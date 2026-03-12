package com.example.alarmmaster.alarm.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.core.AlarmRuntime
import com.example.alarmmaster.alarm.notification.AlarmAction
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.notification.AlarmNotificationIds
import com.example.alarmmaster.alarm.service.AlarmRingingService
import kotlinx.coroutines.runBlocking

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = AlarmAction.fromActionId(intent?.action) ?: return
        val alarmId = intent?.getLongExtra(AlarmIntentExtras.EXTRA_ALARM_ID, -1L) ?: -1L
        val triggerId = intent?.getStringExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID).orEmpty()
        val sessionId = intent?.getStringExtra(AlarmIntentExtras.EXTRA_SESSION_ID).orEmpty()
        val generation = intent?.getIntExtra(AlarmIntentExtras.EXTRA_GENERATION, -1) ?: -1

        if (action == AlarmAction.PRE_DISMISS) {
            if (triggerId.isNotBlank()) {
                NotificationManagerCompat.from(context).cancel(
                    AlarmNotificationIds.preAlertForTrigger(triggerId),
                )
            }
            val runtime = AlarmRuntime.get(context.applicationContext)
            runBlocking {
                runtime.historyRepository.record(
                    alarmId = alarmId.coerceAtLeast(0L),
                    triggerId = triggerId,
                    eventType = "PRE_NOTIFICATION_DISMISSED",
                    meta = "source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED}",
                )
            }
            return
        }

        val serviceAction = when (action) {
            AlarmAction.DISMISS -> AlarmRingingService.ACTION_DISMISS
            AlarmAction.PRE_DISMISS -> return
            AlarmAction.SNOOZE_5,
            AlarmAction.SNOOZE_10,
            AlarmAction.SNOOZE_15,
            -> AlarmRingingService.ACTION_SNOOZE
            AlarmAction.PRIMARY_ACTION -> AlarmRingingService.ACTION_PRIMARY_ACTION
        }

        val serviceIntent = Intent(context, AlarmRingingService::class.java).apply {
            this.action = serviceAction
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, triggerId)
            putExtra(AlarmIntentExtras.EXTRA_SESSION_ID, sessionId)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, generation)
            action.snoozeMinutes?.let {
                putExtra(AlarmIntentExtras.EXTRA_SNOOZE_MINUTES, it)
            }
        }

        try {
            context.startService(serviceIntent)
        } catch (_: IllegalStateException) {
            ContextCompat.startForegroundService(context, serviceIntent)
        }
    }
}
