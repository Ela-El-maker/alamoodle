package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.RingSessionEntity

@Dao
interface RingSessionDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: RingSessionEntity)

    @Query("SELECT * FROM ring_sessions WHERE sessionId = :sessionId LIMIT 1")
    suspend fun getById(sessionId: String): RingSessionEntity?

    @Query(
        """
        UPDATE ring_sessions
        SET endedAtUtcMillis = :endedAtUtcMillis, outcome = :outcome
        WHERE sessionId = :sessionId
        """
    )
    suspend fun endSession(sessionId: String, endedAtUtcMillis: Long, outcome: String)

    @Query("DELETE FROM ring_sessions")
    suspend fun clearAll()
}
