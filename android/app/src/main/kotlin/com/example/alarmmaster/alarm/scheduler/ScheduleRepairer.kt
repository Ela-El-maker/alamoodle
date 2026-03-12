package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.data.dao.ScheduleRegistryDao
import com.example.alarmmaster.alarm.repository.TriggerRepository

data class ScheduleRepairReport(
    val examined: Int,
    val restored: Int,
    val staleRemoved: Int,
)

class ScheduleRepairer(
    private val triggerRepository: TriggerRepository,
    private val alarmScheduler: AlarmScheduler,
    private val scheduleRegistryDao: ScheduleRegistryDao? = null,
) {
    suspend fun repairFutureSchedule(nowUtcMillis: Long = System.currentTimeMillis()): Int {
        return repairFutureScheduleDetailed(nowUtcMillis).restored
    }

    suspend fun repairFutureScheduleDetailed(
        nowUtcMillis: Long = System.currentTimeMillis(),
        forceRescheduleAll: Boolean = false,
    ): ScheduleRepairReport {
        val future = triggerRepository.getFuture(nowUtcMillis)
        val activeRegistry = scheduleRegistryDao?.getActive().orEmpty().associateBy { it.triggerId }
        var restored = 0
        future.forEach { trigger ->
            if (forceRescheduleAll || activeRegistry[trigger.triggerId] == null) {
                alarmScheduler.scheduleTrigger(trigger)
                restored += 1
            }
        }

        var staleRemoved = 0
        if (scheduleRegistryDao != null) {
            val futureIds = future.map { it.triggerId }.toSet()
            activeRegistry.values.forEach { entry ->
                if (!futureIds.contains(entry.triggerId)) {
                    scheduleRegistryDao.deleteByTriggerId(entry.triggerId)
                    staleRemoved += 1
                }
            }
        }

        return ScheduleRepairReport(
            examined = future.size,
            restored = restored,
            staleRemoved = staleRemoved,
        )
    }
}
