package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.DailyAlarmStatsEntity

@Dao
interface DailyAlarmStatsDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: DailyAlarmStatsEntity)

    @Query(
        "SELECT * FROM daily_alarm_stats WHERE dayUtcStartMillis = :dayUtcStartMillis LIMIT 1",
    )
    suspend fun getByDay(dayUtcStartMillis: Long): DailyAlarmStatsEntity?

    @Query(
        "SELECT * FROM daily_alarm_stats WHERE dayUtcStartMillis >= :fromUtcMillis AND dayUtcStartMillis <= :toUtcMillis ORDER BY dayUtcStartMillis ASC",
    )
    suspend fun getRange(fromUtcMillis: Long, toUtcMillis: Long): List<DailyAlarmStatsEntity>

    @Query("SELECT * FROM daily_alarm_stats ORDER BY dayUtcStartMillis ASC")
    suspend fun getAll(): List<DailyAlarmStatsEntity>

    @Query("DELETE FROM daily_alarm_stats")
    suspend fun clearAll()
}
