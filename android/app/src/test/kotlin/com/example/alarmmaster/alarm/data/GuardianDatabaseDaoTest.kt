package com.example.alarmmaster.alarm.data

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.alarmmaster.alarm.data.entities.AlarmHistoryEntity
import com.example.alarmmaster.alarm.data.entities.AlarmPlanEntity
import com.example.alarmmaster.alarm.data.entities.TriggerInstanceEntity
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class GuardianDatabaseDaoTest {
    private lateinit var db: GuardianDatabase

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        db = Room.inMemoryDatabaseBuilder(context, GuardianDatabase::class.java)
            .allowMainThreadQueries()
            .build()
    }

    @After
    fun tearDown() {
        db.close()
    }

    @Test
    fun alarmPlanDao_createUpdateDelete_roundTrips() = runBlocking {
        val initial = AlarmPlanEntity(
            alarmId = 10L,
            title = "Morning",
            hour24 = 6,
            minute = 30,
            repeatDaysCsv = "Mon,Tue",
            enabled = true,
            sound = "Default Alarm",
            challenge = "None",
            snoozeCount = 3,
            snoozeDuration = 5,
            vibration = true,
            anchorUtcMillis = null,
            timezoneId = "UTC",
            timezonePolicy = "FIXED_LOCAL_TIME",
            preReminderMinutesCsv = "60,1440",
            createdAtUtcMillis = 1_000L,
            updatedAtUtcMillis = 1_000L,
        )
        db.alarmPlanDao().upsert(initial)
        assertNotNull(db.alarmPlanDao().getById(10L))

        val updated = initial.copy(title = "Morning Updated", enabled = false, updatedAtUtcMillis = 2_000L)
        db.alarmPlanDao().upsert(updated)
        val stored = db.alarmPlanDao().getById(10L)
        assertEquals("Morning Updated", stored?.title)
        assertEquals(false, stored?.enabled)

        db.alarmPlanDao().deleteById(10L)
        assertNull(db.alarmPlanDao().getById(10L))
    }

    @Test
    fun triggerDao_insertsAndQueriesFuture_onlyFutureReturned() = runBlocking {
        val now = 1_000_000L
        val oldTrigger = TriggerInstanceEntity(
            triggerId = "old",
            alarmId = 77L,
            kind = "PRE",
            scheduledLocalIso = "2026-03-01T09:00",
            scheduledUtcMillis = now - 1_000L,
            requestCode = 7001,
            status = "SCHEDULED",
            generation = 1,
        )
        val futureTrigger = oldTrigger.copy(
            triggerId = "future",
            kind = "MAIN",
            scheduledLocalIso = "2026-03-01T10:00",
            scheduledUtcMillis = now + 5_000L,
            requestCode = 7002,
        )
        db.triggerInstanceDao().upsertAll(listOf(oldTrigger, futureTrigger))

        val future = db.triggerInstanceDao().getFuture(now)
        assertEquals(1, future.size)
        assertEquals("future", future.first().triggerId)
    }

    @Test
    fun historyDao_insertsAndQueriesByAlarm_descendingByOccurredTime() = runBlocking {
        val first = AlarmHistoryEntity(
            alarmId = 8L,
            triggerId = "t-1",
            eventType = "CREATED",
            occurredAtUtcMillis = 10L,
            meta = "",
        )
        val second = first.copy(
            historyId = 0L,
            triggerId = "t-2",
            eventType = "UPDATED",
            occurredAtUtcMillis = 20L,
        )
        db.alarmHistoryDao().insert(first)
        db.alarmHistoryDao().insert(second)

        val events = db.alarmHistoryDao().getByAlarmId(8L)
        assertEquals(2, events.size)
        assertEquals("UPDATED", events.first().eventType)
        assertEquals("CREATED", events.last().eventType)
    }
}
