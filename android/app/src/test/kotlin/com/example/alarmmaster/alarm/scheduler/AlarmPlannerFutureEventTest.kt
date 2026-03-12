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

class AlarmPlannerFutureEventTest {
    private val zone: ZoneId = ZoneId.of("Africa/Nairobi")
    private val planner = AlarmPlanner(
        triggerIdFactory = TriggerIdFactory(),
        recurrenceEngine = KotlinRecurrenceEngine(),
        reminderBundlePlanner = ReminderBundlePlanner(),
    )

    @Test
    fun `plans next-month event with pre-reminders and main trigger`() {
        val now = ZonedDateTime.of(2026, 3, 11, 12, 0, 0, 0, zone)
        val event = ZonedDateTime.of(2026, 4, 10, 13, 0, 0, 0, zone)
        val plan = buildEventPlan(
            anchorUtcMillis = event.toInstant().toEpochMilli(),
            reminderOffsetsMinutes = listOf(10080, 1440, 60),
            reminderBeforeOnly = false,
        )

        val triggers = planner.planTriggers(
            plan = plan,
            generation = 12345,
            nowUtcMillis = now.toInstant().toEpochMilli(),
        )

        val expectedTimes = listOf(
            event.minusWeeks(1).toInstant().toEpochMilli(),
            event.minusDays(1).toInstant().toEpochMilli(),
            event.minusHours(1).toInstant().toEpochMilli(),
            event.toInstant().toEpochMilli(),
        )

        assertEquals(4, triggers.size)
        assertEquals(expectedTimes, triggers.map { it.scheduledUtcMillis })
        assertEquals(
            listOf(TriggerKind.PRE, TriggerKind.PRE, TriggerKind.PRE, TriggerKind.MAIN),
            triggers.map { it.kind },
        )
        assertTrue(triggers.all { it.scheduledUtcMillis > now.toInstant().toEpochMilli() })
    }

    @Test
    fun `before-only mode keeps pre-reminders and omits main trigger`() {
        val now = ZonedDateTime.of(2026, 3, 11, 12, 0, 0, 0, zone)
        val event = ZonedDateTime.of(2026, 4, 10, 13, 0, 0, 0, zone)
        val plan = buildEventPlan(
            anchorUtcMillis = event.toInstant().toEpochMilli(),
            reminderOffsetsMinutes = listOf(10080, 1440, 60),
            reminderBeforeOnly = true,
        )

        val triggers = planner.planTriggers(
            plan = plan,
            generation = 12345,
            nowUtcMillis = now.toInstant().toEpochMilli(),
        )

        assertEquals(3, triggers.size)
        assertTrue(triggers.all { it.kind == TriggerKind.PRE })
        assertEquals(
            listOf(
                event.minusWeeks(1).toInstant().toEpochMilli(),
                event.minusDays(1).toInstant().toEpochMilli(),
                event.minusHours(1).toInstant().toEpochMilli(),
            ),
            triggers.map { it.scheduledUtcMillis },
        )
    }

    private fun buildEventPlan(
        anchorUtcMillis: Long,
        reminderOffsetsMinutes: List<Int>,
        reminderBeforeOnly: Boolean,
    ): AlarmPlan {
        return AlarmPlan(
            alarmId = 9001L,
            title = "Future Event",
            hour24 = 13,
            minute = 0,
            repeatDays = emptyList(),
            enabled = true,
            sound = "default_alarm",
            challenge = "None",
            snoozeCount = 2,
            snoozeDuration = 5,
            vibration = true,
            anchorUtcMillis = anchorUtcMillis,
            timezoneId = zone.id,
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = reminderOffsetsMinutes,
            recurrenceType = null,
            recurrenceInterval = null,
            recurrenceWeekdays = emptyList(),
            recurrenceDayOfMonth = null,
            recurrenceOrdinal = null,
            recurrenceOrdinalWeekday = null,
            recurrenceExclusionDates = emptyList(),
            reminderOffsetsMinutes = reminderOffsetsMinutes,
            reminderBeforeOnly = reminderBeforeOnly,
            createdAtUtcMillis = anchorUtcMillis - 60_000L,
            updatedAtUtcMillis = anchorUtcMillis - 60_000L,
        )
    }
}

