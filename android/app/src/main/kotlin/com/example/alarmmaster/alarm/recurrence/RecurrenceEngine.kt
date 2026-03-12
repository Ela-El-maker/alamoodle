package com.example.alarmmaster.alarm.recurrence

import com.example.alarmmaster.alarm.domain.RecurrenceRule
import java.time.ZonedDateTime

interface RecurrenceEngine {
    fun nextOccurrences(
        rule: RecurrenceRule,
        anchor: ZonedDateTime,
        now: ZonedDateTime,
        limit: Int,
    ): List<ZonedDateTime>
}
