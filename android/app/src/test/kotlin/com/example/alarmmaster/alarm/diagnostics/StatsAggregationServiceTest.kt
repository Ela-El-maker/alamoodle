package com.example.alarmmaster.alarm.diagnostics

import com.example.alarmmaster.alarm.data.dao.DailyAlarmStatsDao
import com.example.alarmmaster.alarm.data.entities.DailyAlarmStatsEntity
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class StatsAggregationServiceTest {
    @Test
    fun recordEvents_updatesMaterializedCounters() = runBlocking {
        val dao = InMemoryDailyAlarmStatsDao()
        val service = StatsAggregationService(dao)
        val now = System.currentTimeMillis()

        service.recordHistoryEvent("FIRED", now)
        service.recordHistoryEvent("DISMISSED", now)
        service.recordHistoryEvent("SNOOZED", now)
        service.recordHistoryEvent("MISSED", now)
        service.recordHistoryEvent("RESTORED_AFTER_BOOT", now)

        val summary = service.getSummary("7d")

        assertEquals(1, summary.totalFired)
        assertEquals(1, summary.totalDismissed)
        assertEquals(1, summary.totalSnoozed)
        assertEquals(1, summary.totalMissed)
        assertEquals(1, summary.repairedCount)
        assertTrue(summary.dismissRate > 0.0)
    }

    @Test
    fun trends_returnsOrderedDayRows() = runBlocking {
        val dao = InMemoryDailyAlarmStatsDao()
        val service = StatsAggregationService(dao)
        val now = System.currentTimeMillis()
        val day = 86_400_000L

        service.recordHistoryEvent("FIRED", now - day)
        service.recordHistoryEvent("DISMISSED", now - day)
        service.recordHistoryEvent("FIRED", now)

        val trends = service.getTrends("7d")

        assertTrue(trends.size >= 2)
        assertTrue(trends[0].dayUtcStartMillis <= trends.last().dayUtcStartMillis)
    }

    private class InMemoryDailyAlarmStatsDao : DailyAlarmStatsDao {
        private val store = linkedMapOf<Long, DailyAlarmStatsEntity>()

        override suspend fun upsert(entity: DailyAlarmStatsEntity) {
            store[entity.dayUtcStartMillis] = entity
        }

        override suspend fun getByDay(dayUtcStartMillis: Long): DailyAlarmStatsEntity? {
            return store[dayUtcStartMillis]
        }

        override suspend fun getRange(
            fromUtcMillis: Long,
            toUtcMillis: Long,
        ): List<DailyAlarmStatsEntity> {
            return store.values
                .filter { it.dayUtcStartMillis in fromUtcMillis..toUtcMillis }
                .sortedBy { it.dayUtcStartMillis }
        }

        override suspend fun getAll(): List<DailyAlarmStatsEntity> {
            return store.values.sortedBy { it.dayUtcStartMillis }
        }

        override suspend fun clearAll() {
            store.clear()
        }
    }
}
