package com.example.alarmmaster.alarm.notification

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.example.alarmmaster.alarm.ui.AlarmActivity

class AlarmFullScreenLauncher(private val context: Context) {
    fun buildPendingIntent(
        alarmId: Long,
        triggerId: String,
        sessionId: String,
        generation: Int,
        title: String,
    ): PendingIntent {
        val intent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, triggerId)
            putExtra(AlarmIntentExtras.EXTRA_SESSION_ID, sessionId)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, generation)
            putExtra(AlarmIntentExtras.EXTRA_ALARM_TITLE, title)
        }
        val requestCode = ((alarmId % Int.MAX_VALUE).toInt().coerceAtLeast(1))
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
