package com.example.alarmmaster.alarm.diagnostics

import com.example.alarmmaster.alarm.domain.AlarmHistoryRecord
import com.example.alarmmaster.alarm.repository.HistoryRepository

class HistoryReadService(
    private val historyRepository: HistoryRepository,
) {
    suspend fun getRecent(limit: Int, alarmId: Long?): List<AlarmHistoryRecord> {
        return historyRepository.getRecent(limit = limit, alarmId = alarmId)
    }
}
