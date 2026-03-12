package com.example.alarmmaster.alarm.domain

enum class TimezonePolicy {
    FIXED_LOCAL_TIME,
}

enum class TriggerKind {
    PRE,
    MAIN,
    SNOOZE,
}

enum class TriggerStatus {
    SCHEDULED,
    FIRED,
    CANCELLED,
}

data class AlarmPlan(
    val alarmId: Long,
    val title: String,
    val hour24: Int,
    val minute: Int,
    val repeatDays: List<String>,
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
    val timezonePolicy: TimezonePolicy,
    val preReminderMinutes: List<Int>,
    val recurrenceType: String? = null,
    val recurrenceInterval: Int? = null,
    val recurrenceWeekdays: List<Int> = emptyList(),
    val recurrenceDayOfMonth: Int? = null,
    val recurrenceOrdinal: Int? = null,
    val recurrenceOrdinalWeekday: Int? = null,
    val recurrenceExclusionDates: List<String> = emptyList(),
    val reminderOffsetsMinutes: List<Int> = emptyList(),
    val reminderBeforeOnly: Boolean = false,
    val createdAtUtcMillis: Long,
    val updatedAtUtcMillis: Long,
)

data class TriggerInstance(
    val triggerId: String,
    val alarmId: Long,
    val kind: TriggerKind,
    val scheduledLocalIso: String,
    val scheduledUtcMillis: Long,
    val requestCode: Int,
    val status: TriggerStatus,
    val generation: Int,
)

data class ReliabilitySnapshot(
    val exactAlarmPermissionGranted: Boolean,
    val notificationsPermissionGranted: Boolean,
    val canScheduleExactAlarms: Boolean,
    val engineMode: String,
    val schedulerHealth: String,
    val nativeRingPipelineEnabled: Boolean,
    val legacyEmergencyRingFallbackEnabled: Boolean,
    val directBootReady: Boolean,
    val channelHealth: String,
    val fullScreenReady: Boolean,
    val batteryOptimizationRisk: String,
    val scheduleRegistryHealth: String,
    val lastRecoveryReason: String,
    val lastRecoveryAtUtcMillis: Long?,
    val lastRecoveryStatus: String,
    val legacyFallbackDefaultEnabled: Boolean,
)

data class AlarmHistoryRecord(
    val historyId: Long,
    val alarmId: Long,
    val triggerId: String,
    val eventType: String,
    val occurredAtUtcMillis: Long,
    val meta: String,
)

data class TestAlarmResult(
    val success: Boolean,
    val message: String,
    val scheduledAtUtcMillis: Long?,
)
