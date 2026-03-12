package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.RecurrenceException
import com.example.alarmmaster.alarm.domain.RecurrenceRule
import com.example.alarmmaster.alarm.domain.RecurrenceType
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import com.example.alarmmaster.alarm.recurrence.RecurrenceEngine
import java.time.DayOfWeek
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

class AlarmPlanner(
    private val triggerIdFactory: TriggerIdFactory,
    private val recurrenceEngine: RecurrenceEngine,
    private val reminderBundlePlanner: ReminderBundlePlanner = ReminderBundlePlanner(),
) {
    fun planTriggers(
        plan: AlarmPlan,
        generation: Int,
        nowUtcMillis: Long = System.currentTimeMillis(),
    ): List<TriggerInstance> {
        val zone = resolveZone(plan.timezoneId)
        val now = Instant.ofEpochMilli(nowUtcMillis).atZone(zone)
        val mainCandidates = computeMainCandidates(plan, now)

        val results = mutableListOf<TriggerInstance>()
        var mainIndex = 0
        var preIndex = 0
        val reminderOffsets = if (plan.reminderOffsetsMinutes.isNotEmpty()) {
            plan.reminderOffsetsMinutes
        } else {
            plan.preReminderMinutes
        }
        val includeMain = !plan.reminderBeforeOnly || reminderOffsets.isEmpty()

        for (main in mainCandidates) {
            val mainMillis = main.toInstant().toEpochMilli()
            if (mainMillis <= nowUtcMillis) continue
            if (includeMain) {
                results += buildTrigger(
                    alarmId = plan.alarmId,
                    kind = TriggerKind.MAIN,
                    index = mainIndex++,
                    generation = generation,
                    scheduled = main,
                )
            }

            for (preTime in reminderBundlePlanner.planPreReminderTimes(main, reminderOffsets, nowUtcMillis)) {
                results += buildTrigger(
                    alarmId = plan.alarmId,
                    kind = TriggerKind.PRE,
                    index = preIndex++,
                    generation = generation,
                    scheduled = preTime,
                )
            }
        }

        return results.sortedBy { it.scheduledUtcMillis }
    }

    private fun computeMainCandidates(plan: AlarmPlan, now: ZonedDateTime): List<ZonedDateTime> {
        val recurrenceRule = toRecurrenceRule(plan)
        val anchor = resolveAnchor(plan, now)
        return recurrenceEngine.nextOccurrences(
            rule = recurrenceRule,
            anchor = anchor,
            now = now,
            limit = 14,
        )
    }

    private fun resolveAnchor(plan: AlarmPlan, now: ZonedDateTime): ZonedDateTime {
        val anchored = plan.anchorUtcMillis?.let { anchorUtc ->
            Instant.ofEpochMilli(anchorUtc).atZone(now.zone)
                .withHour(plan.hour24)
                .withMinute(plan.minute)
                .withSecond(0)
                .withNano(0)
        }
        if (anchored != null) return anchored
        val baseToday = now.withHour(plan.hour24).withMinute(plan.minute).withSecond(0).withNano(0)
        return if (baseToday.isAfter(now)) baseToday else baseToday.plusDays(1)
    }

    private fun toRecurrenceRule(plan: AlarmPlan): RecurrenceRule {
        val type = parseRecurrenceType(plan.recurrenceType)
        val selectedType = if (type != RecurrenceType.NONE) type else legacyRecurrenceType(plan.repeatDays)
        val weekdays = when {
            plan.recurrenceWeekdays.isNotEmpty() -> plan.recurrenceWeekdays
                .mapNotNull { index -> runCatching { DayOfWeek.of(index.coerceIn(1, 7)) }.getOrNull() }
                .toSet()
            selectedType == RecurrenceType.CUSTOM_WEEKDAYS -> normalizeDays(plan.repeatDays).toSet()
            selectedType == RecurrenceType.WEEKDAYS -> setOf(
                DayOfWeek.MONDAY,
                DayOfWeek.TUESDAY,
                DayOfWeek.WEDNESDAY,
                DayOfWeek.THURSDAY,
                DayOfWeek.FRIDAY,
            )
            else -> emptySet()
        }
        val exclusions = plan.recurrenceExclusionDates
            .mapNotNull { RecurrenceException(it).asLocalDateOrNull() }
            .toSet()

        return RecurrenceRule(
            type = selectedType,
            interval = (plan.recurrenceInterval ?: 1).coerceAtLeast(1),
            weekdays = weekdays,
            dayOfMonth = plan.recurrenceDayOfMonth,
            ordinal = plan.recurrenceOrdinal,
            ordinalWeekday = plan.recurrenceOrdinalWeekday?.let { value ->
                runCatching { DayOfWeek.of(value.coerceIn(1, 7)) }.getOrNull()
            },
            exclusions = exclusions,
        )
    }

    private fun parseRecurrenceType(value: String?): RecurrenceType {
        if (value.isNullOrBlank()) return RecurrenceType.NONE
        return runCatching { RecurrenceType.valueOf(value.trim().uppercase()) }.getOrDefault(RecurrenceType.NONE)
    }

    private fun legacyRecurrenceType(days: List<String>): RecurrenceType {
        val normalized = normalizeDays(days)
        if (normalized.isEmpty()) return RecurrenceType.NONE
        if (normalized.size == 7) return RecurrenceType.DAILY
        if (normalized.containsAll(
                listOf(
                    DayOfWeek.MONDAY,
                    DayOfWeek.TUESDAY,
                    DayOfWeek.WEDNESDAY,
                    DayOfWeek.THURSDAY,
                    DayOfWeek.FRIDAY,
                ),
            ) && normalized.size == 5
        ) {
            return RecurrenceType.WEEKDAYS
        }
        return RecurrenceType.CUSTOM_WEEKDAYS
    }

    private fun normalizeDays(days: List<String>): List<DayOfWeek> {
        if (days.any { it.equals("Daily", ignoreCase = true) }) {
            return DayOfWeek.values().toList()
        }

        val map = mapOf(
            "Mon" to DayOfWeek.MONDAY,
            "Tue" to DayOfWeek.TUESDAY,
            "Wed" to DayOfWeek.WEDNESDAY,
            "Thu" to DayOfWeek.THURSDAY,
            "Fri" to DayOfWeek.FRIDAY,
            "Sat" to DayOfWeek.SATURDAY,
            "Sun" to DayOfWeek.SUNDAY,
        )
        return days.mapNotNull { map[it] }
    }

    private fun resolveZone(timezoneId: String): ZoneId {
        return try {
            ZoneId.of(timezoneId)
        } catch (_: Exception) {
            ZoneId.systemDefault()
        }
    }

    private fun buildTrigger(
        alarmId: Long,
        kind: TriggerKind,
        index: Int,
        generation: Int,
        scheduled: ZonedDateTime,
    ): TriggerInstance {
        val utcMillis = scheduled.toInstant().toEpochMilli()
        return TriggerInstance(
            triggerId = triggerIdFactory.buildTriggerId(alarmId, kind, index, generation, utcMillis),
            alarmId = alarmId,
            kind = kind,
            scheduledLocalIso = scheduled.toLocalDateTime().toString(),
            scheduledUtcMillis = utcMillis,
            requestCode = triggerIdFactory.buildRequestCode(alarmId, kind, index, generation),
            status = TriggerStatus.SCHEDULED,
            generation = generation,
        )
    }
}
