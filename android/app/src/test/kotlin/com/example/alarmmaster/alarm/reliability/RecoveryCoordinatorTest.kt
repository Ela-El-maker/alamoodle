package com.example.alarmmaster.alarm.reliability

import com.example.alarmmaster.alarm.data.LastRecoveryState
import com.example.alarmmaster.alarm.data.RecoveryIndexEntry
import com.example.alarmmaster.alarm.data.RecoveryStateStore
import com.example.alarmmaster.alarm.diagnostics.EventLogger
import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.scheduler.AlarmScheduler
import com.example.alarmmaster.alarm.scheduler.ScheduleRepairer
import com.example.alarmmaster.alarm.scheduler.TriggerIdFactory
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class RecoveryCoordinatorTest {
    @Test
    fun lockedBootRestoresOnlyFutureEntries() = runBlocking {
        val now = System.currentTimeMillis()
        val store = _FakeRecoveryStore(
            index = mutableListOf(
                RecoveryIndexEntry(1, "future", "PRE", now + 60_000, 10, 1),
                RecoveryIndexEntry(1, "past", "PRE", now - 60_000, 11, 1),
            ),
            enabledIds = mutableListOf(1),
        )

        val scheduler = _RecordingScheduler()
        val coordinator = RecoveryCoordinator(
            alarmRepository = _FakeAlarmRepository(),
            triggerRepository = _FakeTriggerRepository(),
            historyRepository = _FakeHistoryRepository(),
            alarmScheduler = scheduler,
            repairer = ScheduleRepairer(_FakeTriggerRepository(), scheduler),
            recoveryStore = store,
            triggerIdFactory = TriggerIdFactory(),
            eventLogger = object : EventLogger() {
                override fun log(event: String, meta: String) = Unit
            },
        )

        val result = coordinator.recover(RecoveryReason.LOCKED_BOOT_COMPLETED, now)

        assertEquals(1, result.restoredTriggers)
        assertTrue(scheduler.scheduled.any { it.triggerId == "future" })
        assertTrue(scheduler.scheduled.none { it.triggerId == "past" })
        assertEquals("LOCKED_BOOT_COMPLETED", store.lastState?.reason)
    }

    @Test
    fun startupSanityRestoresLateMainWithinGrace() = runBlocking {
        val now = System.currentTimeMillis()
        val scheduler = _RecordingScheduler()
        val triggerRepository = _FakeTriggerRepository(
            triggersByAlarmId = mutableMapOf(
                1L to mutableListOf(
                    TriggerInstance(
                        triggerId = "late-main",
                        alarmId = 1L,
                        kind = TriggerKind.MAIN,
                        scheduledLocalIso = "2026-03-11T12:10:00",
                        scheduledUtcMillis = now - 2 * 60 * 1000L,
                        requestCode = 1001,
                        status = TriggerStatus.SCHEDULED,
                        generation = 1,
                    ),
                ),
            ),
        )
        val store = _FakeRecoveryStore(index = mutableListOf(), enabledIds = mutableListOf(1))

        val coordinator = RecoveryCoordinator(
            alarmRepository = _FakeAlarmRepository(),
            triggerRepository = triggerRepository,
            historyRepository = _FakeHistoryRepository(),
            alarmScheduler = scheduler,
            repairer = ScheduleRepairer(triggerRepository, scheduler),
            recoveryStore = store,
            triggerIdFactory = TriggerIdFactory(),
            eventLogger = object : EventLogger() {
                override fun log(event: String, meta: String) = Unit
            },
        )

        val result = coordinator.recover(RecoveryReason.STARTUP_SANITY, now)

        assertEquals(1, result.restoredTriggers)
        assertEquals("repaired", result.status)
        assertTrue(scheduler.scheduled.any { it.triggerId == "late-main" })
    }

    @Test
    fun startupSanitySkipsTooLateAndPreTriggers() = runBlocking {
        val now = System.currentTimeMillis()
        val scheduler = _RecordingScheduler()
        val triggerRepository = _FakeTriggerRepository(
            triggersByAlarmId = mutableMapOf(
                1L to mutableListOf(
                    TriggerInstance(
                        triggerId = "too-late-main",
                        alarmId = 1L,
                        kind = TriggerKind.MAIN,
                        scheduledLocalIso = "2026-03-11T12:10:00",
                        scheduledUtcMillis = now - 20 * 60 * 1000L,
                        requestCode = 1002,
                        status = TriggerStatus.SCHEDULED,
                        generation = 1,
                    ),
                    TriggerInstance(
                        triggerId = "late-pre",
                        alarmId = 1L,
                        kind = TriggerKind.PRE,
                        scheduledLocalIso = "2026-03-11T12:10:00",
                        scheduledUtcMillis = now - 2 * 60 * 1000L,
                        requestCode = 1003,
                        status = TriggerStatus.SCHEDULED,
                        generation = 1,
                    ),
                ),
            ),
        )
        val store = _FakeRecoveryStore(index = mutableListOf(), enabledIds = mutableListOf(1))

        val coordinator = RecoveryCoordinator(
            alarmRepository = _FakeAlarmRepository(),
            triggerRepository = triggerRepository,
            historyRepository = _FakeHistoryRepository(),
            alarmScheduler = scheduler,
            repairer = ScheduleRepairer(triggerRepository, scheduler),
            recoveryStore = store,
            triggerIdFactory = TriggerIdFactory(),
            eventLogger = object : EventLogger() {
                override fun log(event: String, meta: String) = Unit
            },
        )

        val result = coordinator.recover(RecoveryReason.STARTUP_SANITY, now)

        assertEquals(0, result.restoredTriggers)
        assertEquals("ok", result.status)
        assertTrue(scheduler.scheduled.none { it.triggerId == "too-late-main" || it.triggerId == "late-pre" })
    }

    private class _RecordingScheduler : AlarmScheduler {
        val scheduled = mutableListOf<TriggerInstance>()
        override fun scheduleTrigger(trigger: TriggerInstance) {
            scheduled += trigger
        }

        override fun scheduleAll(triggers: List<TriggerInstance>) {
            scheduled += triggers
        }

        override fun cancelTrigger(trigger: TriggerInstance) = Unit
        override fun cancelAllForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
    }

    private class _FakeAlarmRepository : AlarmRepository {
        override suspend fun upsert(plan: AlarmPlan) = Unit
        override suspend fun delete(alarmId: Long) = Unit
        override suspend fun getById(alarmId: Long): AlarmPlan? = null
        override suspend fun getAll(): List<AlarmPlan> =
            listOf(
                AlarmPlan(
                    alarmId = 1,
                    title = "A",
                    hour24 = 7,
                    minute = 0,
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

    private class _FakeTriggerRepository(
        private val triggersByAlarmId: MutableMap<Long, MutableList<TriggerInstance>> = mutableMapOf(),
    ) : TriggerRepository {
        override suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
        override suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance> = triggersByAlarmId[alarmId].orEmpty()
        override suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance> {
            return triggersByAlarmId.values.flatten().filter { it.scheduledUtcMillis > fromUtcMillis }
        }

        override suspend fun getByTriggerId(triggerId: String): TriggerInstance? {
            return triggersByAlarmId.values.flatten().firstOrNull { it.triggerId == triggerId }
        }

        override suspend fun upsertTrigger(trigger: TriggerInstance) = Unit
        override suspend fun updateStatus(triggerId: String, status: String) = Unit
        override suspend fun clearForAlarm(alarmId: Long) = Unit
    }

    private class _FakeHistoryRepository : HistoryRepository {
        override suspend fun record(alarmId: Long, triggerId: String, eventType: String, meta: String) = Unit
        override suspend fun getByAlarmId(alarmId: Long) = emptyList<com.example.alarmmaster.alarm.domain.AlarmHistoryRecord>()
        override suspend fun getRecent(limit: Int, alarmId: Long?) = emptyList<com.example.alarmmaster.alarm.domain.AlarmHistoryRecord>()
    }

    private class _FakeRecoveryStore(
        private val index: MutableList<RecoveryIndexEntry>,
        private val enabledIds: MutableList<Long>,
    ) : RecoveryStateStore {
        var lastState: LastRecoveryState? = null

        override suspend fun setEnabledAlarmIds(ids: List<Long>) {
            enabledIds.clear()
            enabledIds.addAll(ids)
        }

        override suspend fun getEnabledAlarmIds(): List<Long> = enabledIds.toList()

        override suspend fun setRecoveryIndex(entries: List<RecoveryIndexEntry>) {
            index.clear()
            index.addAll(entries)
        }

        override suspend fun getRecoveryIndex(): List<RecoveryIndexEntry> = index.toList()

        override suspend fun setLastRecoveryState(state: LastRecoveryState) {
            lastState = state
        }

        override suspend fun getLastRecoveryState(): LastRecoveryState {
            return lastState ?: LastRecoveryState("NONE", "UNKNOWN", null)
        }
    }
}
