package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "daily_alarm_stats")
data class DailyAlarmStatsEntity(
    @PrimaryKey val dayUtcStartMillis: Long,
    val fired: Int,
    val dismissed: Int,
    val snoozed: Int,
    val missed: Int,
    val repaired: Int,
)
