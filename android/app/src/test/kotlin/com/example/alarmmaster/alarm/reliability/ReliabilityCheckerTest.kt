package com.example.alarmmaster.alarm.reliability

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.example.alarmmaster.alarm.data.LastRecoveryState
import com.example.alarmmaster.alarm.data.dao.ScheduleRegistryDao
import com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity
import com.example.alarmmaster.alarm.notification.ChannelRegistry
import com.example.alarmmaster.alarm.notification.NotificationPermissionHelper
import com.example.alarmmaster.alarm.scheduler.ExactAlarmPermissionGate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ReliabilityCheckerTest {
    @Test
    fun snapshotIncludesRecoveryAndHealthFields() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val checker = ReliabilityChecker(
            context = context,
            exactAlarmPermissionGate = _ExactGate(true),
            notificationPermissionHelper = _NotificationHelper(context),
            channelRegistry = ChannelRegistry(context),
            scheduleRegistryDao = _RegistryDao(),
            recoveryStateProvider = _RecoveryStateProvider(),
        )

        val snapshot = checker.snapshot("shadow_native")

        assertEquals("shadow_native", snapshot.engineMode)
        assertTrue(snapshot.directBootReady)
        assertEquals("healthy", snapshot.scheduleRegistryHealth)
        assertEquals("BOOT_COMPLETED", snapshot.lastRecoveryReason)
    }

    private class _ExactGate(private val value: Boolean) :
        ExactAlarmPermissionGate(ApplicationProvider.getApplicationContext<Context>()) {
        override fun canScheduleExactAlarms(): Boolean = value
    }

    private class _NotificationHelper(context: Context) :
        NotificationPermissionHelper(context) {
        override fun hasNotificationPermission(): Boolean = true
        override fun areNotificationsEnabled(): Boolean = true
        override fun canUseFullScreenIntent(): Boolean = true
    }

    private class _RegistryDao : ScheduleRegistryDao {
        override suspend fun upsert(entity: ScheduleRegistryEntity) = Unit
        override suspend fun deleteByAlarmId(alarmId: Long) = Unit
        override suspend fun getActive(): List<ScheduleRegistryEntity> =
            listOf(ScheduleRegistryEntity("t", 1, 1, 1, true))

        override suspend fun getActiveByTriggerId(triggerId: String): ScheduleRegistryEntity? = null
        override suspend fun deleteByTriggerId(triggerId: String) = Unit
        override suspend fun clearAll() = Unit
        override suspend fun setActive(triggerId: String, active: Boolean) = Unit
    }

    private class _RecoveryStateProvider : RecoveryStateProvider {
        override suspend fun getLastRecoveryState(): LastRecoveryState {
            return LastRecoveryState(
                reason = "BOOT_COMPLETED",
                status = "ok",
                atUtcMillis = 1L,
            )
        }
    }
}
