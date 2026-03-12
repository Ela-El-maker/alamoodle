package com.example.alarmmaster.alarm.data

import com.example.alarmmaster.alarm.data.dao.BackupMetadataDao
import com.example.alarmmaster.alarm.data.dao.DailyAlarmStatsDao
import com.example.alarmmaster.alarm.data.entities.BackupMetadataEntity
import com.example.alarmmaster.alarm.data.entities.DailyAlarmStatsEntity
import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.BackupImportResult
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.TemplateRepository
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.scheduler.AlarmPlanner
import com.example.alarmmaster.alarm.scheduler.AlarmScheduler
import org.json.JSONArray
import org.json.JSONObject

class BackupImporter(
    private val alarmRepository: AlarmRepository,
    private val triggerRepository: TriggerRepository,
    private val historyRepository: HistoryRepository,
    private val templateRepository: TemplateRepository,
    private val dailyAlarmStatsDao: DailyAlarmStatsDao,
    private val backupMetadataDao: BackupMetadataDao,
    private val planner: AlarmPlanner,
    private val alarmScheduler: AlarmScheduler,
) {
    suspend fun importJson(
        payload: String,
        replaceExisting: Boolean = true,
    ): BackupImportResult {
        return runCatching {
            val root = JSONObject(payload)
            val version = root.optInt("version", -1)
            if (version != BackupExporter.BACKUP_VERSION) {
                return BackupImportResult(
                    success = false,
                    message = "Unsupported backup version: $version",
                    restoredAlarms = 0,
                    restoredTemplates = 0,
                )
            }

            if (replaceExisting) {
                clearExistingData()
            }

            val now = System.currentTimeMillis()
            val alarms = parseAlarms(root.optJSONArray("alarms"))
            val templates = parseTemplates(root.optJSONArray("templates"))
            val dailyStats = parseDailyStats(root.optJSONArray("dailyStats"))

            alarms.forEach { plan ->
                alarmRepository.upsert(plan)
                if (plan.enabled) {
                    val generation = ((plan.updatedAtUtcMillis / 1000L) % 100_000L).toInt()
                    val triggers = planner.planTriggers(plan, generation, now)
                    triggerRepository.replaceForAlarm(plan.alarmId, triggers)
                    alarmScheduler.scheduleAll(triggers)
                }
            }

            templates.forEach { templateRepository.upsert(it) }
            dailyStats.forEach { dailyAlarmStatsDao.upsert(it) }

            backupMetadataDao.upsert(
                BackupMetadataEntity(
                    id = 1,
                    lastExportAtUtcMillis = backupMetadataDao.get()?.lastExportAtUtcMillis,
                    lastImportAtUtcMillis = now,
                    lastVersion = version,
                ),
            )

            historyRepository.record(
                alarmId = 0,
                triggerId = "",
                eventType = "BACKUP_IMPORTED",
                meta = "replace=$replaceExisting alarms=${alarms.size} templates=${templates.size}",
            )

            BackupImportResult(
                success = true,
                message = "Restore completed",
                restoredAlarms = alarms.size,
                restoredTemplates = templates.size,
            )
        }.getOrElse { error ->
            BackupImportResult(
                success = false,
                message = "Restore failed: ${error.message ?: "unknown"}",
                restoredAlarms = 0,
                restoredTemplates = 0,
            )
        }
    }

    private suspend fun clearExistingData() {
        val alarms = alarmRepository.getAll()
        alarms.forEach { plan ->
            val existingTriggers = triggerRepository.getByAlarmId(plan.alarmId)
            alarmScheduler.cancelAllForAlarm(plan.alarmId, existingTriggers)
            triggerRepository.clearForAlarm(plan.alarmId)
            alarmRepository.delete(plan.alarmId)
        }
        templateRepository.clearAll()
        dailyAlarmStatsDao.clearAll()
    }

    private fun parseAlarms(array: JSONArray?): List<AlarmPlan> {
        if (array == null) return emptyList()
        return (0 until array.length()).mapNotNull { index ->
            val item = array.optJSONObject(index) ?: return@mapNotNull null
            item.toAlarmPlanOrNull()
        }
    }

    private fun parseTemplates(array: JSONArray?) =
        if (array == null) {
            emptyList()
        } else {
            (0 until array.length()).mapNotNull { index ->
                val item = array.optJSONObject(index) ?: return@mapNotNull null
                item.toTemplateOrNull()
            }
        }

    private fun parseDailyStats(array: JSONArray?) =
        if (array == null) {
            emptyList()
        } else {
            (0 until array.length()).mapNotNull { index ->
                val item = array.optJSONObject(index) ?: return@mapNotNull null
                DailyAlarmStatsEntity(
                    dayUtcStartMillis = item.optLong("dayUtcStartMillis", 0L),
                    fired = item.optInt("fired", 0),
                    dismissed = item.optInt("dismissed", 0),
                    snoozed = item.optInt("snoozed", 0),
                    missed = item.optInt("missed", 0),
                    repaired = item.optInt("repaired", 0),
                )
            }
        }

    private fun JSONObject.toAlarmPlanOrNull(): AlarmPlan? {
        val alarmId = optLong("alarmId", 0L)
        if (alarmId <= 0L) return null
        return AlarmPlan(
            alarmId = alarmId,
            title = optString("title", "Alarm"),
            hour24 = optInt("hour24", 6),
            minute = optInt("minute", 30),
            repeatDays = optStringArray("repeatDays"),
            enabled = optBoolean("enabled", true),
            sound = optString("sound", "Default Alarm"),
            challenge = optString("challenge", "None"),
            snoozeCount = optInt("snoozeCount", 3),
            snoozeDuration = optInt("snoozeDuration", 5),
            vibration = optBoolean("vibration", true),
            vibrationProfileId = optNullableString("vibrationProfileId"),
            escalationPolicy = optNullableString("escalationPolicy"),
            nagPolicy = optNullableString("nagPolicy"),
            primaryAction = optNullableString("primaryAction"),
            challengePolicy = optNullableString("challengePolicy"),
            anchorUtcMillis = if (has("anchorUtcMillis") && !isNull("anchorUtcMillis")) optLong("anchorUtcMillis") else null,
            timezoneId = optString("timezoneId", "UTC"),
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = optIntArray("preReminderMinutes"),
            recurrenceType = optNullableString("recurrenceType"),
            recurrenceInterval = if (has("recurrenceInterval") && !isNull("recurrenceInterval")) optInt("recurrenceInterval") else null,
            recurrenceWeekdays = optIntArray("recurrenceWeekdays"),
            recurrenceDayOfMonth = if (has("recurrenceDayOfMonth") && !isNull("recurrenceDayOfMonth")) optInt("recurrenceDayOfMonth") else null,
            recurrenceOrdinal = if (has("recurrenceOrdinal") && !isNull("recurrenceOrdinal")) optInt("recurrenceOrdinal") else null,
            recurrenceOrdinalWeekday = if (has("recurrenceOrdinalWeekday") && !isNull("recurrenceOrdinalWeekday")) optInt("recurrenceOrdinalWeekday") else null,
            recurrenceExclusionDates = optStringArray("recurrenceExclusionDates"),
            reminderOffsetsMinutes = optIntArray("reminderOffsetsMinutes"),
            reminderBeforeOnly = optBoolean("reminderBeforeOnly", false),
            createdAtUtcMillis = optLong("createdAtUtcMillis", System.currentTimeMillis()),
            updatedAtUtcMillis = optLong("updatedAtUtcMillis", System.currentTimeMillis()),
        )
    }

    private fun JSONObject.toTemplateOrNull(): com.example.alarmmaster.alarm.domain.AlarmTemplate? {
        val name = optString("name", "").trim()
        if (name.isEmpty()) return null
        return com.example.alarmmaster.alarm.domain.AlarmTemplate(
            templateId = optLong("templateId", 0L),
            name = name,
            title = optString("title", "Alarm"),
            hour24 = optInt("hour24", 6),
            minute = optInt("minute", 30),
            repeatDays = optStringArray("repeatDays"),
            sound = optString("sound", "Default Alarm"),
            vibration = optBoolean("vibration", true),
            vibrationProfileId = optNullableString("vibrationProfileId"),
            escalationPolicy = optNullableString("escalationPolicy"),
            nagPolicy = optNullableString("nagPolicy"),
            primaryAction = optNullableString("primaryAction"),
            challenge = optString("challenge", "None"),
            challengePolicy = optNullableString("challengePolicy"),
            snoozeCount = optInt("snoozeCount", 3),
            snoozeDuration = optInt("snoozeDuration", 5),
            recurrenceType = optNullableString("recurrenceType"),
            recurrenceInterval = if (has("recurrenceInterval") && !isNull("recurrenceInterval")) optInt("recurrenceInterval") else null,
            recurrenceWeekdays = optIntArray("recurrenceWeekdays"),
            recurrenceDayOfMonth = if (has("recurrenceDayOfMonth") && !isNull("recurrenceDayOfMonth")) optInt("recurrenceDayOfMonth") else null,
            recurrenceOrdinal = if (has("recurrenceOrdinal") && !isNull("recurrenceOrdinal")) optInt("recurrenceOrdinal") else null,
            recurrenceOrdinalWeekday = if (has("recurrenceOrdinalWeekday") && !isNull("recurrenceOrdinalWeekday")) optInt("recurrenceOrdinalWeekday") else null,
            recurrenceExclusionDates = optStringArray("recurrenceExclusionDates"),
            reminderOffsetsMinutes = optIntArray("reminderOffsetsMinutes"),
            reminderBeforeOnly = optBoolean("reminderBeforeOnly", false),
            timezonePolicy = optString("timezonePolicy", "FIXED_LOCAL_TIME"),
        )
    }

    private fun JSONObject.optNullableString(key: String): String? {
        if (!has(key) || isNull(key)) return null
        return optString(key).takeIf { it.isNotBlank() }
    }

    private fun JSONObject.optStringArray(key: String): List<String> {
        val array = optJSONArray(key) ?: return emptyList()
        return (0 until array.length()).mapNotNull { idx ->
            array.opt(idx)?.toString()
        }
    }

    private fun JSONObject.optIntArray(key: String): List<Int> {
        val array = optJSONArray(key) ?: return emptyList()
        return (0 until array.length()).mapNotNull { idx ->
            val raw = array.opt(idx) ?: return@mapNotNull null
            when (raw) {
                is Number -> raw.toInt()
                is String -> raw.toIntOrNull()
                else -> null
            }
        }
    }
}
