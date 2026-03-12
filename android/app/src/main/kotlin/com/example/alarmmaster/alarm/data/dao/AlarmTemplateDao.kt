package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.AlarmTemplateEntity

@Dao
interface AlarmTemplateDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: AlarmTemplateEntity): Long

    @Query("SELECT * FROM alarm_templates ORDER BY name ASC")
    suspend fun getAll(): List<AlarmTemplateEntity>

    @Query("SELECT * FROM alarm_templates WHERE templateId = :templateId LIMIT 1")
    suspend fun getById(templateId: Long): AlarmTemplateEntity?

    @Query("DELETE FROM alarm_templates WHERE templateId = :templateId")
    suspend fun deleteById(templateId: Long)

    @Query("DELETE FROM alarm_templates")
    suspend fun clearAll()
}
