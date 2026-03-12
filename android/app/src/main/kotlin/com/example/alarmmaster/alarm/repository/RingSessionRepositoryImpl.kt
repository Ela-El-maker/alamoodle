package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.data.dao.RingSessionDao
import com.example.alarmmaster.alarm.data.entities.RingSessionEntity

class RingSessionRepositoryImpl(
    private val ringSessionDao: RingSessionDao,
) : RingSessionRepository {
    override suspend fun startSession(sessionId: String, alarmId: Long, triggerId: String) {
        ringSessionDao.upsert(
            RingSessionEntity(
                sessionId = sessionId,
                alarmId = alarmId,
                triggerId = triggerId,
                startedAtUtcMillis = System.currentTimeMillis(),
                endedAtUtcMillis = null,
                outcome = "RINGING",
                driftMs = 0,
            ),
        )
    }

    override suspend fun endSession(sessionId: String, outcome: String) {
        ringSessionDao.endSession(
            sessionId = sessionId,
            endedAtUtcMillis = System.currentTimeMillis(),
            outcome = outcome,
        )
    }

    override suspend fun getById(sessionId: String): RingSessionEntity? {
        return ringSessionDao.getById(sessionId)
    }
}
