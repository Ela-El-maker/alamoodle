package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "schedule_registry",
    indices = [Index(value = ["alarmId"]), Index(value = ["requestCode"], unique = true)],
)
data class ScheduleRegistryEntity(
    @PrimaryKey val triggerId: String,
    val alarmId: Long,
    val requestCode: Int,
    val scheduledUtcMillis: Long,
    val active: Boolean,
)
