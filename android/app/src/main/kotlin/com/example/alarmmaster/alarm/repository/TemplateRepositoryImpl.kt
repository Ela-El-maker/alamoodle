package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.data.dao.AlarmTemplateDao
import com.example.alarmmaster.alarm.data.entities.AlarmTemplateEntity
import com.example.alarmmaster.alarm.domain.AlarmTemplate

class TemplateRepositoryImpl(
    private val dao: AlarmTemplateDao,
) : TemplateRepository {
    override suspend fun getAll(): List<AlarmTemplate> = dao.getAll().map { it.toDomain() }

    override suspend fun getById(templateId: Long): AlarmTemplate? = dao.getById(templateId)?.toDomain()

    override suspend fun upsert(template: AlarmTemplate): AlarmTemplate {
        val entity = template.toEntity()
        val savedId = dao.upsert(entity)
        return template.copy(templateId = if (template.templateId > 0) template.templateId else savedId)
    }

    override suspend fun delete(templateId: Long) {
        dao.deleteById(templateId)
    }

    override suspend fun clearAll() {
        dao.clearAll()
    }
}

private fun AlarmTemplateEntity.toDomain(): AlarmTemplate {
    return AlarmTemplate(
        templateId = templateId,
        name = name,
        title = title,
        hour24 = hour24,
        minute = minute,
        repeatDays = repeatDaysCsv.split(',').filter { it.isNotBlank() },
        sound = sound,
        vibration = vibration,
        vibrationProfileId = vibrationProfileId,
        escalationPolicy = escalationPolicy,
        nagPolicy = nagPolicy,
        primaryAction = primaryAction,
        challenge = challenge,
        challengePolicy = challengePolicy,
        snoozeCount = snoozeCount,
        snoozeDuration = snoozeDuration,
        recurrenceType = recurrenceType,
        recurrenceInterval = recurrenceInterval,
        recurrenceWeekdays = recurrenceWeekdaysCsv.split(',').mapNotNull { it.toIntOrNull() },
        recurrenceDayOfMonth = recurrenceDayOfMonth,
        recurrenceOrdinal = recurrenceOrdinal,
        recurrenceOrdinalWeekday = recurrenceOrdinalWeekday,
        recurrenceExclusionDates = recurrenceExclusionDatesCsv.split(',').filter { it.isNotBlank() },
        reminderOffsetsMinutes = reminderOffsetsMinutesCsv.split(',').mapNotNull { it.toIntOrNull() },
        reminderBeforeOnly = reminderBeforeOnly,
        timezonePolicy = timezonePolicy,
    )
}

private fun AlarmTemplate.toEntity(): AlarmTemplateEntity {
    return AlarmTemplateEntity(
        templateId = templateId,
        name = name,
        title = title,
        hour24 = hour24,
        minute = minute,
        repeatDaysCsv = repeatDays.joinToString(","),
        sound = sound,
        vibration = vibration,
        vibrationProfileId = vibrationProfileId,
        escalationPolicy = escalationPolicy,
        nagPolicy = nagPolicy,
        primaryAction = primaryAction,
        challenge = challenge,
        challengePolicy = challengePolicy,
        snoozeCount = snoozeCount,
        snoozeDuration = snoozeDuration,
        recurrenceType = recurrenceType,
        recurrenceInterval = recurrenceInterval,
        recurrenceWeekdaysCsv = recurrenceWeekdays.joinToString(","),
        recurrenceDayOfMonth = recurrenceDayOfMonth,
        recurrenceOrdinal = recurrenceOrdinal,
        recurrenceOrdinalWeekday = recurrenceOrdinalWeekday,
        recurrenceExclusionDatesCsv = recurrenceExclusionDates.joinToString(","),
        reminderOffsetsMinutesCsv = reminderOffsetsMinutes.joinToString(","),
        reminderBeforeOnly = reminderBeforeOnly,
        timezonePolicy = timezonePolicy,
    )
}
