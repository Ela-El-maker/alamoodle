package com.example.alarmmaster.alarm.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.core.AlarmRuntime
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.service.AlarmRingingService
import kotlinx.coroutines.runBlocking

open class AlarmTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val runtime = AlarmRuntime.get(context.applicationContext)
        val triggerId = intent?.getStringExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID).orEmpty()
        val alarmId = intent?.getLongExtra(AlarmIntentExtras.EXTRA_ALARM_ID, -1L) ?: -1L
        val generation = intent?.getIntExtra(AlarmIntentExtras.EXTRA_GENERATION, -1) ?: -1

        if (alarmId <= 0 || triggerId.isBlank()) {
            runtime.eventLogger.log("TRIGGER_INVALID", "alarmId=$alarmId triggerId=$triggerId")
            return
        }

        try {
            val validation = runBlocking {
                val dbTrigger = runtime.triggerRepository.getByTriggerId(triggerId)
                val plan = runtime.alarmRepository.getById(alarmId)
                when (AlarmTriggerValidator.validate(generation, dbTrigger, plan)) {
                    TriggerValidationResult.MISSING_TRIGGER -> {
                        runtime.historyRepository.record(
                            alarmId,
                            triggerId,
                            "TRIGGER_MISSING",
                            "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED}",
                        )
                        return@runBlocking false
                    }
                    TriggerValidationResult.STALE_GENERATION -> {
                        runtime.historyRepository.record(
                            alarmId,
                            triggerId,
                            "TRIGGER_STALE",
                            "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} payloadGen=$generation dbGen=${dbTrigger?.generation}",
                        )
                        return@runBlocking false
                    }
                    TriggerValidationResult.DISABLED_ALARM -> {
                        runtime.historyRepository.record(
                            alarmId,
                            triggerId,
                            "TRIGGER_IGNORED_DISABLED",
                            "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED}",
                        )
                        return@runBlocking false
                    }
                    TriggerValidationResult.ALREADY_CONSUMED -> {
                        runtime.historyRepository.record(
                            alarmId,
                            triggerId,
                            "TRIGGER_IGNORED_DUPLICATE",
                            "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} status=${dbTrigger?.status}",
                        )
                        return@runBlocking false
                    }
                    TriggerValidationResult.VALID -> Unit
                }

                val validatedTrigger = dbTrigger ?: return@runBlocking false
                val driftMs = System.currentTimeMillis() - validatedTrigger.scheduledUtcMillis
                val driftDecision = TriggerDriftPolicy.decide(validatedTrigger.kind, driftMs)
                if (driftDecision == DriftDecision.IGNORE_TOO_LATE) {
                    runtime.historyRepository.record(
                        alarmId,
                        triggerId,
                        "TRIGGER_LATE_DEGRADED",
                        "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} kind=${validatedTrigger.kind} driftMs=$driftMs",
                    )
                    return@runBlocking false
                }

                runtime.historyRepository.record(
                    alarmId,
                    triggerId,
                    "FIRED",
                    "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} kind=${validatedTrigger.kind} driftMs=$driftMs",
                )
                runtime.triggerRepository.updateStatus(triggerId, "FIRED")
                true
            }

            if (!validation) return

            val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
                action = AlarmRingingService.ACTION_START_RINGING
                putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, triggerId)
                putExtra(AlarmIntentExtras.EXTRA_GENERATION, generation)
            }
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (t: Throwable) {
            Log.e("AlarmTriggerReceiver", "Failed to start service", t)
            runBlocking {
                runtime.historyRepository.record(
                    alarmId = alarmId,
                    triggerId = triggerId,
                    eventType = "TRIGGER_SERVICE_START_FAILED",
                    meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} error=${t.message ?: "unknown"}",
                )
            }
        }
    }
}
