package com.example.alarmmaster.alarm.notification

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.example.alarmmaster.R
import com.example.alarmmaster.alarm.receiver.AlarmActionReceiver

class AlarmNotificationFactory(
    private val context: Context,
    private val fullScreenLauncher: AlarmFullScreenLauncher,
) {
    private val accentColor: Int = android.graphics.Color.parseColor("#FF7A1A")

    fun buildRingingNotification(
        alarmId: Long,
        triggerId: String,
        sessionId: String,
        generation: Int,
        title: String,
        challengeRequired: Boolean = false,
    ): android.app.Notification {
        val contentIntent = fullScreenLauncher.buildPendingIntent(
            alarmId = alarmId,
            triggerId = triggerId,
            sessionId = sessionId,
            generation = generation,
            title = title,
        )

        val builder = NotificationCompat.Builder(context, ChannelRegistry.CHANNEL_RINGING)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title.ifBlank { "Alarm" })
            .setContentText("Alarm ringing \u2022 tap to open controls")
            .setSubText("Running now")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setWhen(System.currentTimeMillis())
            .setUsesChronometer(true)
            .setColor(accentColor)
            .setColorized(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(contentIntent)
        if (!challengeRequired) {
            builder.addAction(
                0,
                "Dismiss",
                actionPendingIntent(AlarmAction.DISMISS, alarmId, triggerId, sessionId, generation),
            )
            builder.addAction(
                0,
                "Snooze 5m",
                actionPendingIntent(AlarmAction.SNOOZE_5, alarmId, triggerId, sessionId, generation),
            )
            builder.addAction(
                0,
                "Snooze 10m",
                actionPendingIntent(AlarmAction.SNOOZE_10, alarmId, triggerId, sessionId, generation),
            )
            builder.addAction(
                0,
                "Snooze 15m",
                actionPendingIntent(AlarmAction.SNOOZE_15, alarmId, triggerId, sessionId, generation),
            )
            builder.addAction(
                0,
                "Do Action",
                actionPendingIntent(AlarmAction.PRIMARY_ACTION, alarmId, triggerId, sessionId, generation),
            )
        }
        return builder.build()
    }

    fun buildFullScreenAlarmInterruptNotification(
        alarmId: Long,
        triggerId: String,
        sessionId: String,
        generation: Int,
        title: String,
        challengeRequired: Boolean = false,
    ): android.app.Notification {
        val fullScreenIntent = fullScreenLauncher.buildPendingIntent(
            alarmId = alarmId,
            triggerId = triggerId,
            sessionId = sessionId,
            generation = generation,
            title = title,
        )
        return NotificationCompat.Builder(context, ChannelRegistry.CHANNEL_RINGING)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title.ifBlank { "Alarm" })
            .setContentText(if (challengeRequired) "Alarm ringing - challenge required" else "Alarm ringing")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setWhen(System.currentTimeMillis())
            .setUsesChronometer(true)
            .setColor(accentColor)
            .setColorized(true)
            .setAutoCancel(true)
            .setContentIntent(fullScreenIntent)
            .setFullScreenIntent(fullScreenIntent, true)
            .build()
    }

    fun buildPreAlertNotification(
        alarmId: Long,
        triggerId: String,
        title: String,
        generation: Int,
    ): android.app.Notification {
        val openIntent = fullScreenLauncher.buildPendingIntent(
            alarmId = alarmId,
            triggerId = triggerId,
            sessionId = "pre-$triggerId",
            generation = generation,
            title = title,
        )
        return NotificationCompat.Builder(context, ChannelRegistry.CHANNEL_PREALERTS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Upcoming alarm")
            .setContentText("$title • reminder")
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openIntent)
            .addAction(
                0,
                "Dismiss",
                actionPendingIntent(
                    action = AlarmAction.PRE_DISMISS,
                    alarmId = alarmId,
                    triggerId = triggerId,
                    sessionId = "pre-$triggerId",
                    generation = generation,
                ),
            )
            .build()
    }

    fun buildServiceStatusNotification(
        alarmId: Long,
        triggerId: String,
        sessionId: String,
        title: String,
    ): android.app.Notification {
        val openIntent = fullScreenLauncher.buildPendingIntent(
            alarmId = alarmId,
            triggerId = triggerId,
            sessionId = sessionId,
            generation = -1,
            title = title,
        )
        return NotificationCompat.Builder(context, ChannelRegistry.CHANNEL_SERVICE_STATUS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Alarm running")
            .setContentText(title)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openIntent)
            .build()
    }

    private fun actionPendingIntent(
        action: AlarmAction,
        alarmId: Long,
        triggerId: String,
        sessionId: String,
        generation: Int,
    ): PendingIntent {
        val intent = Intent(context, AlarmActionReceiver::class.java).apply {
            this.action = action.actionId
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, triggerId)
            putExtra(AlarmIntentExtras.EXTRA_SESSION_ID, sessionId)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, generation)
            action.snoozeMinutes?.let {
                putExtra(AlarmIntentExtras.EXTRA_SNOOZE_MINUTES, it)
            }
        }

        val requestCodeSeed = "${action.actionId}-$alarmId-$triggerId".hashCode()
        return PendingIntent.getBroadcast(
            context,
            requestCodeSeed,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
