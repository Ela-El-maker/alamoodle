package com.example.alarmmaster.alarm.reliability

import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TestAlarmResult
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.scheduler.AlarmScheduler
import com.example.alarmmaster.alarm.scheduler.ExactAlarmPermissionGate
import com.example.alarmmaster.alarm.scheduler.TriggerIdFactory
import java.time.Instant
import java.time.ZoneId

class TestAlarmRunner(
    private val alarmRepository: AlarmRepository,
    private val triggerRepository: TriggerRepository,
    private val historyRepository: HistoryRepository,
    private val alarmScheduler: AlarmScheduler,
    private val triggerIdFactory: TriggerIdFactory,
    private val exactAlarmPermissionGate: ExactAlarmPermissionGate,
) {
    suspend fun run(): TestAlarmResult {
        if (!exactAlarmPermissionGate.canScheduleExactAlarms()) {
            return TestAlarmResult(
                success = false,
                message = "Exact alarms unavailable",
                scheduledAtUtcMillis = null,
            )
        }

        val now = System.currentTimeMillis()
        val scheduledAt = now + 15_000L
        val generation = ((now / 1000L) % 100_000L).toInt()

        val alarm = alarmRepository.getAll().firstOrNull { it.enabled } ?: createTestAlarm(now)
        val trigger = buildTestTrigger(alarm.alarmId, generation, scheduledAt)

        triggerRepository.upsertTrigger(trigger)
        alarmScheduler.scheduleTrigger(trigger)
        historyRepository.record(
            alarmId = alarm.alarmId,
            triggerId = trigger.triggerId,
            eventType = "TEST_ALARM_SCHEDULED",
            meta = "scheduledAtUtcMillis=$scheduledAt",
        )

        return TestAlarmResult(
            success = true,
            message = "Test alarm scheduled for ~15 seconds",
            scheduledAtUtcMillis = scheduledAt,
        )
    }

    private suspend fun createTestAlarm(now: Long): AlarmPlan {
        val zoned = Instant.ofEpochMilli(now).atZone(ZoneId.systemDefault())
        val plan = AlarmPlan(
            alarmId = now,
            title = "[System] Test Alarm",
            hour24 = zoned.hour,
            minute = zoned.minute,
            repeatDays = emptyList(),
            enabled = true,
            sound = "Default Alarm",
            challenge = "None",
            snoozeCount = 0,
            snoozeDuration = 5,
            vibration = true,
            anchorUtcMillis = null,
            timezoneId = zoned.zone.id,
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = emptyList(),
            createdAtUtcMillis = now,
            updatedAtUtcMillis = now,
        )
        alarmRepository.upsert(plan)
        return plan
    }

    private fun buildTestTrigger(alarmId: Long, generation: Int, scheduledAt: Long): TriggerInstance {
        val index = (scheduledAt % 10_000L).toInt()
        return TriggerInstance(
            triggerId = triggerIdFactory.buildTriggerId(
                alarmId = alarmId,
                kind = TriggerKind.PRE,
                index = index,
                generation = generation,
                scheduledUtcMillis = scheduledAt,
            ),
            alarmId = alarmId,
            kind = TriggerKind.PRE,
            scheduledLocalIso = Instant.ofEpochMilli(scheduledAt).atZone(ZoneId.systemDefault()).toLocalDateTime().toString(),
            scheduledUtcMillis = scheduledAt,
            requestCode = triggerIdFactory.buildRequestCode(
                alarmId = alarmId,
                kind = TriggerKind.PRE,
                index = index,
                generation = generation,
            ),
            status = TriggerStatus.SCHEDULED,
            generation = generation,
        )
    }
}
