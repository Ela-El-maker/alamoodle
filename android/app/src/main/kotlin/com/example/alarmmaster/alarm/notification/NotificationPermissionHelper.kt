package com.example.alarmmaster.alarm.notification

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat

open class NotificationPermissionHelper(private val context: Context) {
    open fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    open fun buildAppNotificationSettingsIntent(): Intent {
        return Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    open fun areNotificationsEnabled(): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java)
        return manager?.areNotificationsEnabled() ?: false
    }

    open fun canUseFullScreenIntent(): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            runCatching {
                manager.canUseFullScreenIntent()
            }.getOrDefault(true)
        } else {
            true
        }
    }
}
