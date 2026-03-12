package com.example.alarmmaster.alarm.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.os.Build

class ChannelRegistry(private val context: Context) {
    companion object {
        const val CHANNEL_RINGING = "alarm_ringing"
        const val CHANNEL_PREALERTS = "alarm_prealerts"
        const val CHANNEL_SERVICE_STATUS = "alarm_service_status"
        const val CHANNEL_DIAGNOSTICS = "alarm_diagnostics"
    }

    fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val notificationManager = context.getSystemService(NotificationManager::class.java)
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val ringing = NotificationChannel(
            CHANNEL_RINGING,
            "Alarm Ringing",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Urgent alarm ringing channel"
            enableVibration(true)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            setSound(null, attrs)
        }

        val prealerts = NotificationChannel(
            CHANNEL_PREALERTS,
            "Alarm Pre-alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Pre-alert reminders for upcoming alarms"
            enableVibration(true)
        }

        val serviceStatus = NotificationChannel(
            CHANNEL_SERVICE_STATUS,
            "Alarm Service Status",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Foreground service status channel"
            setShowBadge(false)
        }

        val diagnostics = NotificationChannel(
            CHANNEL_DIAGNOSTICS,
            "Alarm Diagnostics",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Alarm pipeline diagnostics and recovery notices"
            setShowBadge(false)
        }

        notificationManager.createNotificationChannels(listOf(ringing, prealerts, serviceStatus, diagnostics))
    }

    fun channelHealth(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return "healthy_pre_o"
        val manager = context.getSystemService(NotificationManager::class.java)
        val required = listOf(CHANNEL_RINGING, CHANNEL_PREALERTS, CHANNEL_SERVICE_STATUS, CHANNEL_DIAGNOSTICS)
        val missing = required.count { channelId -> manager?.getNotificationChannel(channelId) == null }
        return if (missing == 0) "healthy" else "missing_$missing"
    }
}
