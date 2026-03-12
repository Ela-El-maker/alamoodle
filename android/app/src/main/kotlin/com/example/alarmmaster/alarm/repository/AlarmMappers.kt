package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.data.entities.AlarmHistoryEntity
import com.example.alarmmaster.alarm.data.entities.AlarmPlanEntity
import com.example.alarmmaster.alarm.data.entities.TriggerInstanceEntity
import com.example.alarmmaster.alarm.domain.AlarmHistoryRecord
import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus

internal fun AlarmPlanEntity.toDomain(): AlarmPlan {
    return AlarmPlan(
        alarmId = alarmId,
        title = title,
        hour24 = hour24,
        minute = minute,
        repeatDays = repeatDaysCsv.split(',').filter { it.isNotBlank() },
        enabled = enabled,
        sound = sound,
        challenge = challenge,
        snoozeCount = snoozeCount,
        snoozeDuration = snoozeDuration,
        vibration = vibration,
        vibrationProfileId = vibrationProfileId,
        escalationPolicy = escalationPolicy,
        nagPolicy = nagPolicy,
        primaryAction = primaryAction,
        challengePolicy = challengePolicy,
        anchorUtcMillis = anchorUtcMillis,
        timezoneId = timezoneId,
        timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
        preReminderMinutes = preReminderMinutesCsv.split(',').mapNotNull { it.toIntOrNull() },
        recurrenceType = recurrenceType,
        recurrenceInterval = recurrenceInterval,
        recurrenceWeekdays = recurrenceWeekdaysCsv.split(',').mapNotNull { it.toIntOrNull() },
        recurrenceDayOfMonth = recurrenceDayOfMonth,
        recurrenceOrdinal = recurrenceOrdinal,
        recurrenceOrdinalWeekday = recurrenceOrdinalWeekday,
        recurrenceExclusionDates = recurrenceExclusionDatesCsv.split(',').filter { it.isNotBlank() },
        reminderOffsetsMinutes = reminderOffsetsMinutesCsv.split(',').mapNotNull { it.toIntOrNull() },
        reminderBeforeOnly = reminderBeforeOnly,
        createdAtUtcMillis = createdAtUtcMillis,
        updatedAtUtcMillis = updatedAtUtcMillis,
    )
}

internal fun AlarmPlan.toEntity(): AlarmPlanEntity {
    return AlarmPlanEntity(
        alarmId = alarmId,
        title = title,
        hour24 = hour24,
        minute = minute,
        repeatDaysCsv = repeatDays.joinToString(","),
        enabled = enabled,
        sound = sound,
        challenge = challenge,
        snoozeCount = snoozeCount,
        snoozeDuration = snoozeDuration,
        vibration = vibration,
        vibrationProfileId = vibrationProfileId,
        escalationPolicy = escalationPolicy,
        nagPolicy = nagPolicy,
        primaryAction = primaryAction,
        challengePolicy = challengePolicy,
        anchorUtcMillis = anchorUtcMillis,
        timezoneId = timezoneId,
        timezonePolicy = timezonePolicy.name,
        preReminderMinutesCsv = preReminderMinutes.joinToString(","),
        recurrenceType = recurrenceType,
        recurrenceInterval = recurrenceInterval,
        recurrenceWeekdaysCsv = recurrenceWeekdays.joinToString(","),
        recurrenceDayOfMonth = recurrenceDayOfMonth,
        recurrenceOrdinal = recurrenceOrdinal,
        recurrenceOrdinalWeekday = recurrenceOrdinalWeekday,
        recurrenceExclusionDatesCsv = recurrenceExclusionDates.joinToString(","),
        reminderOffsetsMinutesCsv = reminderOffsetsMinutes.joinToString(","),
        reminderBeforeOnly = reminderBeforeOnly,
        createdAtUtcMillis = createdAtUtcMillis,
        updatedAtUtcMillis = updatedAtUtcMillis,
    )
}

internal fun TriggerInstance.toEntity(): TriggerInstanceEntity {
    return TriggerInstanceEntity(
        triggerId = triggerId,
        alarmId = alarmId,
        kind = kind.name,
        scheduledLocalIso = scheduledLocalIso,
        scheduledUtcMillis = scheduledUtcMillis,
        requestCode = requestCode,
        status = status.name,
        generation = generation,
    )
}

internal fun TriggerInstanceEntity.toDomain(): TriggerInstance {
    return TriggerInstance(
        triggerId = triggerId,
        alarmId = alarmId,
        kind = TriggerKind.valueOf(kind),
        scheduledLocalIso = scheduledLocalIso,
        scheduledUtcMillis = scheduledUtcMillis,
        requestCode = requestCode,
        status = TriggerStatus.valueOf(status),
        generation = generation,
    )
}

internal fun AlarmHistoryEntity.toDomain(): AlarmHistoryRecord {
    return AlarmHistoryRecord(
        historyId = historyId,
        alarmId = alarmId,
        triggerId = triggerId,
        eventType = eventType,
        occurredAtUtcMillis = occurredAtUtcMillis,
        meta = meta,
    )
}
