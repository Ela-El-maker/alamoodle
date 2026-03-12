package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.AlarmHistoryEntity

@Dao
interface AlarmHistoryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: AlarmHistoryEntity)

    @Query("SELECT * FROM alarm_history WHERE alarmId = :alarmId ORDER BY occurredAtUtcMillis DESC")
    suspend fun getByAlarmId(alarmId: Long): List<AlarmHistoryEntity>

    @Query("SELECT * FROM alarm_history ORDER BY occurredAtUtcMillis DESC LIMIT :limit")
    suspend fun getRecent(limit: Int): List<AlarmHistoryEntity>

    @Query(
        "SELECT * FROM alarm_history WHERE alarmId = :alarmId ORDER BY occurredAtUtcMillis DESC LIMIT :limit",
    )
    suspend fun getRecentByAlarmId(alarmId: Long, limit: Int): List<AlarmHistoryEntity>

    @Query("DELETE FROM alarm_history")
    suspend fun clearAll()
}
