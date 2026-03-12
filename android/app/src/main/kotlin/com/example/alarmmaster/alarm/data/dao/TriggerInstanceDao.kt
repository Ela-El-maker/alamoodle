package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.TriggerInstanceEntity

@Dao
interface TriggerInstanceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: TriggerInstanceEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(entities: List<TriggerInstanceEntity>)

    @Query("SELECT * FROM trigger_instances WHERE alarmId = :alarmId ORDER BY scheduledUtcMillis ASC")
    suspend fun getByAlarmId(alarmId: Long): List<TriggerInstanceEntity>

    @Query("SELECT * FROM trigger_instances WHERE triggerId = :triggerId LIMIT 1")
    suspend fun getByTriggerId(triggerId: String): TriggerInstanceEntity?

    @Query("DELETE FROM trigger_instances WHERE alarmId = :alarmId")
    suspend fun deleteByAlarmId(alarmId: Long)

    @Query("UPDATE trigger_instances SET status = :status WHERE triggerId = :triggerId")
    suspend fun updateStatus(triggerId: String, status: String)

    @Query("SELECT * FROM trigger_instances WHERE scheduledUtcMillis >= :fromUtcMillis ORDER BY scheduledUtcMillis ASC")
    suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstanceEntity>

    @Query("DELETE FROM trigger_instances")
    suspend fun clearAll()
}
