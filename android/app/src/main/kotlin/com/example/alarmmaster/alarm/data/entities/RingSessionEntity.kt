package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "ring_sessions",
    indices = [Index(value = ["alarmId"]), Index(value = ["startedAtUtcMillis"])],
)
data class RingSessionEntity(
    @PrimaryKey val sessionId: String,
    val alarmId: Long,
    val triggerId: String,
    val startedAtUtcMillis: Long,
    val endedAtUtcMillis: Long?,
    val outcome: String,
    val driftMs: Long,
)
