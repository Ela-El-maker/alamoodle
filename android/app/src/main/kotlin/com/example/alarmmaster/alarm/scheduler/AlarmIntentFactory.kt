package com.example.alarmmaster.alarm.scheduler

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.receiver.AlarmTriggerReceiver
import com.example.alarmmaster.alarm.service.AlarmRingingService

class AlarmIntentFactory(private val context: Context) {
    fun build(trigger: TriggerInstance): PendingIntent {
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

    fun cancelLegacyBroadcast(trigger: TriggerInstance) {
        val legacyIntent = Intent(context, AlarmTriggerReceiver::class.java).apply {
            action = "com.example.alarmmaster.ALARM_TRIGGER"
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, trigger.triggerId)
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, trigger.alarmId)
            putExtra(AlarmIntentExtras.EXTRA_REQUEST_CODE, trigger.requestCode)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_KIND, trigger.kind.name)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, trigger.generation)
            putExtra(AlarmIntentExtras.EXTRA_SCHEDULED_UTC_MILLIS, trigger.scheduledUtcMillis)
        }
        val legacyPendingIntent = PendingIntent.getBroadcast(
            context,
            trigger.requestCode,
            legacyIntent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        legacyPendingIntent?.cancel()
    }
}
