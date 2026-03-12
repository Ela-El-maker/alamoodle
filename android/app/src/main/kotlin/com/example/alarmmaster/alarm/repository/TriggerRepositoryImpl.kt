package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.data.dao.TriggerInstanceDao
import com.example.alarmmaster.alarm.domain.TriggerInstance

class TriggerRepositoryImpl(
    private val triggerInstanceDao: TriggerInstanceDao,
) : TriggerRepository {
    override suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>) {
        triggerInstanceDao.deleteByAlarmId(alarmId)
        if (triggers.isNotEmpty()) {
            triggerInstanceDao.upsertAll(triggers.map { it.toEntity() })
        }
    }

    override suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance> {
        return triggerInstanceDao.getByAlarmId(alarmId).map { it.toDomain() }
    }

    override suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance> {
        return triggerInstanceDao.getFuture(fromUtcMillis).map { it.toDomain() }
    }

    override suspend fun getByTriggerId(triggerId: String): TriggerInstance? {
        return triggerInstanceDao.getByTriggerId(triggerId)?.toDomain()
    }

    override suspend fun upsertTrigger(trigger: TriggerInstance) {
        triggerInstanceDao.upsert(trigger.toEntity())
    }

    override suspend fun updateStatus(triggerId: String, status: String) {
        triggerInstanceDao.updateStatus(triggerId, status)
    }

    override suspend fun clearForAlarm(alarmId: Long) {
        triggerInstanceDao.deleteByAlarmId(alarmId)
    }
}
