package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "alarm_history",
    indices = [Index(value = ["alarmId"]), Index(value = ["occurredAtUtcMillis"])],
)
data class AlarmHistoryEntity(
    @PrimaryKey(autoGenerate = true) val historyId: Long = 0,
    val alarmId: Long,
    val triggerId: String,
    val eventType: String,
    val occurredAtUtcMillis: Long,
    val meta: String,
)
