package com.example.alarmmaster.alarm.diagnostics

import com.example.alarmmaster.alarm.data.dao.DailyAlarmStatsDao
import com.example.alarmmaster.alarm.data.entities.DailyAlarmStatsEntity
import com.example.alarmmaster.alarm.domain.StatsSummary
import com.example.alarmmaster.alarm.domain.StatsTrendPoint
import java.time.Instant
import java.time.ZoneOffset
import java.time.ZonedDateTime

class StatsAggregationService(
    private val dailyAlarmStatsDao: DailyAlarmStatsDao,
) {
    suspend fun recordHistoryEvent(eventType: String, occurredAtUtcMillis: Long) {
        val day = dayUtcStart(occurredAtUtcMillis)
        val existing = dailyAlarmStatsDao.getByDay(day)
            ?: DailyAlarmStatsEntity(
                dayUtcStartMillis = day,
                fired = 0,
                dismissed = 0,
                snoozed = 0,
                missed = 0,
                repaired = 0,
            )

        val updated = when {
            eventType == "FIRED" -> existing.copy(fired = existing.fired + 1)
            eventType == "DISMISSED" -> existing.copy(dismissed = existing.dismissed + 1)
            eventType == "SNOOZED" -> existing.copy(snoozed = existing.snoozed + 1)
            eventType == "MISSED" || eventType == "LATE_DEGRADED" -> existing.copy(missed = existing.missed + 1)
            eventType.startsWith("RESTORED_") || eventType.startsWith("REPAIR_") -> {
                existing.copy(repaired = existing.repaired + 1)
            }
            else -> existing
        }
        dailyAlarmStatsDao.upsert(updated)
    }

    suspend fun getSummary(range: String): StatsSummary {
        val (from, to) = rangeBounds(range)
        val rows = dailyAlarmStatsDao.getRange(from, to)
        val totalFired = rows.sumOf { it.fired }
        val totalDismissed = rows.sumOf { it.dismissed }
        val totalSnoozed = rows.sumOf { it.snoozed }
        val totalMissed = rows.sumOf { it.missed }
        val repaired = rows.sumOf { it.repaired }
        val dismissRate = if (totalFired == 0) 0.0 else totalDismissed.toDouble() / totalFired.toDouble()
        val snoozeRate = if (totalFired == 0) 0.0 else totalSnoozed.toDouble() / totalFired.toDouble()
        return StatsSummary(
            totalFired = totalFired,
            totalDismissed = totalDismissed,
            totalSnoozed = totalSnoozed,
            totalMissed = totalMissed,
            repairedCount = repaired,
            dismissRate = dismissRate,
            snoozeRate = snoozeRate,
            streakDays = calculateDismissStreak(rows),
        )
    }

    suspend fun getTrends(range: String): List<StatsTrendPoint> {
        val (from, to) = rangeBounds(range)
        return dailyAlarmStatsDao.getRange(from, to).map {
            StatsTrendPoint(
                dayUtcStartMillis = it.dayUtcStartMillis,
                fired = it.fired,
                dismissed = it.dismissed,
                snoozed = it.snoozed,
                missed = it.missed,
                repaired = it.repaired,
            )
        }
    }

    private fun calculateDismissStreak(rows: List<DailyAlarmStatsEntity>): Int {
        var streak = 0
        rows.sortedByDescending { it.dayUtcStartMillis }.forEach { row ->
            if (row.fired > 0 && row.dismissed >= row.fired) {
                streak += 1
            } else {
                return streak
            }
        }
        return streak
    }

    private fun rangeBounds(range: String): Pair<Long, Long> {
        val now = System.currentTimeMillis()
        val to = dayUtcStart(now)
        val days = when (range.lowercase()) {
            "week", "7d" -> 6L
            "month", "30d" -> 29L
            "90d" -> 89L
            else -> 29L
        }
        val from = dayUtcStart(now - days * MILLIS_PER_DAY)
        return from to to
    }

    private fun dayUtcStart(timeUtcMillis: Long): Long {
        val dayStart = Instant.ofEpochMilli(timeUtcMillis)
            .atZone(ZoneOffset.UTC)
            .toLocalDate()
            .atStartOfDay(ZoneOffset.UTC)
        return dayStart.toInstant().toEpochMilli()
    }

    companion object {
        private const val MILLIS_PER_DAY = 86_400_000L
    }
}
