package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import com.example.alarmmaster.alarm.data.dao.ScheduleRegistryDao
import com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity
import com.example.alarmmaster.alarm.repository.TriggerRepository
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test

class ScheduleRepairerTest {
    @Test
    fun schedulesFutureTriggers_withoutDestructiveRebuild() = runBlocking {
        val trigger = TriggerInstance(
            triggerId = "t-1",
            alarmId = 1,
            kind = TriggerKind.MAIN,
            scheduledLocalIso = "2026-04-20T15:00",
            scheduledUtcMillis = System.currentTimeMillis() + 60_000,
            requestCode = 123,
            status = TriggerStatus.SCHEDULED,
            generation = 1,
        )

        val fakeRepo = object : TriggerRepository {
            override suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
            override suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance> = listOf(trigger)
            override suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance> = listOf(trigger)
            override suspend fun clearForAlarm(alarmId: Long) = Unit
            override suspend fun getByTriggerId(triggerId: String): TriggerInstance? =
                if (triggerId == trigger.triggerId) trigger else null

            override suspend fun upsertTrigger(trigger: TriggerInstance) = Unit
            override suspend fun updateStatus(triggerId: String, status: String) = Unit
        }

        var scheduledCount = 0
        val fakeScheduler = object : AlarmScheduler {
            override fun scheduleTrigger(trigger: TriggerInstance) {
                scheduledCount += 1
            }

            override fun scheduleAll(triggers: List<TriggerInstance>) {
                scheduledCount += triggers.size
            }

            override fun cancelTrigger(trigger: TriggerInstance) = Unit
            override fun cancelAllForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
        }

        val repairer = ScheduleRepairer(fakeRepo, fakeScheduler)
        val repaired = repairer.repairFutureSchedule()

        assertEquals(1, repaired)
        assertEquals(1, scheduledCount)
    }

    @Test
    fun removesStaleRegistryEntries_nonDestructive() = runBlocking {
        val futureTrigger = TriggerInstance(
            triggerId = "t-future",
            alarmId = 1,
            kind = TriggerKind.MAIN,
            scheduledLocalIso = "2026-04-20T15:00",
            scheduledUtcMillis = System.currentTimeMillis() + 60_000,
            requestCode = 123,
            status = TriggerStatus.SCHEDULED,
            generation = 1,
        )
        val staleRegistry = ScheduleRegistryEntity(
            triggerId = "stale",
            alarmId = 2,
            requestCode = 999,
            scheduledUtcMillis = System.currentTimeMillis() - 60_000,
            active = true,
        )

        val fakeRepo = object : TriggerRepository {
            override suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
            override suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance> = listOf(futureTrigger)
            override suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance> = listOf(futureTrigger)
            override suspend fun clearForAlarm(alarmId: Long) = Unit
            override suspend fun getByTriggerId(triggerId: String): TriggerInstance? = null
            override suspend fun upsertTrigger(trigger: TriggerInstance) = Unit
            override suspend fun updateStatus(triggerId: String, status: String) = Unit
        }

        val fakeScheduler = object : AlarmScheduler {
            override fun scheduleTrigger(trigger: TriggerInstance) = Unit
            override fun scheduleAll(triggers: List<TriggerInstance>) = Unit
            override fun cancelTrigger(trigger: TriggerInstance) = Unit
            override fun cancelAllForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
        }

        val removed = mutableListOf<String>()
        val fakeRegistry = object : ScheduleRegistryDao {
            override suspend fun upsert(entity: ScheduleRegistryEntity) = Unit
            override suspend fun deleteByAlarmId(alarmId: Long) = Unit
            override suspend fun getActive(): List<ScheduleRegistryEntity> = listOf(staleRegistry)
            override suspend fun getActiveByTriggerId(triggerId: String): ScheduleRegistryEntity? = null
            override suspend fun deleteByTriggerId(triggerId: String) {
                removed += triggerId
            }
            override suspend fun clearAll() = Unit
            override suspend fun setActive(triggerId: String, active: Boolean) = Unit
        }

        val report = ScheduleRepairer(fakeRepo, fakeScheduler, fakeRegistry).repairFutureScheduleDetailed()
        assertEquals(1, report.examined)
        assertEquals(1, report.staleRemoved)
        assertEquals(listOf("stale"), removed)
    }

    @Test
    fun removesStaleRegistryEntries_evenWhenNoFutureTriggersRemain() = runBlocking {
        val staleRegistry = ScheduleRegistryEntity(
            triggerId = "stale-only",
            alarmId = 2,
            requestCode = 999,
            scheduledUtcMillis = System.currentTimeMillis() + 60_000,
            active = true,
        )

        val fakeRepo = object : TriggerRepository {
            override suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
            override suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance> = emptyList()
            override suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance> = emptyList()
            override suspend fun clearForAlarm(alarmId: Long) = Unit
            override suspend fun getByTriggerId(triggerId: String): TriggerInstance? = null
            override suspend fun upsertTrigger(trigger: TriggerInstance) = Unit
            override suspend fun updateStatus(triggerId: String, status: String) = Unit
        }

        val fakeScheduler = object : AlarmScheduler {
            override fun scheduleTrigger(trigger: TriggerInstance) = Unit
            override fun scheduleAll(triggers: List<TriggerInstance>) = Unit
            override fun cancelTrigger(trigger: TriggerInstance) = Unit
            override fun cancelAllForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
        }

        val removed = mutableListOf<String>()
        val fakeRegistry = object : ScheduleRegistryDao {
            override suspend fun upsert(entity: ScheduleRegistryEntity) = Unit
            override suspend fun deleteByAlarmId(alarmId: Long) = Unit
            override suspend fun getActive(): List<ScheduleRegistryEntity> = listOf(staleRegistry)
            override suspend fun getActiveByTriggerId(triggerId: String): ScheduleRegistryEntity? = null
            override suspend fun deleteByTriggerId(triggerId: String) {
                removed += triggerId
            }
            override suspend fun clearAll() = Unit
            override suspend fun setActive(triggerId: String, active: Boolean) = Unit
        }

        val report = ScheduleRepairer(fakeRepo, fakeScheduler, fakeRegistry).repairFutureScheduleDetailed()
        assertEquals(0, report.examined)
        assertEquals(0, report.restored)
        assertEquals(1, report.staleRemoved)
        assertEquals(listOf("stale-only"), removed)
    }

    @Test
    fun forceRescheduleAll_rebuildsFutureSchedulesEvenWhenRegistryLooksHealthy() = runBlocking {
        val futureTrigger = TriggerInstance(
            triggerId = "t-force",
            alarmId = 7,
            kind = TriggerKind.MAIN,
            scheduledLocalIso = "2026-04-20T15:00",
            scheduledUtcMillis = System.currentTimeMillis() + 60_000,
            requestCode = 707,
            status = TriggerStatus.SCHEDULED,
            generation = 7,
        )

        val fakeRepo = object : TriggerRepository {
            override suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
            override suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance> = listOf(futureTrigger)
            override suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance> = listOf(futureTrigger)
            override suspend fun clearForAlarm(alarmId: Long) = Unit
            override suspend fun getByTriggerId(triggerId: String): TriggerInstance? = null
            override suspend fun upsertTrigger(trigger: TriggerInstance) = Unit
            override suspend fun updateStatus(triggerId: String, status: String) = Unit
        }

        var scheduledCount = 0
        val fakeScheduler = object : AlarmScheduler {
            override fun scheduleTrigger(trigger: TriggerInstance) {
                scheduledCount += 1
            }

            override fun scheduleAll(triggers: List<TriggerInstance>) = Unit
            override fun cancelTrigger(trigger: TriggerInstance) = Unit
            override fun cancelAllForAlarm(alarmId: Long, triggers: List<TriggerInstance>) = Unit
        }

        val fakeRegistry = object : ScheduleRegistryDao {
            override suspend fun upsert(entity: ScheduleRegistryEntity) = Unit
            override suspend fun deleteByAlarmId(alarmId: Long) = Unit
            override suspend fun getActive(): List<ScheduleRegistryEntity> = listOf(
                ScheduleRegistryEntity(
                    triggerId = "t-force",
                    alarmId = 7,
                    requestCode = 707,
                    scheduledUtcMillis = futureTrigger.scheduledUtcMillis,
                    active = true,
                ),
            )
            override suspend fun getActiveByTriggerId(triggerId: String): ScheduleRegistryEntity? = null
            override suspend fun deleteByTriggerId(triggerId: String) = Unit
            override suspend fun clearAll() = Unit
            override suspend fun setActive(triggerId: String, active: Boolean) = Unit
        }

        val report = ScheduleRepairer(fakeRepo, fakeScheduler, fakeRegistry)
            .repairFutureScheduleDetailed(forceRescheduleAll = true)
        assertEquals(1, report.examined)
        assertEquals(1, report.restored)
        assertEquals(0, report.staleRemoved)
        assertEquals(1, scheduledCount)
    }
}
