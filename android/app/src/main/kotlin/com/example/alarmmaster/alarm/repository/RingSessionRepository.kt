package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.data.entities.RingSessionEntity

interface RingSessionRepository {
    suspend fun startSession(sessionId: String, alarmId: Long, triggerId: String)
    suspend fun endSession(sessionId: String, outcome: String)
    suspend fun getById(sessionId: String): RingSessionEntity?
}
