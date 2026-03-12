package com.example.alarmmaster.alarm.recurrence

import com.example.alarmmaster.alarm.domain.RecurrenceRule
import java.time.ZonedDateTime

/**
 * Sprint 5 sealed seam for future C++ recurrence compute integration.
 * Production lane remains Kotlin-first in this sprint.
 */
class NativeRecurrenceEngineAdapter(
    private val fallback: RecurrenceEngine = KotlinRecurrenceEngine(),
) : RecurrenceEngine {
    override fun nextOccurrences(
        rule: RecurrenceRule,
        anchor: ZonedDateTime,
        now: ZonedDateTime,
        limit: Int,
    ): List<ZonedDateTime> {
        // No JNI dependency in Sprint 5; delegate to Kotlin implementation.
        return fallback.nextOccurrences(rule, anchor, now, limit)
    }
}
