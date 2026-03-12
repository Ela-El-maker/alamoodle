package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.domain.AlarmHistoryRecord

interface HistoryRepository {
    suspend fun record(alarmId: Long, triggerId: String, eventType: String, meta: String = "")
    suspend fun getByAlarmId(alarmId: Long): List<AlarmHistoryRecord>
    suspend fun getRecent(limit: Int, alarmId: Long? = null): List<AlarmHistoryRecord>
}
