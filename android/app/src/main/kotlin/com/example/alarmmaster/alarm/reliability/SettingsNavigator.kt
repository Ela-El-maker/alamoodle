package com.example.alarmmaster.alarm.reliability

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.example.alarmmaster.alarm.notification.ChannelRegistry
import com.example.alarmmaster.alarm.notification.NotificationPermissionHelper

class SettingsNavigator(
    private val context: Context,
    private val notificationPermissionHelper: NotificationPermissionHelper,
) {
    fun open(target: String): Boolean {
        val intent = when (target) {
            "notifications" -> notificationPermissionHelper.buildAppNotificationSettingsIntent()
            "channel_ringing" -> buildChannelIntent(ChannelRegistry.CHANNEL_RINGING)
            "channel_prealerts" -> buildChannelIntent(ChannelRegistry.CHANNEL_PREALERTS)
            "exact_alarm" -> Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            "battery_optimization" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }

        return try {
            context.startActivity(intent)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun buildChannelIntent(channelId: String): Intent {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return notificationPermissionHelper.buildAppNotificationSettingsIntent()
        }
        return Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
