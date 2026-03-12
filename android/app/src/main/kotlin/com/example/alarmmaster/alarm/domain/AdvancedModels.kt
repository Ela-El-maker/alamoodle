package com.example.alarmmaster.alarm.domain

data class AlarmTemplate(
    val templateId: Long,
    val name: String,
    val title: String,
    val hour24: Int,
    val minute: Int,
    val repeatDays: List<String>,
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
    val recurrenceWeekdays: List<Int>,
    val recurrenceDayOfMonth: Int?,
    val recurrenceOrdinal: Int?,
    val recurrenceOrdinalWeekday: Int?,
    val recurrenceExclusionDates: List<String>,
    val reminderOffsetsMinutes: List<Int>,
    val reminderBeforeOnly: Boolean,
    val timezonePolicy: String,
)

data class BackupImportResult(
    val success: Boolean,
    val message: String,
    val restoredAlarms: Int,
    val restoredTemplates: Int,
)

data class OemGuidance(
    val manufacturer: String,
    val title: String,
    val summary: String,
    val steps: List<String>,
    val settingsTargets: List<String>,
)
