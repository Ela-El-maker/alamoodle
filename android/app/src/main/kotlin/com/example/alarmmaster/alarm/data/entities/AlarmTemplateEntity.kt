package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "alarm_templates")
data class AlarmTemplateEntity(
    @PrimaryKey(autoGenerate = true) val templateId: Long = 0,
    val name: String,
    val title: String,
    val hour24: Int,
    val minute: Int,
    val repeatDaysCsv: String,
    val sound: String,
    val vibration: Boolean,
    val vibrationProfileId: String?,
    val escalationPolicy: String?,
    val nagPolicy: String?,
    val primaryAction: String?,
    val challenge: String,
    val challengePolicy: String?,
    val snoozeCount: Int,
    val snoozeDuration: Int,
    val recurrenceType: String?,
    val recurrenceInterval: Int?,
    val recurrenceWeekdaysCsv: String,
    val recurrenceDayOfMonth: Int?,
    val recurrenceOrdinal: Int?,
    val recurrenceOrdinalWeekday: Int?,
    val recurrenceExclusionDatesCsv: String,
    val reminderOffsetsMinutesCsv: String,
    val reminderBeforeOnly: Boolean,
    val timezonePolicy: String,
)
