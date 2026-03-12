package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.recurrence.KotlinRecurrenceEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime

class AlarmPlannerTest {
    private val planner = AlarmPlanner(TriggerIdFactory(), KotlinRecurrenceEngine())

    @Test
    fun plansMainAndPreReminders_forFutureEventScenario() {
        val plan = AlarmPlan(
            alarmId = 100,
            title = "Doctor",
            hour24 = 15,
            minute = 0,
            repeatDays = emptyList(),
            enabled = true,
            sound = "Default Alarm",
            challenge = "None",
            snoozeCount = 3,
            snoozeDuration = 5,
            vibration = true,
            anchorUtcMillis = java.time.ZonedDateTime.of(2026, 4, 20, 15, 0, 0, 0, java.time.ZoneId.of("UTC"))
                .toInstant().toEpochMilli(),
            timezoneId = "UTC",
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = listOf(10080, 1440, 60),
            createdAtUtcMillis = 0,
            updatedAtUtcMillis = 0,
        )

        val now = java.time.ZonedDateTime.of(2026, 4, 1, 12, 0, 0, 0, java.time.ZoneId.of("UTC"))
            .toInstant().toEpochMilli()

        val triggers = planner.planTriggers(plan, generation = 1, nowUtcMillis = now)
        val mainCount = triggers.count { it.kind == TriggerKind.MAIN }
        val preCount = triggers.count { it.kind == TriggerKind.PRE }

        assertEquals(1, mainCount)
        assertEquals(3, preCount)
        assertTrue(triggers.all { it.scheduledUtcMillis > now })
    }

    @Test
    fun plansNextFridayWithThursdayEveningAndFridayMorningReminders() {
        val zone = ZoneId.of("UTC")
        val nextFridayTenAm = ZonedDateTime.of(2026, 3, 13, 10, 0, 0, 0, zone)
        val plan = AlarmPlan(
            alarmId = 200,
            title = "Meeting",
            hour24 = 10,
            minute = 0,
            repeatDays = emptyList(),
            enabled = true,
            sound = "Default Alarm",
            challenge = "None",
            snoozeCount = 3,
            snoozeDuration = 5,
            vibration = true,
            anchorUtcMillis = nextFridayTenAm.toInstant().toEpochMilli(),
            timezoneId = "UTC",
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = listOf(960, 120), // Thu 18:00 + Fri 08:00
            createdAtUtcMillis = 0,
            updatedAtUtcMillis = 0,
        )

        val now = ZonedDateTime.of(2026, 3, 9, 9, 0, 0, 0, zone).toInstant().toEpochMilli()
        val triggers = planner.planTriggers(plan, generation = 1, nowUtcMillis = now)

        assertEquals(3, triggers.size)
        assertEquals(listOf(TriggerKind.PRE, TriggerKind.PRE, TriggerKind.MAIN), triggers.map { it.kind })
        assertEquals("2026-03-12T18:00", triggers[0].scheduledLocalIso)
        assertEquals("2026-03-13T08:00", triggers[1].scheduledLocalIso)
        assertEquals("2026-03-13T10:00", triggers[2].scheduledLocalIso)
    }

    @Test
    fun filtersPastPreReminder() {
        val plan = AlarmPlan(
            alarmId = 101,
            title = "Soon",
            hour24 = 12,
            minute = 30,
            repeatDays = emptyList(),
            enabled = true,
            sound = "Default Alarm",
            challenge = "None",
            snoozeCount = 3,
            snoozeDuration = 5,
            vibration = true,
            anchorUtcMillis = null,
            timezoneId = "UTC",
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = listOf(180),
            createdAtUtcMillis = 0,
            updatedAtUtcMillis = 0,
        )

        val now = java.time.ZonedDateTime.of(2026, 4, 1, 12, 0, 0, 0, java.time.ZoneId.of("UTC"))
            .toInstant().toEpochMilli()

        val triggers = planner.planTriggers(plan, generation = 1, nowUtcMillis = now)

        assertEquals(1, triggers.count { it.kind == TriggerKind.MAIN })
        assertEquals(0, triggers.count { it.kind == TriggerKind.PRE })
    }
}
