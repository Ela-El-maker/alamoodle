package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.data.dao.AlarmHistoryDao
import com.example.alarmmaster.alarm.data.entities.AlarmHistoryEntity
import com.example.alarmmaster.alarm.domain.AlarmHistoryRecord

class HistoryRepositoryImpl(
    private val alarmHistoryDao: AlarmHistoryDao,
    private val statsAggregationService: com.example.alarmmaster.alarm.diagnostics.StatsAggregationService? = null,
) : HistoryRepository {
    override suspend fun record(alarmId: Long, triggerId: String, eventType: String, meta: String) {
        val occurredAt = System.currentTimeMillis()
        alarmHistoryDao.insert(
            AlarmHistoryEntity(
                alarmId = alarmId,
                triggerId = triggerId,
                eventType = eventType,
                occurredAtUtcMillis = occurredAt,
                meta = meta,
            ),
        )
        statsAggregationService?.recordHistoryEvent(eventType, occurredAt)
    }

    override suspend fun getByAlarmId(alarmId: Long): List<AlarmHistoryRecord> {
        return alarmHistoryDao.getByAlarmId(alarmId).map { it.toDomain() }
    }

    override suspend fun getRecent(limit: Int, alarmId: Long?): List<AlarmHistoryRecord> {
        val entities = if (alarmId == null) {
            alarmHistoryDao.getRecent(limit)
        } else {
            alarmHistoryDao.getRecentByAlarmId(alarmId, limit)
        }
        return entities.map { it.toDomain() }
    }
}
