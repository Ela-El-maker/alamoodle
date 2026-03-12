package com.example.alarmmaster.alarm.domain

import java.time.DayOfWeek
import java.time.LocalDate

enum class RecurrenceType {
    NONE,
    DAILY,
    WEEKDAYS,
    CUSTOM_WEEKDAYS,
    WEEKLY_INTERVAL,
    MONTHLY_DAY_OF_MONTH,
    MONTHLY_ORDINAL_WEEKDAY,
}

data class RecurrenceException(
    val localDateIso: String,
) {
    fun asLocalDateOrNull(): LocalDate? = runCatching { LocalDate.parse(localDateIso) }.getOrNull()
}

data class RecurrenceRule(
    val type: RecurrenceType,
    val interval: Int = 1,
    val weekdays: Set<DayOfWeek> = emptySet(),
    val dayOfMonth: Int? = null,
    val ordinal: Int? = null,
    val ordinalWeekday: DayOfWeek? = null,
    val exclusions: Set<LocalDate> = emptySet(),
) {
    companion object {
        val NONE = RecurrenceRule(RecurrenceType.NONE)
    }
}
