package com.example.alarmmaster.alarm.receiver

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.example.alarmmaster.alarm.data.DeviceProtectedRecoveryStore
import com.example.alarmmaster.alarm.data.LastRecoveryState
import com.example.alarmmaster.alarm.data.RecoveryIndexEntry
import com.example.alarmmaster.alarm.diagnostics.EventLogger
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.reliability.RecoveryReason
import com.example.alarmmaster.alarm.service.AlarmRingingService

internal object DirectBootRecoveryFallback {
    suspend fun recover(context: Context, reason: RecoveryReason, nowUtcMillis: Long = System.currentTimeMillis()) {
        val deviceContext = if (context.isDeviceProtectedStorage) {
            context
        } else {
            context.createDeviceProtectedStorageContext()
        }

        val eventLogger = EventLogger(deviceContext)
        val recoveryStore = DeviceProtectedRecoveryStore(deviceContext)
        val alarmManager = deviceContext.getSystemService(AlarmManager::class.java)

        val rawEntries = recoveryStore.getRecoveryIndex()
        val entries = rawEntries.filter { entry ->
            if (entry.scheduledUtcMillis > nowUtcMillis) {
                true
            } else {
                val kind = runCatching { TriggerKind.valueOf(entry.kind) }.getOrDefault(TriggerKind.MAIN)
                val driftMs = nowUtcMillis - entry.scheduledUtcMillis
                when (kind) {
                    TriggerKind.MAIN,
                    TriggerKind.SNOOZE,
                    -> TriggerDriftPolicy.decide(kind, driftMs) == DriftDecision.RING_NOW
                    TriggerKind.PRE -> false
                }
            }
        }

        var restored = 0
        var failures = 0
        val staleRemoved = (rawEntries.size - entries.size).coerceAtLeast(0)

        entries.forEach { entry ->
            val trigger = entry.toTriggerInstance()
            runCatching {
                val pendingIntent = buildPendingIntent(deviceContext, trigger)
                when (trigger.kind) {
                    TriggerKind.MAIN -> {
                        val launchIntent = deviceContext.packageManager.getLaunchIntentForPackage(deviceContext.packageName)
                        val showIntent = PendingIntent.getActivity(
                            deviceContext,
                            trigger.requestCode,
                            launchIntent ?: Intent(),
                            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                        )
                        val info = AlarmManager.AlarmClockInfo(trigger.scheduledUtcMillis, showIntent)
                        alarmManager.setAlarmClock(info, pendingIntent)
                    }
                    TriggerKind.PRE,
                    TriggerKind.SNOOZE,
                    -> {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            trigger.scheduledUtcMillis,
                            pendingIntent,
                        )
                    }
                }
            }.onSuccess {
                restored += 1
            }.onFailure {
                failures += 1
            }
        }

        val status = if (failures == 0) "ok" else "degraded"
        recoveryStore.setLastRecoveryState(
            LastRecoveryState(
                reason = reason.name,
                status = status,
                atUtcMillis = nowUtcMillis,
            ),
        )
        eventLogger.log(
            "RECOVERY_FALLBACK_COMPLETED",
            "reason=${reason.name} status=$status restored=$restored staleRemoved=$staleRemoved failures=$failures",
        )
    }

    private fun buildPendingIntent(context: Context, trigger: TriggerInstance): PendingIntent {
        val intent = Intent(context, AlarmRingingService::class.java).apply {
            action = AlarmRingingService.ACTION_START_RINGING
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, trigger.triggerId)
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, trigger.alarmId)
            putExtra(AlarmIntentExtras.EXTRA_REQUEST_CODE, trigger.requestCode)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_KIND, trigger.kind.name)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, trigger.generation)
            putExtra(AlarmIntentExtras.EXTRA_SCHEDULED_UTC_MILLIS, trigger.scheduledUtcMillis)
        }
        return PendingIntent.getForegroundService(
            context,
            trigger.requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun RecoveryIndexEntry.toTriggerInstance(): TriggerInstance {
        val resolvedKind = runCatching { TriggerKind.valueOf(kind) }.getOrDefault(TriggerKind.MAIN)
        val resolvedRequestCode = if (requestCode > 0) requestCode else triggerId.hashCode()
        return TriggerInstance(
            triggerId = triggerId,
            alarmId = alarmId,
            kind = resolvedKind,
            scheduledLocalIso = "",
            scheduledUtcMillis = scheduledUtcMillis,
            requestCode = resolvedRequestCode,
            status = com.example.alarmmaster.alarm.domain.TriggerStatus.SCHEDULED,
            generation = generation,
        )
    }
}
