package com.example.alarmmaster.alarm.recurrence

import com.example.alarmmaster.alarm.domain.RecurrenceRule
import com.example.alarmmaster.alarm.domain.RecurrenceType
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.YearMonth
import java.time.ZonedDateTime
import java.time.temporal.TemporalAdjusters

class KotlinRecurrenceEngine : RecurrenceEngine {
    override fun nextOccurrences(
        rule: RecurrenceRule,
        anchor: ZonedDateTime,
        now: ZonedDateTime,
        limit: Int,
    ): List<ZonedDateTime> {
        if (limit <= 0) return emptyList()
        return when (rule.type) {
            RecurrenceType.NONE -> {
                val candidate = normalizeForDst(anchor)
                if (candidate.isAfter(now) && !isExcluded(rule, candidate.toLocalDate())) {
                    listOf(candidate)
                } else {
                    emptyList()
                }
            }
            RecurrenceType.DAILY -> iterateByDate(rule, anchor, now, limit) { it.plusDays(rule.interval.coerceAtLeast(1).toLong()) }
            RecurrenceType.WEEKDAYS -> iterateByDate(rule, anchor, now, limit) { it.plusDays(1) }
                .filter { it.dayOfWeek in WEEKDAYS }
                .take(limit)
            RecurrenceType.CUSTOM_WEEKDAYS -> {
                val weekdays = if (rule.weekdays.isEmpty()) WEEKDAYS else rule.weekdays
                iterateByDate(rule, anchor, now, limit * 3) { it.plusDays(1) }
                    .filter { it.dayOfWeek in weekdays }
                    .take(limit)
            }
            RecurrenceType.WEEKLY_INTERVAL -> {
                val step = rule.interval.coerceAtLeast(1).toLong()
                iterateByDate(rule, anchor, now, limit) { it.plusWeeks(step) }
            }
            RecurrenceType.MONTHLY_DAY_OF_MONTH -> iterateMonthlyByDay(rule, anchor, now, limit)
            RecurrenceType.MONTHLY_ORDINAL_WEEKDAY -> iterateMonthlyByOrdinalWeekday(rule, anchor, now, limit)
        }
    }

    private fun iterateByDate(
        rule: RecurrenceRule,
        anchor: ZonedDateTime,
        now: ZonedDateTime,
        limit: Int,
        increment: (ZonedDateTime) -> ZonedDateTime,
    ): List<ZonedDateTime> {
        val results = mutableListOf<ZonedDateTime>()
        var cursor = anchor
        var attempts = 0
        val maxAttempts = limit * 20
        while (results.size < limit && attempts < maxAttempts) {
            val normalized = normalizeForDst(cursor)
            val localDate = normalized.toLocalDate()
            if (normalized.isAfter(now) && !isExcluded(rule, localDate)) {
                results += normalized
            }
            cursor = increment(cursor)
            attempts += 1
        }
        return results
    }

    private fun iterateMonthlyByDay(
        rule: RecurrenceRule,
        anchor: ZonedDateTime,
        now: ZonedDateTime,
        limit: Int,
    ): List<ZonedDateTime> {
        val targetDay = (rule.dayOfMonth ?: anchor.dayOfMonth).coerceIn(1, 31)
        val step = rule.interval.coerceAtLeast(1).toLong()
        val results = mutableListOf<ZonedDateTime>()
        var cursorMonth = YearMonth.from(anchor)
        var attempts = 0
        val maxAttempts = limit * 24
        while (results.size < limit && attempts < maxAttempts) {
            val clampedDay = targetDay.coerceAtMost(cursorMonth.lengthOfMonth())
            val local = LocalDateTime.of(
                cursorMonth.year,
                cursorMonth.month,
                clampedDay,
                anchor.hour,
                anchor.minute,
                anchor.second,
                anchor.nano,
            )
            val candidate = normalizeForDst(ZonedDateTime.of(local, anchor.zone))
            if (candidate.isAfter(now) && !isExcluded(rule, candidate.toLocalDate())) {
                results += candidate
            }
            cursorMonth = cursorMonth.plusMonths(step)
            attempts += 1
        }
        return results
    }

    private fun iterateMonthlyByOrdinalWeekday(
        rule: RecurrenceRule,
        anchor: ZonedDateTime,
        now: ZonedDateTime,
        limit: Int,
    ): List<ZonedDateTime> {
        val step = rule.interval.coerceAtLeast(1).toLong()
        val ordinal = rule.ordinal ?: 1
        val weekday = rule.ordinalWeekday ?: anchor.dayOfWeek
        val results = mutableListOf<ZonedDateTime>()
        var cursorMonth = YearMonth.from(anchor)
        var attempts = 0
        val maxAttempts = limit * 24
        while (results.size < limit && attempts < maxAttempts) {
            val monthStart = cursorMonth.atDay(1)
            val date = if (ordinal < 0) {
                monthStart.with(TemporalAdjusters.lastInMonth(weekday))
            } else {
                monthStart.with(TemporalAdjusters.dayOfWeekInMonth(ordinal, weekday))
            }
            val local = date.atTime(anchor.hour, anchor.minute, anchor.second, anchor.nano)
            val candidate = normalizeForDst(ZonedDateTime.of(local, anchor.zone))
            if (candidate.isAfter(now) && !isExcluded(rule, candidate.toLocalDate())) {
                results += candidate
            }
            cursorMonth = cursorMonth.plusMonths(step)
            attempts += 1
        }
        return results
    }

    private fun normalizeForDst(candidate: ZonedDateTime): ZonedDateTime {
        val zone = candidate.zone
        val local = candidate.toLocalDateTime()
        val offsets = zone.rules.getValidOffsets(local)
        return when {
            offsets.size == 1 -> ZonedDateTime.ofLocal(local, zone, offsets[0])
            offsets.size > 1 -> ZonedDateTime.ofLocal(local, zone, offsets.first())
            else -> {
                val afterGap = zone.rules.getTransition(local)?.dateTimeAfter ?: local.plusMinutes(1)
                ZonedDateTime.of(afterGap, zone)
            }
        }
    }

    private fun isExcluded(rule: RecurrenceRule, date: LocalDate): Boolean {
        return date in rule.exclusions
    }

    private companion object {
        val WEEKDAYS: Set<DayOfWeek> = setOf(
            DayOfWeek.MONDAY,
            DayOfWeek.TUESDAY,
            DayOfWeek.WEDNESDAY,
            DayOfWeek.THURSDAY,
            DayOfWeek.FRIDAY,
        )
    }
}
