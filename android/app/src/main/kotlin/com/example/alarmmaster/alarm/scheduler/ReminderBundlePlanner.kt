package com.example.alarmmaster.alarm.scheduler

import java.time.ZonedDateTime

class ReminderBundlePlanner {
    fun normalizedOffsets(offsetsMinutes: List<Int>): List<Int> {
        return offsetsMinutes
            .map { it.coerceAtLeast(0) }
            .filter { it > 0 }
            .distinct()
            .sortedDescending()
    }

    fun planPreReminderTimes(
        mainTime: ZonedDateTime,
        offsetsMinutes: List<Int>,
        nowUtcMillis: Long,
    ): List<ZonedDateTime> {
        return normalizedOffsets(offsetsMinutes)
            .map { mainTime.minusMinutes(it.toLong()) }
            .filter { it.toInstant().toEpochMilli() > nowUtcMillis }
            .distinctBy { it.toInstant().toEpochMilli() }
            .sortedBy { it.toInstant().toEpochMilli() }
    }
}
