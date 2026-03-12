package com.example.alarmmaster.alarm.data.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "backup_metadata")
data class BackupMetadataEntity(
    @PrimaryKey val id: Int = 1,
    val lastExportAtUtcMillis: Long? = null,
    val lastImportAtUtcMillis: Long? = null,
    val lastVersion: Int = 1,
)
