package com.example.alarmmaster.alarm.receiver

import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import org.junit.Assert.assertEquals
import org.junit.Test

class AlarmTriggerValidatorTest {
    @Test
    fun validatesMissingAndStaleAndDisabledAndValidCases() {
        val plan = samplePlan(enabled = true)
        val trigger = sampleTrigger(generation = 5)

        assertEquals(
            TriggerValidationResult.MISSING_TRIGGER,
            AlarmTriggerValidator.validate(payloadGeneration = 5, dbTrigger = null, plan = plan),
        )

        assertEquals(
            TriggerValidationResult.STALE_GENERATION,
            AlarmTriggerValidator.validate(payloadGeneration = 4, dbTrigger = trigger, plan = plan),
        )

        assertEquals(
            TriggerValidationResult.DISABLED_ALARM,
            AlarmTriggerValidator.validate(payloadGeneration = 5, dbTrigger = trigger, plan = samplePlan(enabled = false)),
        )

        assertEquals(
            TriggerValidationResult.VALID,
            AlarmTriggerValidator.validate(payloadGeneration = 5, dbTrigger = trigger, plan = plan),
        )

        assertEquals(
            TriggerValidationResult.ALREADY_CONSUMED,
            AlarmTriggerValidator.validate(
                payloadGeneration = 5,
                dbTrigger = trigger.copy(status = TriggerStatus.FIRED),
                plan = plan,
            ),
        )
    }

    private fun samplePlan(enabled: Boolean): AlarmPlan {
        return AlarmPlan(
            alarmId = 1L,
            title = "Alarm",
            hour24 = 7,
            minute = 0,
            repeatDays = emptyList(),
            enabled = enabled,
            sound = "Default Alarm",
            challenge = "None",
            snoozeCount = 3,
            snoozeDuration = 5,
            vibration = true,
            anchorUtcMillis = null,
            timezoneId = "UTC",
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = emptyList(),
            createdAtUtcMillis = 0,
            updatedAtUtcMillis = 0,
        )
    }

    private fun sampleTrigger(generation: Int): TriggerInstance {
        return TriggerInstance(
            triggerId = "t-1",
            alarmId = 1L,
            kind = TriggerKind.MAIN,
            scheduledLocalIso = "2026-03-11T07:00",
            scheduledUtcMillis = 1_777_000_000_000,
            requestCode = 123,
            status = TriggerStatus.SCHEDULED,
            generation = generation,
        )
    }
}
