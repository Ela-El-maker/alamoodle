package com.example.alarmmaster.alarm

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.alarmmaster.alarm.bridge.AlarmCoreService
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.service.AlarmRingingService
import com.example.alarmmaster.bridge.gen.CreateAlarmCommandDto
import com.example.alarmmaster.bridge.gen.TriggerDto
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.FileInputStream
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlin.math.max

@RunWith(AndroidJUnit4::class)
class FutureEventCertificationTest {
    private val certTag = "FutureEventCert"

    @Test
    fun canonicalNextMonth_triggerPlan_has3d1d1hAndMain() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val zone = ZoneId.systemDefault()
        val alarmId = System.currentTimeMillis()
        val anchor = nextMonthAnchor(zone)
        val offsets = listOf(4320, 1440, 60)

        try {
            val created = kotlinx.coroutines.runBlocking {
                service.createAlarm(buildAnchoredCommand(alarmId, anchor, offsets))
            }
            val checkpoints = kotlinx.coroutines.runBlocking {
                service.debugGetAlarmTriggerCheckpoints(alarmId)
            }
            val main = created.triggers.firstOrNull { it.kind == "MAIN" }
            assertNotNull("Expected MAIN trigger for canonical future event", main)
            assertEquals("Expected 3 PRE + 1 MAIN trigger", 4, checkpoints.size)

            val pre = checkpoints.filter { it.kind == "PRE" }
            assertEquals("Expected 3 PRE triggers", 3, pre.size)
            assertTrue("Expected MAIN trigger checkpoint", checkpoints.any { it.kind == "MAIN" })

            val expectedUtc = offsets.sortedDescending().map { offset ->
                anchor.minusMinutes(offset.toLong()).toInstant().toEpochMilli()
            } + anchor.toInstant().toEpochMilli()
            val actualUtc = checkpoints.sortedBy { it.scheduledUtcMillis }.map { it.scheduledUtcMillis }
            assertEquals("Expected exact UTC schedule map for canonical offsets", expectedUtc, actualUtc)

            checkpoints.forEach {
                emitExpected(
                    lane = "canonical",
                    alarmId = alarmId,
                    trigger = it,
                )
            }
        } finally {
            kotlinx.coroutines.runBlocking {
                service.deleteAlarm(alarmId)
            }
        }
    }

    @Test
    fun canonicalNextMonth_persistsAcrossKillRelaunchAndRecoveryReasons() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val zone = ZoneId.systemDefault()
        val alarmId = System.currentTimeMillis()
        val anchor = nextMonthAnchor(zone)
        val offsets = listOf(4320, 1440, 60)

        try {
            kotlinx.coroutines.runBlocking {
                service.createAlarm(buildAnchoredCommand(alarmId, anchor, offsets))
            }
            val before = kotlinx.coroutines.runBlocking {
                service.debugGetAlarmTriggerCheckpoints(alarmId)
            }.associateBy { it.triggerId }

            runShell("am kill com.example.alarmmaster")
            Thread.sleep(1200)
            runShell("am start -n com.example.alarmmaster/.MainActivity")
            Thread.sleep(3500)

            kotlinx.coroutines.runBlocking {
                service.debugRunStartupSanity()
                service.debugRunRecovery("BOOT_COMPLETED")
                service.debugRunRecovery("PACKAGE_REPLACED")
            }

            val after = kotlinx.coroutines.runBlocking {
                service.debugGetAlarmTriggerCheckpoints(alarmId)
            }.associateBy { it.triggerId }

            assertEquals("Trigger count must persist after kill/recovery", before.size, after.size)
            before.forEach { (triggerId, pre) ->
                val post = after[triggerId]
                assertNotNull("Missing trigger after recovery: $triggerId", post)
                assertEquals("requestCode drift for $triggerId", pre.requestCode, post!!.requestCode)
                assertEquals("generation drift for $triggerId", pre.generation, post.generation)
                assertEquals("schedule drift for $triggerId", pre.scheduledUtcMillis, post.scheduledUtcMillis)
            }
        } finally {
            kotlinx.coroutines.runBlocking {
                service.deleteAlarm(alarmId)
            }
        }
    }

    @Test
    fun acceleratedMirror_postsPreNotifications_thenMainRings() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val zone = ZoneId.systemDefault()
        val alarmId = System.currentTimeMillis()
        val now = ZonedDateTime.now(zone)
        val anchor = now.plusMinutes(8).withSecond(0).withNano(0)
        val offsets = listOf(6, 3, 1)

        // Keep accelerated-stage delivery deterministic on OEM devices that may enter idle.
        runCatching { runShell("dumpsys deviceidle disable") }
        try {
            val created = kotlinx.coroutines.runBlocking {
                service.createAlarm(buildAnchoredCommand(alarmId, anchor, offsets))
            }
            val pre = created.triggers
                .filter { it.kind == "PRE" }
                .sortedBy { it.scheduledUtcMillis }
            val main = created.triggers.firstOrNull { it.kind == "MAIN" }
            assertEquals("Expected 3 PRE triggers for accelerated mirror", 3, pre.size)
            assertNotNull("Expected MAIN trigger for accelerated mirror", main)

            pre.forEach { trigger ->
                emitExpected(
                    lane = "accelerated",
                    alarmId = alarmId,
                    trigger = trigger,
                )
            }
            emitExpected(
                lane = "accelerated",
                alarmId = alarmId,
                trigger = main!!,
            )

            pre.forEach { trigger ->
                waitForEvent(
                    service = service,
                    alarmId = alarmId,
                    triggerId = trigger.triggerId,
                    eventType = "PRE_NOTIFICATION_POSTED",
                    timeoutMs = waitBudget(trigger.scheduledUtcMillis),
                )
                emitObserved(
                    lane = "accelerated",
                    alarmId = alarmId,
                    triggerId = trigger.triggerId,
                    eventType = "PRE_NOTIFICATION_POSTED",
                )
                assertFalse(
                    "PRE trigger must not enter ringing session: ${trigger.triggerId}",
                    hasEvent(service, alarmId, trigger.triggerId, "SERVICE_STARTED"),
                )
            }

            val mainTrigger = requireNotNull(main) { "MAIN trigger disappeared unexpectedly" }
            waitForEvent(
                service = service,
                alarmId = alarmId,
                triggerId = mainTrigger.triggerId,
                eventType = "SERVICE_STARTED",
                timeoutMs = waitBudget(mainTrigger.scheduledUtcMillis),
            )
            emitObserved(
                lane = "accelerated",
                alarmId = alarmId,
                triggerId = mainTrigger.triggerId,
                eventType = "SERVICE_STARTED",
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
            emitObserved(
                lane = "accelerated",
                alarmId = alarmId,
                triggerId = mainTrigger.triggerId,
                eventType = "DISMISSED",
            )
        } finally {
            runCatching { runShell("dumpsys deviceidle enable") }
            kotlinx.coroutines.runBlocking {
                service.deleteAlarm(alarmId)
            }
        }
    }

    @Test
    fun simultaneousFutureEvents_keepDistinctTriggerIdentity() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val zone = ZoneId.systemDefault()
        val anchor = ZonedDateTime.now(zone).plusDays(35).withHour(13).withMinute(0).withSecond(0).withNano(0)
        val offsets = listOf(1440, 60)
        val alarmIdA = System.currentTimeMillis()
        val alarmIdB = alarmIdA + 1

        try {
            kotlinx.coroutines.runBlocking {
                service.createAlarm(buildAnchoredCommand(alarmIdA, anchor, offsets))
                service.createAlarm(buildAnchoredCommand(alarmIdB, anchor, offsets))
                service.debugRunRecovery("PACKAGE_REPLACED")
            }

            val a = kotlinx.coroutines.runBlocking { service.debugGetAlarmTriggerCheckpoints(alarmIdA) }
            val b = kotlinx.coroutines.runBlocking { service.debugGetAlarmTriggerCheckpoints(alarmIdB) }
            assertEquals(3, a.size)
            assertEquals(3, b.size)
            val aIds = a.map { it.triggerId }.toSet()
            val bIds = b.map { it.triggerId }.toSet()
            assertTrue("Trigger IDs must be unique across simultaneous events", aIds.intersect(bIds).isEmpty())
        } finally {
            kotlinx.coroutines.runBlocking {
                service.deleteAlarm(alarmIdA)
                service.deleteAlarm(alarmIdB)
            }
        }
    }

    private fun nextMonthAnchor(zone: ZoneId): ZonedDateTime {
        return ZonedDateTime.now(zone)
            .plusMonths(1)
            .withDayOfMonth(10)
            .withHour(13)
            .withMinute(0)
            .withSecond(0)
            .withNano(0)
    }

    private fun buildAnchoredCommand(
        alarmId: Long,
        anchor: ZonedDateTime,
        offsetsMinutes: List<Int>,
    ): CreateAlarmCommandDto {
        return CreateAlarmCommandDto(
            alarmId = alarmId,
            title = "Future Event Certification",
            hour24 = anchor.hour.toLong(),
            minute = anchor.minute.toLong(),
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
            anchorUtcMillis = anchor.toInstant().toEpochMilli(),
            timezoneId = anchor.zone.id,
            timezonePolicy = "FIXED_LOCAL_TIME",
            preReminderMinutes = offsetsMinutes.map { it.toLong() },
            recurrenceType = null,
            recurrenceInterval = null,
            recurrenceWeekdays = emptyList(),
            recurrenceDayOfMonth = null,
            recurrenceOrdinal = null,
            recurrenceOrdinalWeekday = null,
            recurrenceExclusionDates = emptyList(),
            reminderOffsetsMinutes = offsetsMinutes.map { it.toLong() },
            reminderBeforeOnly = false,
        )
    }

    private fun waitBudget(triggerUtcMillis: Long): Long {
        val until = triggerUtcMillis - System.currentTimeMillis()
        return max(90_000L, until + 90_000L)
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
            if (hasEvent(service, alarmId, triggerId, eventType)) return
            Thread.sleep(500)
        }
        throw AssertionError(
            "Timed out waiting for event=$eventType alarmId=$alarmId triggerId=$triggerId timeoutMs=$timeoutMs",
        )
    }

    private fun hasEvent(
        service: AlarmCoreService,
        alarmId: Long,
        triggerId: String,
        eventType: String,
    ): Boolean {
        return kotlinx.coroutines.runBlocking {
            service.getAlarmHistory(alarmId).any {
                it.triggerId == triggerId && it.eventType == eventType
            }
        }
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

    private fun runShell(command: String): String {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        instrumentation.uiAutomation.executeShellCommand(command).use { parcel ->
            return FileInputStream(parcel.fileDescriptor).bufferedReader().readText()
        }
    }

    private fun emitExpected(
        lane: String,
        alarmId: Long,
        trigger: TriggerDto,
    ) {
        val payload =
            "CERT_EXPECT lane=$lane alarmId=$alarmId triggerId=${trigger.triggerId} " +
                "kind=${trigger.kind} scheduledUtc=${trigger.scheduledUtcMillis} requestCode=${trigger.requestCode} generation=${trigger.generation}"
        println(payload)
        Log.i(certTag, payload)
    }

    private fun emitObserved(
        lane: String,
        alarmId: Long,
        triggerId: String,
        eventType: String,
    ) {
        val payload =
            "CERT_OBSERVED lane=$lane alarmId=$alarmId triggerId=$triggerId " +
                "eventType=$eventType observedUtc=${System.currentTimeMillis()}"
        println(payload)
        Log.i(certTag, payload)
    }
}
