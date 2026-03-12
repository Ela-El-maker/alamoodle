package com.example.alarmmaster.alarm.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.alarmmaster.alarm.data.entities.BackupMetadataEntity

@Dao
interface BackupMetadataDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: BackupMetadataEntity)

    @Query("SELECT * FROM backup_metadata WHERE id = 1 LIMIT 1")
    suspend fun get(): BackupMetadataEntity?
}
