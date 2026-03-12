package com.example.alarmmaster.alarm.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.alarmmaster.alarm.data.entities.AlarmPlanEntity
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class GuardianDatabaseBaselineTest {
    @Test
    fun schemaV1_openAndRoundTripData() {
        runBlocking {
            val context = ApplicationProvider.getApplicationContext<Context>()
            val dbName = "guardian_db_v1_baseline_test.db"
            context.deleteDatabase(dbName)

            val db = Room.databaseBuilder(context, GuardianDatabase::class.java, dbName)
                .allowMainThreadQueries()
                .build()
            try {
                db.alarmPlanDao().upsert(
                    AlarmPlanEntity(
                        alarmId = 300L,
                        title = "Baseline",
                        hour24 = 9,
                        minute = 45,
                        repeatDaysCsv = "",
                        enabled = true,
                        sound = "Default Alarm",
                        challenge = "None",
                        snoozeCount = 3,
                        snoozeDuration = 5,
                        vibration = true,
                        anchorUtcMillis = 1_776_590_700_000L,
                        timezoneId = "UTC",
                        timezonePolicy = "FIXED_LOCAL_TIME",
                        preReminderMinutesCsv = "60",
                        createdAtUtcMillis = 100L,
                        updatedAtUtcMillis = 100L,
                    ),
                )
            } finally {
                db.close()
            }

            val reopened = Room.databaseBuilder(context, GuardianDatabase::class.java, dbName)
                .allowMainThreadQueries()
                .build()
            try {
                val plan = reopened.alarmPlanDao().getById(300L)
                assertEquals("Baseline", plan?.title)
                assertEquals(1_776_590_700_000L, plan?.anchorUtcMillis)
            } finally {
                reopened.close()
            }

            context.deleteDatabase(dbName)
        }
    }
}
