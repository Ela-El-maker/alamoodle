package com.example.alarmmaster.alarm.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.alarmmaster.alarm.data.dao.AlarmHistoryDao
import com.example.alarmmaster.alarm.data.dao.AlarmPlanDao
import com.example.alarmmaster.alarm.data.dao.AlarmTemplateDao
import com.example.alarmmaster.alarm.data.dao.BackupMetadataDao
import com.example.alarmmaster.alarm.data.dao.DailyAlarmStatsDao
import com.example.alarmmaster.alarm.data.dao.RingSessionDao
import com.example.alarmmaster.alarm.data.dao.ScheduleRegistryDao
import com.example.alarmmaster.alarm.data.dao.TriggerInstanceDao
import com.example.alarmmaster.alarm.data.entities.AlarmHistoryEntity
import com.example.alarmmaster.alarm.data.entities.AlarmPlanEntity
import com.example.alarmmaster.alarm.data.entities.AlarmTemplateEntity
import com.example.alarmmaster.alarm.data.entities.BackupMetadataEntity
import com.example.alarmmaster.alarm.data.entities.DailyAlarmStatsEntity
import com.example.alarmmaster.alarm.data.entities.RingSessionEntity
import com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity
import com.example.alarmmaster.alarm.data.entities.TriggerInstanceEntity

@Database(
    entities = [
        AlarmPlanEntity::class,
        TriggerInstanceEntity::class,
        AlarmHistoryEntity::class,
        RingSessionEntity::class,
        ScheduleRegistryEntity::class,
        DailyAlarmStatsEntity::class,
        AlarmTemplateEntity::class,
        BackupMetadataEntity::class,
    ],
    version = 3,
    exportSchema = false,
)
abstract class GuardianDatabase : RoomDatabase() {
    abstract fun alarmPlanDao(): AlarmPlanDao
    abstract fun triggerInstanceDao(): TriggerInstanceDao
    abstract fun alarmHistoryDao(): AlarmHistoryDao
    abstract fun ringSessionDao(): RingSessionDao
    abstract fun scheduleRegistryDao(): ScheduleRegistryDao
    abstract fun dailyAlarmStatsDao(): DailyAlarmStatsDao
    abstract fun alarmTemplateDao(): AlarmTemplateDao
    abstract fun backupMetadataDao(): BackupMetadataDao

    companion object {
        @Volatile
        private var INSTANCE: GuardianDatabase? = null

        fun getInstance(context: Context): GuardianDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    GuardianDatabase::class.java,
                    "guardian_alarm.db",
                )
                    .addMigrations(DbMigrations.MIGRATION_1_2)
                    .addMigrations(DbMigrations.MIGRATION_2_3)
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
