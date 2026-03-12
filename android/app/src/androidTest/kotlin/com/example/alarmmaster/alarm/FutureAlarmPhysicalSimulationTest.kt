package com.example.alarmmaster.alarm

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.alarmmaster.alarm.bridge.AlarmCoreService
import com.example.alarmmaster.alarm.notification.AlarmAction
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.receiver.AlarmActionReceiver
import com.example.alarmmaster.alarm.service.AlarmRingingService
import com.example.alarmmaster.bridge.gen.CreateAlarmCommandDto
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlin.math.max

@RunWith(AndroidJUnit4::class)
class FutureAlarmPhysicalSimulationTest {

    @Test
    fun anchoredFutureAlarm_withPreReminder_firesPreAndMainOnPhysicalDevice() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val zone = ZoneId.systemDefault()
        val now = ZonedDateTime.now(zone)

        // Keep this short enough for CI/device run, but still a true future-event simulation.
        val eventTime = now.plusMinutes(3).withSecond(0).withNano(0)
        val alarmId = System.currentTimeMillis()

        val created = runCatching {
            kotlinx.coroutines.runBlocking {
                service.createAlarm(
                    CreateAlarmCommandDto(
                        alarmId = alarmId,
                        title = "Physical Future Event Simulation",
                        hour24 = eventTime.hour.toLong(),
                        minute = eventTime.minute.toLong(),
                        repeatDays = emptyList(),
                        enabled = true,
                        sound = "default_alarm",
                        challenge = "None",
                        snoozeCount = 1,
                        snoozeDuration = 5,
                        vibration = true,
                        vibrationProfileId = "default",
                        escalationPolicy = null,
                        nagPolicy = null,
                        primaryAction = null,
                        challengePolicy = null,
                        anchorUtcMillis = eventTime.toInstant().toEpochMilli(),
                        timezoneId = zone.id,
                        timezonePolicy = "FIXED_LOCAL_TIME",
                        preReminderMinutes = listOf(1),
                        recurrenceType = null,
                        recurrenceInterval = null,
                        recurrenceWeekdays = emptyList(),
                        recurrenceDayOfMonth = null,
                        recurrenceOrdinal = null,
                        recurrenceOrdinalWeekday = null,
                        recurrenceExclusionDates = emptyList(),
                        reminderOffsetsMinutes = listOf(1),
                        reminderBeforeOnly = false,
                    ),
                )
            }
        }.getOrElse { throw AssertionError("Failed to create simulation alarm", it) }

        val pre = created.triggers.firstOrNull { it.kind == "PRE" }
        val main = created.triggers.firstOrNull { it.kind == "MAIN" }
        assertNotNull("Expected PRE trigger for simulated event", pre)
        assertNotNull("Expected MAIN trigger for simulated event", main)

        val preTrigger = pre!!
        val mainTrigger = main!!
        assertTrue("PRE must be before MAIN", preTrigger.scheduledUtcMillis < mainTrigger.scheduledUtcMillis)

        waitForEvent(
            service = service,
            alarmId = alarmId,
            triggerId = preTrigger.triggerId,
            eventType = "PRE_NOTIFICATION_POSTED",
            timeoutMs = waitBudget(preTrigger.scheduledUtcMillis),
        )
        dismissPreNotification(
            context = context,
            alarmId = alarmId,
            triggerId = preTrigger.triggerId,
            generation = preTrigger.generation.toInt(),
        )
        waitForEvent(
            service = service,
            alarmId = alarmId,
            triggerId = preTrigger.triggerId,
            eventType = "PRE_NOTIFICATION_DISMISSED",
            timeoutMs = 45_000L,
        )

        waitForEvent(
            service = service,
            alarmId = alarmId,
            triggerId = mainTrigger.triggerId,
            eventType = "SERVICE_STARTED",
            timeoutMs = waitBudget(mainTrigger.scheduledUtcMillis),
        )
        dismissCurrentRing(
            context = context,
            alarmId = alarmId,
            triggerId = mainTrigger.triggerId,
            generation = mainTrigger.generation.toInt(),
        )
        waitForEvent(
            service = service,
            alarmId = alarmId,
            triggerId = mainTrigger.triggerId,
            eventType = "DISMISSED",
            timeoutMs = 45_000L,
        )
    }

    private fun waitBudget(triggerUtcMillis: Long): Long {
        val until = triggerUtcMillis - System.currentTimeMillis()
        return max(60_000L, until + 90_000L)
    }

    private fun dismissCurrentRing(
        context: Context,
        alarmId: Long,
        triggerId: String,
        generation: Int,
    ) {
        val dismissIntent = Intent(context, AlarmRingingService::class.java).apply {
            action = AlarmRingingService.ACTION_DISMISS
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, triggerId)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, generation)
        }
        context.startService(dismissIntent)
    }

    private fun dismissPreNotification(
        context: Context,
        alarmId: Long,
        triggerId: String,
        generation: Int,
    ) {
        val dismissIntent = Intent(context, AlarmActionReceiver::class.java).apply {
            action = AlarmAction.PRE_DISMISS.actionId
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, triggerId)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, generation)
            putExtra(AlarmIntentExtras.EXTRA_SESSION_ID, "pre-$triggerId")
        }
        context.sendBroadcast(dismissIntent)
    }

    private fun waitForEvent(
        service: AlarmCoreService,
        alarmId: Long,
        triggerId: String,
        eventType: String,
        timeoutMs: Long,
    ) {
        val start = System.currentTimeMillis()
        while (System.currentTimeMillis() - start < timeoutMs) {
            val found = kotlinx.coroutines.runBlocking {
                service.getAlarmHistory(alarmId).any {
                    it.triggerId == triggerId && it.eventType == eventType
                }
            }
            if (found) return
            Thread.sleep(500)
        }
        throw AssertionError(
            "Timed out waiting for event=$eventType alarmId=$alarmId triggerId=$triggerId timeoutMs=$timeoutMs",
        )
    }
}
