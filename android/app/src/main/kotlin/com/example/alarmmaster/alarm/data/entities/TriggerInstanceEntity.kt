package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "trigger_instances",
    indices = [
        Index(value = ["alarmId"]),
        Index(value = ["scheduledUtcMillis"]),
    ],
)
data class TriggerInstanceEntity(
    @PrimaryKey val triggerId: String,
    val alarmId: Long,
    val kind: String,
    val scheduledLocalIso: String,
    val scheduledUtcMillis: Long,
    val requestCode: Int,
    val status: String,
    val generation: Int,
)
