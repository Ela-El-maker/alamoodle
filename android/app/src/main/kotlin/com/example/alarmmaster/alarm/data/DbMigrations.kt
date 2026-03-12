package com.example.alarmmaster.alarm.data

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

object DbMigrations {
    val MIGRATION_1_2: Migration = object : Migration(1, 2) {
        override fun migrate(db: SupportSQLiteDatabase) {
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN vibrationProfileId TEXT")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN escalationPolicy TEXT")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN nagPolicy TEXT")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN primaryAction TEXT")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN challengePolicy TEXT")
            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS daily_alarm_stats (
                    dayUtcStartMillis INTEGER NOT NULL PRIMARY KEY,
                    fired INTEGER NOT NULL,
                    dismissed INTEGER NOT NULL,
                    snoozed INTEGER NOT NULL,
                    missed INTEGER NOT NULL,
                    repaired INTEGER NOT NULL
                )
                """.trimIndent(),
            )
        }
    }

    val MIGRATION_2_3: Migration = object : Migration(2, 3) {
        override fun migrate(db: SupportSQLiteDatabase) {
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN recurrenceType TEXT")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN recurrenceInterval INTEGER")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN recurrenceWeekdaysCsv TEXT NOT NULL DEFAULT ''")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN recurrenceDayOfMonth INTEGER")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN recurrenceOrdinal INTEGER")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN recurrenceOrdinalWeekday INTEGER")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN recurrenceExclusionDatesCsv TEXT NOT NULL DEFAULT ''")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN reminderOffsetsMinutesCsv TEXT NOT NULL DEFAULT ''")
            db.execSQL("ALTER TABLE alarm_plans ADD COLUMN reminderBeforeOnly INTEGER NOT NULL DEFAULT 0")

            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS alarm_templates (
                    templateId INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    name TEXT NOT NULL,
                    title TEXT NOT NULL,
                    hour24 INTEGER NOT NULL,
                    minute INTEGER NOT NULL,
                    repeatDaysCsv TEXT NOT NULL,
                    sound TEXT NOT NULL,
                    vibration INTEGER NOT NULL,
                    vibrationProfileId TEXT,
                    escalationPolicy TEXT,
                    nagPolicy TEXT,
                    primaryAction TEXT,
                    challenge TEXT NOT NULL,
                    challengePolicy TEXT,
                    snoozeCount INTEGER NOT NULL,
                    snoozeDuration INTEGER NOT NULL,
                    recurrenceType TEXT,
                    recurrenceInterval INTEGER,
                    recurrenceWeekdaysCsv TEXT NOT NULL,
                    recurrenceDayOfMonth INTEGER,
                    recurrenceOrdinal INTEGER,
                    recurrenceOrdinalWeekday INTEGER,
                    recurrenceExclusionDatesCsv TEXT NOT NULL,
                    reminderOffsetsMinutesCsv TEXT NOT NULL,
                    reminderBeforeOnly INTEGER NOT NULL,
                    timezonePolicy TEXT NOT NULL
                )
                """.trimIndent(),
            )

            db.execSQL(
                """
                CREATE TABLE IF NOT EXISTS backup_metadata (
                    id INTEGER NOT NULL PRIMARY KEY,
                    lastExportAtUtcMillis INTEGER,
                    lastImportAtUtcMillis INTEGER,
                    lastVersion INTEGER NOT NULL
                )
                """.trimIndent(),
            )
        }
    }
}
