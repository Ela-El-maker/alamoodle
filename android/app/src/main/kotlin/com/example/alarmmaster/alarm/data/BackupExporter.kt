package com.example.alarmmaster.alarm.data

import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.data.dao.BackupMetadataDao
import com.example.alarmmaster.alarm.data.dao.DailyAlarmStatsDao
import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.AlarmTemplate
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.TemplateRepository
import org.json.JSONArray
import org.json.JSONObject

class BackupExporter(
    private val alarmRepository: AlarmRepository,
    private val templateRepository: TemplateRepository,
    private val dailyAlarmStatsDao: DailyAlarmStatsDao,
    private val backupMetadataDao: BackupMetadataDao,
) {
    suspend fun exportJson(): String {
        val now = System.currentTimeMillis()
        val alarms = alarmRepository.getAll()
        val templates = templateRepository.getAll()
        val dailyStats = dailyAlarmStatsDao.getAll()

        val payload = JSONObject()
            .put("version", BACKUP_VERSION)
            .put(
                "manifest",
                JSONObject()
                    .put("createdAtUtcMillis", now)
                    .put("engineMode", AlarmRuntimePolicy.ENGINE_MODE)
                    .put("includesDailyStats", true),
            )
            .put("alarms", JSONArray(alarms.map { it.toJson() }))
            .put("templates", JSONArray(templates.map { it.toJson() }))
            .put(
                "dailyStats",
                JSONArray(
                    dailyStats.map {
                        JSONObject()
                            .put("dayUtcStartMillis", it.dayUtcStartMillis)
                            .put("fired", it.fired)
                            .put("dismissed", it.dismissed)
                            .put("snoozed", it.snoozed)
                            .put("missed", it.missed)
                            .put("repaired", it.repaired)
                    },
                ),
            )

        backupMetadataDao.upsert(
            com.example.alarmmaster.alarm.data.entities.BackupMetadataEntity(
                id = 1,
                lastExportAtUtcMillis = now,
                lastImportAtUtcMillis = backupMetadataDao.get()?.lastImportAtUtcMillis,
                lastVersion = BACKUP_VERSION,
            ),
        )
        return payload.toString(2)
    }

    private fun AlarmPlan.toJson(): JSONObject {
        return JSONObject()
            .put("alarmId", alarmId)
            .put("title", title)
            .put("hour24", hour24)
            .put("minute", minute)
            .put("repeatDays", JSONArray(repeatDays))
            .put("enabled", enabled)
            .put("sound", sound)
            .put("challenge", challenge)
            .put("snoozeCount", snoozeCount)
            .put("snoozeDuration", snoozeDuration)
            .put("vibration", vibration)
            .put("vibrationProfileId", vibrationProfileId)
            .put("escalationPolicy", escalationPolicy)
            .put("nagPolicy", nagPolicy)
            .put("primaryAction", primaryAction)
            .put("challengePolicy", challengePolicy)
            .put("anchorUtcMillis", anchorUtcMillis)
            .put("timezoneId", timezoneId)
            .put("timezonePolicy", timezonePolicy.name)
            .put("preReminderMinutes", JSONArray(preReminderMinutes))
            .put("recurrenceType", recurrenceType)
            .put("recurrenceInterval", recurrenceInterval)
            .put("recurrenceWeekdays", JSONArray(recurrenceWeekdays))
            .put("recurrenceDayOfMonth", recurrenceDayOfMonth)
            .put("recurrenceOrdinal", recurrenceOrdinal)
            .put("recurrenceOrdinalWeekday", recurrenceOrdinalWeekday)
            .put("recurrenceExclusionDates", JSONArray(recurrenceExclusionDates))
            .put("reminderOffsetsMinutes", JSONArray(reminderOffsetsMinutes))
            .put("reminderBeforeOnly", reminderBeforeOnly)
            .put("createdAtUtcMillis", createdAtUtcMillis)
            .put("updatedAtUtcMillis", updatedAtUtcMillis)
    }

    private fun AlarmTemplate.toJson(): JSONObject {
        return JSONObject()
            .put("templateId", templateId)
            .put("name", name)
            .put("title", title)
            .put("hour24", hour24)
            .put("minute", minute)
            .put("repeatDays", JSONArray(repeatDays))
            .put("sound", sound)
            .put("vibration", vibration)
            .put("vibrationProfileId", vibrationProfileId)
            .put("escalationPolicy", escalationPolicy)
            .put("nagPolicy", nagPolicy)
            .put("primaryAction", primaryAction)
            .put("challenge", challenge)
            .put("challengePolicy", challengePolicy)
            .put("snoozeCount", snoozeCount)
            .put("snoozeDuration", snoozeDuration)
            .put("recurrenceType", recurrenceType)
            .put("recurrenceInterval", recurrenceInterval)
            .put("recurrenceWeekdays", JSONArray(recurrenceWeekdays))
            .put("recurrenceDayOfMonth", recurrenceDayOfMonth)
            .put("recurrenceOrdinal", recurrenceOrdinal)
            .put("recurrenceOrdinalWeekday", recurrenceOrdinalWeekday)
            .put("recurrenceExclusionDates", JSONArray(recurrenceExclusionDates))
            .put("reminderOffsetsMinutes", JSONArray(reminderOffsetsMinutes))
            .put("reminderBeforeOnly", reminderBeforeOnly)
            .put("timezonePolicy", timezonePolicy)
    }

    companion object {
        const val BACKUP_VERSION = 1
    }
}
