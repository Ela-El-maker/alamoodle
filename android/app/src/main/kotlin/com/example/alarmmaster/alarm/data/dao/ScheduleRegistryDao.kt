package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity

@Dao
interface ScheduleRegistryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: ScheduleRegistryEntity)

    @Query("DELETE FROM schedule_registry WHERE alarmId = :alarmId")
    suspend fun deleteByAlarmId(alarmId: Long)

    @Query("SELECT * FROM schedule_registry WHERE active = 1")
    suspend fun getActive(): List<ScheduleRegistryEntity>

    @Query("SELECT * FROM schedule_registry WHERE active = 1 AND triggerId = :triggerId LIMIT 1")
    suspend fun getActiveByTriggerId(triggerId: String): ScheduleRegistryEntity?

    @Query("DELETE FROM schedule_registry WHERE triggerId = :triggerId")
    suspend fun deleteByTriggerId(triggerId: String)

    @Query("DELETE FROM schedule_registry")
    suspend fun clearAll()

    @Query("UPDATE schedule_registry SET active = :active WHERE triggerId = :triggerId")
    suspend fun setActive(triggerId: String, active: Boolean)
}
