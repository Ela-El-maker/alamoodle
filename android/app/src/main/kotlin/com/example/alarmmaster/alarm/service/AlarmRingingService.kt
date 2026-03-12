package com.example.alarmmaster.alarm.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.alarmmaster.R
import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.core.AlarmRuntime
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.notification.AlarmNotificationIds
import com.example.alarmmaster.alarm.notification.ChannelRegistry
import com.example.alarmmaster.alarm.receiver.AlarmTriggerValidator
import com.example.alarmmaster.alarm.receiver.DriftDecision
import com.example.alarmmaster.alarm.receiver.TriggerDriftPolicy
import com.example.alarmmaster.alarm.receiver.TriggerValidationResult
import com.example.alarmmaster.alarm.scheduler.NagPlanner
import com.example.alarmmaster.alarm.ui.ChallengeCoordinator
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId

class AlarmRingingService : Service() {
    private lateinit var runtime: AlarmRuntime
    private lateinit var wakeController: AlarmWakeController
    private lateinit var audioController: AlarmAudioController
    private lateinit var escalationController: AlarmEscalationController
    private lateinit var primaryActionLauncher: PrimaryActionLauncher
    private val challengeCoordinator = ChallengeCoordinator()
    private val nagPlanner = NagPlanner()

    private var currentAlarmId: Long = -1L
    private var currentTriggerId: String = ""
    private var currentSessionId: String = ""
    private var currentGeneration: Int = -1
    private var terminalActionApplied: Boolean = false
    private var foregroundPromoted: Boolean = false
    private var currentPrimaryAction: String? = null
    private var currentNagPolicy: com.example.alarmmaster.alarm.domain.NagPolicy =
        com.example.alarmmaster.alarm.domain.NagPolicy.DISABLED
    private var sessionStartedAtUtcMillis: Long = 0L

    override fun onCreate() {
        super.onCreate()
        // Promote to foreground immediately to satisfy strict OEM timing checks
        // when the service is cold-started from a background alarm trigger.
        ChannelRegistry(applicationContext).ensureChannels()
        ensureForegroundBootstrap()
        runtime = AlarmRuntime.get(applicationContext)
        runtime.ensureChannels()
        wakeController = AlarmWakeController(applicationContext)
        audioController = AlarmAudioController(applicationContext)
        escalationController = AlarmEscalationController()
        primaryActionLauncher = PrimaryActionLauncher(applicationContext, runtime.eventLogger)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START_RINGING
        try {
            when (action) {
                ACTION_DISMISS -> handleDismiss(intent, source = "notification_or_activity")
                ACTION_SNOOZE -> {
                    val minutes = intent?.getIntExtra(AlarmIntentExtras.EXTRA_SNOOZE_MINUTES, 5) ?: 5
                    handleSnooze(intent, minutes)
                }
                ACTION_PRIMARY_ACTION -> handlePrimaryAction(intent)
                else -> {
                    ensureForegroundBootstrap()
                    handleStart(intent)
                }
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Service action failed", t)
            runtime.eventLogger.log(
                "RING_SERVICE_ERROR",
                "source=native pipeline=native_ring error=${t.message ?: "unknown"}",
            )
            stopSelfSafely()
        }
        return START_NOT_STICKY
    }

    private fun handleStart(intent: Intent?) {
        val alarmId = intent?.getLongExtra(AlarmIntentExtras.EXTRA_ALARM_ID, -1L) ?: -1L
        val triggerId = intent?.getStringExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID).orEmpty()
        val generation = intent?.getIntExtra(AlarmIntentExtras.EXTRA_GENERATION, -1) ?: -1
        if (alarmId <= 0 || triggerId.isBlank()) {
            runtime.eventLogger.log("RING_SERVICE_INVALID_START", "alarmId=$alarmId triggerId=$triggerId")
            stopSelfSafely()
            return
        }

        if (currentSessionId.isNotBlank() && currentTriggerId.isNotBlank()) {
            runtime.eventLogger.log(
                "RING_OVERLAP_REJECTED",
                "source=native pipeline=native_ring alarmId=$alarmId triggerId=$triggerId activeSessionId=$currentSessionId activeTriggerId=$currentTriggerId",
            )
            return
        }

        var triggerKind: TriggerKind = TriggerKind.MAIN
        val plan = runBlocking {
            val dbTrigger = runtime.triggerRepository.getByTriggerId(triggerId)
            val currentPlan = runtime.alarmRepository.getById(alarmId)
            when (AlarmTriggerValidator.validate(generation, dbTrigger, currentPlan)) {
                TriggerValidationResult.MISSING_TRIGGER -> {
                    runtime.historyRepository.record(
                        alarmId,
                        triggerId,
                        "TRIGGER_MISSING",
                        "source=native pipeline=service_direct fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED}",
                    )
                    null
                }

                TriggerValidationResult.STALE_GENERATION -> {
                    runtime.historyRepository.record(
                        alarmId,
                        triggerId,
                        "TRIGGER_STALE",
                        "source=native pipeline=service_direct fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} payloadGen=$generation dbGen=${dbTrigger?.generation}",
                    )
                    null
                }

                TriggerValidationResult.DISABLED_ALARM -> {
                    runtime.historyRepository.record(
                        alarmId,
                        triggerId,
                        "TRIGGER_IGNORED_DISABLED",
                        "source=native pipeline=service_direct fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED}",
                    )
                    null
                }

                TriggerValidationResult.ALREADY_CONSUMED -> {
                    runtime.historyRepository.record(
                        alarmId,
                        triggerId,
                        "TRIGGER_IGNORED_DUPLICATE",
                        "source=native pipeline=service_direct fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} status=${dbTrigger?.status}",
                    )
                    null
                }

                TriggerValidationResult.VALID -> {
                    val validatedTrigger = dbTrigger ?: return@runBlocking null
                    triggerKind = validatedTrigger.kind
                    val driftMs = System.currentTimeMillis() - validatedTrigger.scheduledUtcMillis
                    if (TriggerDriftPolicy.decide(validatedTrigger.kind, driftMs) == DriftDecision.IGNORE_TOO_LATE) {
                        runtime.historyRepository.record(
                            alarmId,
                            triggerId,
                            "TRIGGER_LATE_DEGRADED",
                            "source=native pipeline=service_direct fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} kind=${validatedTrigger.kind} driftMs=$driftMs",
                        )
                        null
                    } else {
                        runtime.historyRepository.record(
                            alarmId,
                            triggerId,
                            "FIRED",
                            "source=native pipeline=service_direct fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} kind=${validatedTrigger.kind} driftMs=$driftMs",
                        )
                        runtime.triggerRepository.updateStatus(triggerId, "FIRED")
                        currentPlan
                    }
                }
            }
        }
        if (plan == null) {
            stopSelfSafely()
            return
        }

        val title = plan.title.ifBlank { "Alarm" }
        if (triggerKind == TriggerKind.PRE) {
            handlePreReminder(
                alarmId = alarmId,
                triggerId = triggerId,
                generation = generation,
                title = title,
            )
            return
        }

        val soundId = plan.soundToProfileId()
        val vibrationProfileId = plan.vibrationProfileId ?: if (plan.vibration) "default" else "off"
        val challengePolicy = challengeCoordinator.normalize(plan.challengePolicy, plan.challenge)
        val challengeRequired = challengePolicy.mode != "none"
        currentPrimaryAction = plan.primaryAction
        currentNagPolicy = parseNagPolicy(plan.nagPolicy)

        val sessionId = "$alarmId-$triggerId-${System.currentTimeMillis()}"
        currentAlarmId = alarmId
        currentTriggerId = triggerId
        currentSessionId = sessionId
        currentGeneration = generation
        terminalActionApplied = false
        sessionStartedAtUtcMillis = System.currentTimeMillis()

        runBlocking {
            runtime.ringSessionRepository.startSession(
                sessionId = sessionId,
                alarmId = alarmId,
                triggerId = triggerId,
            )
                runtime.historyRepository.record(
                    alarmId = alarmId,
                    triggerId = triggerId,
                    eventType = "SERVICE_STARTED",
                    meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} sessionId=$sessionId",
                )
            }

        wakeController.acquire()
        audioController.startRinging(
            soundId = soundId,
            vibrationProfileId = vibrationProfileId,
            initialVolume = parseEscalationStart(plan.escalationPolicy),
        )
        escalationController.start(
            policy = parseEscalationPolicy(plan.escalationPolicy),
            onVolumeStep = { next -> audioController.setVolume(next) },
        )

        val notification = runtime.notificationFactory.buildRingingNotification(
            alarmId = alarmId,
            triggerId = triggerId,
            sessionId = sessionId,
            generation = generation,
            title = title,
            challengeRequired = challengeRequired,
        )

        startForeground(NOTIFICATION_ID, notification)
        foregroundPromoted = true
        NotificationManagerCompat.from(this).notify(
            FULL_SCREEN_NOTIFICATION_ID,
            runtime.notificationFactory.buildFullScreenAlarmInterruptNotification(
                alarmId = alarmId,
                triggerId = triggerId,
                sessionId = sessionId,
                generation = generation,
                title = title,
                challengeRequired = challengeRequired,
            ),
        )

        runBlocking {
                runtime.historyRepository.record(
                    alarmId = alarmId,
                    triggerId = triggerId,
                    eventType = "UI_SHOWN",
                    meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} full_screen=true",
                )
            }

        runtime.eventLogger.log(
            "RING_SERVICE_RUNNING",
            "alarmId=$alarmId triggerId=$triggerId sessionId=$sessionId source=native pipeline=native_ring",
        )
    }

    private fun handlePreReminder(
        alarmId: Long,
        triggerId: String,
        generation: Int,
        title: String,
    ) {
        val notificationId = AlarmNotificationIds.preAlertForTrigger(triggerId)
        NotificationManagerCompat.from(this).notify(
            notificationId,
            runtime.notificationFactory.buildPreAlertNotification(
                alarmId = alarmId,
                triggerId = triggerId,
                title = title,
                generation = generation,
            ),
        )
        runBlocking {
            runtime.historyRepository.record(
                alarmId = alarmId,
                triggerId = triggerId,
                eventType = "PRE_NOTIFICATION_POSTED",
                meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED}",
            )
        }
        runtime.eventLogger.log(
            "PRE_NOTIFICATION_POSTED",
            "alarmId=$alarmId triggerId=$triggerId notificationId=$notificationId source=native pipeline=native_ring",
        )
        stopSelfSafely()
    }

    private fun handleDismiss(intent: Intent?, source: String) {
        if (!canApplyAction(intent, "dismiss")) return
        hydrateSessionContext(intent)
        if (currentAlarmId > 0 && currentTriggerId.isNotBlank()) {
            runBlocking {
                runtime.historyRepository.record(
                    alarmId = currentAlarmId,
                    triggerId = currentTriggerId,
                    eventType = "DISMISSED",
                    meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} via=$source",
                )
                if (currentSessionId.isNotBlank()) {
                    runtime.ringSessionRepository.endSession(currentSessionId, "DISMISSED")
                }
            }
        }
        terminalActionApplied = true
        stopSelfSafely()
    }

    private fun handleSnooze(intent: Intent?, minutes: Int) {
        if (!canApplyAction(intent, "snooze")) return
        hydrateSessionContext(intent)
        if (currentAlarmId <= 0 || currentTriggerId.isBlank()) {
            stopSelfSafely()
            return
        }

        val snoozeMinutes = minutes.coerceAtLeast(1)
        val generation = ((System.currentTimeMillis() / 1000L) % 100_000L).toInt()
        val snoozeAt = System.currentTimeMillis() + snoozeMinutes * 60_000L
        val zone = ZoneId.systemDefault()
        val localIso = Instant.ofEpochMilli(snoozeAt).atZone(zone).toLocalDateTime().toString()
        val snoozeIndex = (System.currentTimeMillis() % 1000L).toInt()

        val snoozeTrigger = TriggerInstance(
            triggerId = runtime.triggerIdFactory.buildTriggerId(
                alarmId = currentAlarmId,
                kind = TriggerKind.SNOOZE,
                index = snoozeIndex,
                generation = generation,
                scheduledUtcMillis = snoozeAt,
            ),
            alarmId = currentAlarmId,
            kind = TriggerKind.SNOOZE,
            scheduledLocalIso = localIso,
            scheduledUtcMillis = snoozeAt,
            requestCode = runtime.triggerIdFactory.buildRequestCode(
                alarmId = currentAlarmId,
                kind = TriggerKind.SNOOZE,
                index = snoozeIndex,
                generation = generation,
            ),
            status = TriggerStatus.SCHEDULED,
            generation = generation,
        )

        runBlocking {
            runtime.triggerRepository.upsertTrigger(snoozeTrigger)
            runtime.alarmScheduler.scheduleTrigger(snoozeTrigger)
            runtime.historyRepository.record(
                alarmId = currentAlarmId,
                triggerId = currentTriggerId,
                eventType = "SNOOZED",
                meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} minutes=$snoozeMinutes",
            )
            if (currentSessionId.isNotBlank()) {
                runtime.ringSessionRepository.endSession(currentSessionId, "SNOOZED")
            }
        }

        terminalActionApplied = true
        stopSelfSafely()
    }

    private fun handlePrimaryAction(intent: Intent?) {
        if (!canApplyAction(intent, "primary")) return
        hydrateSessionContext(intent)
        val launched = primaryActionLauncher.launch(currentPrimaryAction)
        if (currentAlarmId > 0 && currentTriggerId.isNotBlank()) {
            runBlocking {
                runtime.historyRepository.record(
                    alarmId = currentAlarmId,
                    triggerId = currentTriggerId,
                    eventType = if (launched) "PRIMARY_ACTION_LAUNCHED" else "PRIMARY_ACTION_FAILED",
                    meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED}",
                )
                if (currentSessionId.isNotBlank()) {
                    runtime.ringSessionRepository.endSession(currentSessionId, "ACTIONED")
                }
            }
        }
        terminalActionApplied = true
        stopSelfSafely()
    }

    private fun hydrateSessionContext(intent: Intent?) {
        if (intent == null) return
        if (currentAlarmId <= 0) {
            currentAlarmId = intent.getLongExtra(AlarmIntentExtras.EXTRA_ALARM_ID, -1L)
        }
        if (currentTriggerId.isBlank()) {
            currentTriggerId = intent.getStringExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID).orEmpty()
        }
        if (currentSessionId.isBlank()) {
            currentSessionId = intent.getStringExtra(AlarmIntentExtras.EXTRA_SESSION_ID).orEmpty()
        }
        if (currentGeneration < 0) {
            currentGeneration = intent.getIntExtra(AlarmIntentExtras.EXTRA_GENERATION, -1)
        }
    }

    private fun canApplyAction(intent: Intent?, action: String): Boolean {
        if (terminalActionApplied) {
            runtime.eventLogger.log(
                "RING_ACTION_DUPLICATE_IGNORED",
                "source=native pipeline=native_ring action=$action sessionId=$currentSessionId triggerId=$currentTriggerId",
            )
            return false
        }

        val sessionId = intent?.getStringExtra(AlarmIntentExtras.EXTRA_SESSION_ID).orEmpty()
        if (currentSessionId.isNotBlank() && sessionId.isNotBlank() && sessionId != currentSessionId) {
            runtime.eventLogger.log(
                "RING_ACTION_STALE_IGNORED",
                "source=native pipeline=native_ring action=$action payloadSessionId=$sessionId currentSessionId=$currentSessionId",
            )
            return false
        }

        val payloadGeneration = intent?.getIntExtra(AlarmIntentExtras.EXTRA_GENERATION, -1) ?: -1
        if (currentGeneration >= 0 && payloadGeneration >= 0 && payloadGeneration != currentGeneration) {
            runtime.eventLogger.log(
                "RING_ACTION_STALE_GENERATION_IGNORED",
                "source=native pipeline=native_ring action=$action payloadGeneration=$payloadGeneration currentGeneration=$currentGeneration",
            )
            return false
        }
        return true
    }

    private fun stopSelfSafely() {
        escalationController.stop()
        audioController.stop()
        wakeController.release()
        NotificationManagerCompat.from(this).cancel(FULL_SCREEN_NOTIFICATION_ID)
        if (foregroundPromoted) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            foregroundPromoted = false
        }
        stopSelf()
    }

    override fun onDestroy() {
        maybeScheduleNagRetry()
        escalationController.stop()
        audioController.stop()
        wakeController.release()
        super.onDestroy()
    }

    private fun parseEscalationStart(rawPolicy: String?): Float {
        if (rawPolicy.isNullOrBlank()) return 1.0f
        return runCatching {
            JSONObject(rawPolicy).optDouble("startVolume", 0.45).toFloat().coerceIn(0f, 1f)
        }.getOrDefault(1.0f)
    }

    private fun parseEscalationPolicy(rawPolicy: String?): com.example.alarmmaster.alarm.domain.EscalationPolicy {
        if (rawPolicy.isNullOrBlank()) return com.example.alarmmaster.alarm.domain.EscalationPolicy.DISABLED
        return runCatching {
            val json = JSONObject(rawPolicy)
            com.example.alarmmaster.alarm.domain.EscalationPolicy(
                enabled = json.optBoolean("enabled", false),
                startVolume = json.optDouble("startVolume", 0.45).toFloat(),
                endVolume = json.optDouble("endVolume", 1.0).toFloat(),
                stepSeconds = json.optInt("stepSeconds", 20),
                maxSteps = json.optInt("maxSteps", 3),
            )
        }.getOrDefault(com.example.alarmmaster.alarm.domain.EscalationPolicy.DISABLED)
    }

    private fun parseNagPolicy(rawPolicy: String?): com.example.alarmmaster.alarm.domain.NagPolicy {
        if (rawPolicy.isNullOrBlank()) return com.example.alarmmaster.alarm.domain.NagPolicy.DISABLED
        return runCatching {
            val json = JSONObject(rawPolicy)
            com.example.alarmmaster.alarm.domain.NagPolicy(
                enabled = json.optBoolean("enabled", false),
                retryWindowMinutes = json.optInt("retryWindowMinutes", 30),
                maxRetries = json.optInt("maxRetries", 2),
                retryIntervalMinutes = json.optInt("retryIntervalMinutes", 10),
            )
        }.getOrDefault(com.example.alarmmaster.alarm.domain.NagPolicy.DISABLED)
    }

    private fun maybeScheduleNagRetry() {
        if (terminalActionApplied) return
        if (currentAlarmId <= 0 || currentTriggerId.isBlank()) return
        val policy = currentNagPolicy
        if (!policy.enabled) return

        val elapsed = if (sessionStartedAtUtcMillis > 0L) {
            (System.currentTimeMillis() - sessionStartedAtUtcMillis).coerceAtLeast(0L)
        } else {
            0L
        }
        val shouldSchedule = nagPlanner.shouldScheduleNag(
            policy = policy,
            elapsedMillis = elapsed,
            retryCount = 0,
        )
        if (!shouldSchedule) return

        val retryDelay = nagPlanner.nextRetryDelayMillis(policy)
        val retryAt = System.currentTimeMillis() + retryDelay
        val zone = ZoneId.systemDefault()
        val localIso = Instant.ofEpochMilli(retryAt).atZone(zone).toLocalDateTime().toString()
        val generation = ((System.currentTimeMillis() / 1000L) % 100_000L).toInt()
        val index = (retryAt % 1000L).toInt()

        val nagTrigger = TriggerInstance(
            triggerId = runtime.triggerIdFactory.buildTriggerId(
                alarmId = currentAlarmId,
                kind = TriggerKind.SNOOZE,
                index = index,
                generation = generation,
                scheduledUtcMillis = retryAt,
            ),
            alarmId = currentAlarmId,
            kind = TriggerKind.SNOOZE,
            scheduledLocalIso = localIso,
            scheduledUtcMillis = retryAt,
            requestCode = runtime.triggerIdFactory.buildRequestCode(
                alarmId = currentAlarmId,
                kind = TriggerKind.SNOOZE,
                index = index,
                generation = generation,
            ),
            status = TriggerStatus.SCHEDULED,
            generation = generation,
        )

        runBlocking {
            runtime.triggerRepository.upsertTrigger(nagTrigger)
            runtime.alarmScheduler.scheduleTrigger(nagTrigger)
            runtime.historyRepository.record(
                alarmId = currentAlarmId,
                triggerId = currentTriggerId,
                eventType = "NAG_SCHEDULED",
                meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} delayMs=$retryDelay",
            )
        }
    }

    private fun com.example.alarmmaster.alarm.domain.AlarmPlan.soundToProfileId(): String {
        val raw = sound.trim()
        if (raw.isBlank()) return "default_alarm"

        return when (raw) {
            "default_alarm",
            "gentle_chime",
            "digital_beep",
            "bell_tower",
            -> raw
            else -> when {
                raw.contains("bell", ignoreCase = true) -> "bell_tower"
                raw.contains("gentle", ignoreCase = true) -> "gentle_chime"
                raw.contains("digital", ignoreCase = true) -> "digital_beep"
                else -> "default_alarm"
            }
        }
    }

    companion object {
        private const val TAG = "AlarmRingingService"
        const val ACTION_START_RINGING = "com.example.alarmmaster.service.START_RINGING"
        const val ACTION_DISMISS = "com.example.alarmmaster.service.DISMISS"
        const val ACTION_SNOOZE = "com.example.alarmmaster.service.SNOOZE"
        const val ACTION_PRIMARY_ACTION = "com.example.alarmmaster.service.PRIMARY_ACTION"

        const val NOTIFICATION_ID = 41001
        const val FULL_SCREEN_NOTIFICATION_ID = 41002
    }

    private fun ensureForegroundBootstrap() {
        if (foregroundPromoted) return

        val fallbackTitle = "Alarm"
        val bootstrap = NotificationCompat.Builder(this, ChannelRegistry.CHANNEL_SERVICE_STATUS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(fallbackTitle)
            .setContentText("Starting alarm...")
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()

        startForeground(NOTIFICATION_ID, bootstrap)
        foregroundPromoted = true
    }
}
