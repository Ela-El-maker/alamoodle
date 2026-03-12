package com.example.alarmmaster.alarm.reliability

import android.content.Context
import android.os.PowerManager
import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.data.dao.ScheduleRegistryDao
import com.example.alarmmaster.alarm.domain.ReliabilitySnapshot
import com.example.alarmmaster.alarm.notification.ChannelRegistry
import com.example.alarmmaster.alarm.notification.NotificationPermissionHelper
import com.example.alarmmaster.alarm.scheduler.ExactAlarmPermissionGate
import kotlinx.coroutines.runBlocking

open class ReliabilityChecker(
    private val context: Context,
    private val exactAlarmPermissionGate: ExactAlarmPermissionGate,
    private val notificationPermissionHelper: NotificationPermissionHelper,
    private val channelRegistry: ChannelRegistry,
    private val scheduleRegistryDao: ScheduleRegistryDao,
    private val recoveryStateProvider: RecoveryStateProvider,
) {
    open fun snapshot(engineMode: String): ReliabilitySnapshot {
        val canScheduleExact = exactAlarmPermissionGate.canScheduleExactAlarms()
        val notificationsPermissionGranted = notificationPermissionHelper.hasNotificationPermission()
        val fullScreenReady = notificationPermissionHelper.canUseFullScreenIntent()
        val channelHealth = channelRegistry.channelHealth()
        val scheduleRegistryHealth = runBlocking {
            val active = scheduleRegistryDao.getActive()
            if (active.isEmpty()) "empty_or_idle" else "healthy"
        }
        val powerManager = context.getSystemService(PowerManager::class.java)
        val batteryOptimizationRisk = if (powerManager?.isIgnoringBatteryOptimizations(context.packageName) == true) {
            "low"
        } else {
            "elevated"
        }
        val lastRecovery = runBlocking { recoveryStateProvider.getLastRecoveryState() }
        val directBootReady = true

        return ReliabilitySnapshot(
            exactAlarmPermissionGranted = canScheduleExact,
            notificationsPermissionGranted = notificationsPermissionGranted,
            canScheduleExactAlarms = canScheduleExact,
            engineMode = engineMode,
            schedulerHealth = when {
                !canScheduleExact -> "exact_alarm_permission_required"
                scheduleRegistryHealth.startsWith("missing_") -> "registry_inconsistent"
                else -> "healthy"
            },
            nativeRingPipelineEnabled = AlarmRuntimePolicy.NATIVE_RING_PIPELINE_ENABLED,
            legacyEmergencyRingFallbackEnabled = AlarmRuntimePolicy.LEGACY_EMERGENCY_RING_FALLBACK_ENABLED,
            directBootReady = directBootReady,
            channelHealth = channelHealth,
            fullScreenReady = fullScreenReady,
            batteryOptimizationRisk = batteryOptimizationRisk,
            scheduleRegistryHealth = scheduleRegistryHealth,
            lastRecoveryReason = lastRecovery.reason,
            lastRecoveryAtUtcMillis = lastRecovery.atUtcMillis,
            lastRecoveryStatus = lastRecovery.status,
            legacyFallbackDefaultEnabled = AlarmRuntimePolicy.LEGACY_EMERGENCY_RING_FALLBACK_ENABLED,
        )
    }
}
