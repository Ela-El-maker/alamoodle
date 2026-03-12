package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.AlarmPlanEntity

@Dao
interface AlarmPlanDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: AlarmPlanEntity)

    @Query("DELETE FROM alarm_plans WHERE alarmId = :alarmId")
    suspend fun deleteById(alarmId: Long)

    @Query("SELECT * FROM alarm_plans ORDER BY hour24 ASC, minute ASC, alarmId ASC")
    suspend fun getAllOrdered(): List<AlarmPlanEntity>

    @Query("SELECT * FROM alarm_plans WHERE alarmId = :alarmId LIMIT 1")
    suspend fun getById(alarmId: Long): AlarmPlanEntity?

    @Query("DELETE FROM alarm_plans")
    suspend fun clearAll()
}
