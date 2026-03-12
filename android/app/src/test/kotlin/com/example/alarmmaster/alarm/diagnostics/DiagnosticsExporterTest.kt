package com.example.alarmmaster.alarm.diagnostics

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.example.alarmmaster.alarm.data.LastRecoveryState
import com.example.alarmmaster.alarm.domain.AlarmHistoryRecord
import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.ReliabilitySnapshot
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import com.example.alarmmaster.alarm.notification.ChannelRegistry
import com.example.alarmmaster.alarm.notification.NotificationPermissionHelper
import com.example.alarmmaster.alarm.reliability.RecoveryStateProvider
import com.example.alarmmaster.alarm.reliability.ReliabilityChecker
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.scheduler.ExactAlarmPermissionGate
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DiagnosticsExporterTest {
    @Test
    fun exportsPayloadWithReliabilityAndHistory() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val exporter = DiagnosticsExporter(
            context = context,
            alarmRepository = _AlarmRepo(),
            triggerRepository = _TriggerRepo(),
            historyRepository = _HistoryRepo(),
            reliabilityChecker = _FakeReliabilityChecker(context),
            exactAlarmPermissionGate = object : ExactAlarmPermissionGate(context) {
                override fun canScheduleExactAlarms(): Boolean = true
            },
        )

        val payload = exporter.export(
            LastRecoveryState("BOOT_COMPLETED", "ok", 1L),
            historyLimit = 5,
        )

        assertTrue(payload.contains("\"reliability\""))
        assertTrue(payload.contains("\"recentHistory\""))
        assertTrue(payload.contains("\"traceId\""))
        assertTrue(payload.contains("\"appVersion\""))
        assertTrue(payload.contains("BOOT_COMPLETED"))
    }

    private class _AlarmRepo : AlarmRepository {
        override suspend fun upsert(plan: AlarmPlan) = Unit
        override suspend fun delete(alarmId: Long) = Unit
        override suspend fun getById(alarmId: Long): AlarmPlan? = null
        override suspend fun getAll(): List<AlarmPlan> =
            listOf(
                AlarmPlan(
                    alarmId = 1,
                    title = "A",
                    hour24 = 6,
                    minute = 30,
                    repeatDays = emptyList(),
                    enabled = true,
                    sound = "Default Alarm",
                    challenge = "None",
                    snoozeCount = 0,
                    snoozeDuration = 5,
                    vibration = true,
                    anchorUtcMillis = null,
                    timezoneId = "UTC",
                    timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
                    preReminderMinutes = emptyList(),
                    createdAtUtcMillis = 1,
                    updatedAtUtcMillis = 1,
                ),
            )
    }

    private class _TriggerRepo : TriggerRepository {
        override suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
        override suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance> =
            listOf(
                TriggerInstance(
                    triggerId = "t",
                    alarmId = 1,
                    kind = TriggerKind.MAIN,
                    scheduledLocalIso = "2026-01-01T06:30",
                    scheduledUtcMillis = 1,
                    requestCode = 1,
                    status = TriggerStatus.SCHEDULED,
                    generation = 1,
                ),
            )

        override suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance> = emptyList()
        override suspend fun getByTriggerId(triggerId: String): TriggerInstance? = null
        override suspend fun upsertTrigger(trigger: TriggerInstance) = Unit
        override suspend fun updateStatus(triggerId: String, status: String) = Unit
        override suspend fun clearForAlarm(alarmId: Long) = Unit
    }

    private class _HistoryRepo : HistoryRepository {
        override suspend fun record(
            alarmId: Long,
            triggerId: String,
            eventType: String,
            meta: String,
        ) = Unit

        override suspend fun getByAlarmId(alarmId: Long): List<AlarmHistoryRecord> =
            emptyList()

        override suspend fun getRecent(
            limit: Int,
            alarmId: Long?,
        ): List<AlarmHistoryRecord> =
            listOf(
                AlarmHistoryRecord(
                    historyId = 1,
                    alarmId = 1,
                    triggerId = "t",
                    eventType = "RESTORED_AFTER_BOOT",
                    occurredAtUtcMillis = 1,
                    meta = "ok",
                ),
            )
    }

    private class _FakeReliabilityChecker(context: Context) : ReliabilityChecker(
        context = context,
        exactAlarmPermissionGate = object : ExactAlarmPermissionGate(context) {
            override fun canScheduleExactAlarms(): Boolean = true
        },
        notificationPermissionHelper = object : NotificationPermissionHelper(context) {
            override fun hasNotificationPermission(): Boolean = true
            override fun areNotificationsEnabled(): Boolean = true
            override fun canUseFullScreenIntent(): Boolean = true
        },
        channelRegistry = ChannelRegistry(context),
        scheduleRegistryDao = object : com.example.alarmmaster.alarm.data.dao.ScheduleRegistryDao {
            override suspend fun upsert(entity: com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity) = Unit
            override suspend fun deleteByAlarmId(alarmId: Long) = Unit
            override suspend fun getActive(): List<com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity> = emptyList()
            override suspend fun getActiveByTriggerId(triggerId: String) = null
            override suspend fun deleteByTriggerId(triggerId: String) = Unit
            override suspend fun clearAll() = Unit
            override suspend fun setActive(triggerId: String, active: Boolean) = Unit
        },
        recoveryStateProvider = object : RecoveryStateProvider {
            override suspend fun getLastRecoveryState(): LastRecoveryState =
                LastRecoveryState("BOOT_COMPLETED", "ok", 1L)
        },
    ) {
        override fun snapshot(engineMode: String): ReliabilitySnapshot {
            return ReliabilitySnapshot(
                exactAlarmPermissionGranted = true,
                notificationsPermissionGranted = true,
                canScheduleExactAlarms = true,
                engineMode = engineMode,
                schedulerHealth = "healthy",
                nativeRingPipelineEnabled = true,
                legacyEmergencyRingFallbackEnabled = true,
                directBootReady = true,
                channelHealth = "healthy",
                fullScreenReady = true,
                batteryOptimizationRisk = "low",
                scheduleRegistryHealth = "healthy",
                lastRecoveryReason = "BOOT_COMPLETED",
                lastRecoveryAtUtcMillis = 1,
                lastRecoveryStatus = "ok",
                legacyFallbackDefaultEnabled = false,
            )
        }
    }
}
