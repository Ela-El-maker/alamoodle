package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "alarm_plans")
data class AlarmPlanEntity(
    @PrimaryKey val alarmId: Long,
    val title: String,
    val hour24: Int,
    val minute: Int,
    val repeatDaysCsv: String,
    val enabled: Boolean,
    val sound: String,
    val challenge: String,
    val snoozeCount: Int,
    val snoozeDuration: Int,
    val vibration: Boolean,
    val vibrationProfileId: String? = null,
    val escalationPolicy: String? = null,
    val nagPolicy: String? = null,
    val primaryAction: String? = null,
    val challengePolicy: String? = null,
    val anchorUtcMillis: Long?,
    val timezoneId: String,
    val timezonePolicy: String,
    val preReminderMinutesCsv: String,
    val recurrenceType: String? = null,
    val recurrenceInterval: Int? = null,
    val recurrenceWeekdaysCsv: String = "",
    val recurrenceDayOfMonth: Int? = null,
    val recurrenceOrdinal: Int? = null,
    val recurrenceOrdinalWeekday: Int? = null,
    val recurrenceExclusionDatesCsv: String = "",
    val reminderOffsetsMinutesCsv: String = "",
    val reminderBeforeOnly: Boolean = false,
    val createdAtUtcMillis: Long,
    val updatedAtUtcMillis: Long,
)
