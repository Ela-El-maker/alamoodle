package com.example.alarmmaster.alarm

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.alarmmaster.alarm.bridge.AlarmCoreService
import com.example.alarmmaster.bridge.gen.CreateAlarmCommandDto
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.FileInputStream
import java.time.ZoneId
import java.time.ZonedDateTime

@RunWith(AndroidJUnit4::class)
class RecoveryReliabilityPhysicalTest {

    @Test
    fun startupSanity_repairsMissingRegistryRow() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val alarmId = System.currentTimeMillis()
        val event = ZonedDateTime.now(ZoneId.systemDefault()).plusMinutes(5).withSecond(0).withNano(0)

        val created = kotlinx.coroutines.runBlocking {
            service.createAlarm(buildAnchoredCommand(alarmId, event))
        }
        val main = created.triggers.firstOrNull { it.kind == "MAIN" }
        assertNotNull("Expected MAIN trigger", main)
        val triggerId = main!!.triggerId

        kotlinx.coroutines.runBlocking {
            assertTrue("Expected registry row to exist before corruption", service.debugCorruptSchedule(triggerId))
            assertFalse(
                "Registry row should be removed by corruption hook",
                service.debugListScheduleRegistry().any { it.triggerId == triggerId },
            )
            service.debugRunStartupSanity()
            assertTrue(
                "Startup sanity should restore missing registry row",
                service.debugListScheduleRegistry().any { it.triggerId == triggerId },
            )
            service.deleteAlarm(alarmId)
        }
    }

    @Test
    fun startupSanity_removesStaleRegistryRow() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val staleTriggerId = "stale-${System.currentTimeMillis()}"
        val staleAlarmId = 99_999_999L
        val staleRequestCode = 88_888_888
        val staleUtc = System.currentTimeMillis() + 24 * 60 * 60 * 1000L

        kotlinx.coroutines.runBlocking {
            service.debugInsertStaleScheduleRegistryEntry(
                triggerId = staleTriggerId,
                alarmId = staleAlarmId,
                requestCode = staleRequestCode,
                scheduledUtcMillis = staleUtc,
            )
            assertTrue(
                "Expected injected stale row to exist before recovery",
                service.debugListScheduleRegistry().any { it.triggerId == staleTriggerId },
            )
            service.debugRunStartupSanity()
            assertFalse(
                "Startup sanity should remove stale registry row",
                service.debugListScheduleRegistry().any { it.triggerId == staleTriggerId },
            )
        }
    }

    @Test
    fun processKillAndRelaunch_preservesFutureTriggersAndRunsStartupSanity() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val alarmId = System.currentTimeMillis()
        val event = ZonedDateTime.now(ZoneId.systemDefault()).plusMinutes(30).withSecond(0).withNano(0)

        val created = kotlinx.coroutines.runBlocking {
            service.createAlarm(buildAnchoredCommand(alarmId, event))
        }
        val expectedMain = created.triggers.firstOrNull { it.kind == "MAIN" }
        assertNotNull("Expected MAIN trigger", expectedMain)

        runShell("am kill com.example.alarmmaster")
        Thread.sleep(1500)
        runShell("am start -n com.example.alarmmaster/.MainActivity")
        Thread.sleep(4000)

        kotlinx.coroutines.runBlocking {
            val detail = service.getAlarmDetail(alarmId)
            assertNotNull("Alarm detail should still exist after process kill/relaunch", detail)
            val actualMain = detail!!.triggers.firstOrNull { it.kind == "MAIN" }
            assertNotNull("MAIN trigger should still exist after relaunch", actualMain)
            assertEquals(expectedMain!!.triggerId, actualMain!!.triggerId)
            assertEquals(expectedMain.requestCode, actualMain.requestCode)
            assertEquals(expectedMain.generation, actualMain.generation)
            assertEquals(expectedMain.scheduledUtcMillis, actualMain.scheduledUtcMillis)
            val sanityStatus = service.debugRunStartupSanity()
            assertTrue(
                "Startup sanity should complete with a known status",
                sanityStatus == "ok" || sanityStatus == "repaired" || sanityStatus == "degraded",
            )
            service.deleteAlarm(alarmId)
        }
    }

    @Test
    fun longHorizon_nextMonthTriggerPersistsAcrossProcessKillRelaunch() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val alarmId = System.currentTimeMillis()
        val zone = ZoneId.systemDefault()
        val nextMonthAnchor = ZonedDateTime.now(zone)
            .plusMonths(1)
            .withDayOfMonth(10)
            .withHour(13)
            .withMinute(0)
            .withSecond(0)
            .withNano(0)

        val created = kotlinx.coroutines.runBlocking {
            service.createAlarm(buildAnchoredCommand(alarmId, nextMonthAnchor))
        }
        val beforeMain = created.triggers.firstOrNull { it.kind == "MAIN" }
        assertNotNull("Expected MAIN trigger for long-horizon alarm", beforeMain)

        runShell("am kill com.example.alarmmaster")
        Thread.sleep(1500)
        runShell("am start -n com.example.alarmmaster/.MainActivity")
        Thread.sleep(4000)

        kotlinx.coroutines.runBlocking {
            val afterDetail = service.getAlarmDetail(alarmId)
            assertNotNull("Long-horizon alarm should persist after relaunch", afterDetail)
            val afterMain = afterDetail!!.triggers.firstOrNull { it.kind == "MAIN" }
            assertNotNull("MAIN trigger should persist after relaunch", afterMain)
            assertEquals(beforeMain!!.triggerId, afterMain!!.triggerId)
            assertEquals(beforeMain.requestCode, afterMain.requestCode)
            assertEquals(beforeMain.generation, afterMain.generation)
            assertEquals(beforeMain.scheduledUtcMillis, afterMain.scheduledUtcMillis)

            val future = service.debugListFutureTriggers()
            assertTrue(
                "Expected future trigger list to include long-horizon alarm",
                future.any { it.triggerId == beforeMain.triggerId },
            )
            service.deleteAlarm(alarmId)
        }
    }

    @Test
    fun futureEvent_rebootAndPackageRecovery_keepTriggersStable() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val zone = ZoneId.systemDefault()
        val alarmId = System.currentTimeMillis()
        val anchor = ZonedDateTime.now(zone)
            .plusMonths(1)
            .withDayOfMonth(10)
            .withHour(13)
            .withMinute(0)
            .withSecond(0)
            .withNano(0)

        try {
            kotlinx.coroutines.runBlocking {
                service.createAlarm(buildAnchoredCommand(alarmId, anchor))
            }
            val before = kotlinx.coroutines.runBlocking {
                service.debugGetAlarmTriggerCheckpoints(alarmId)
            }.associateBy { it.triggerId }

            kotlinx.coroutines.runBlocking {
                service.debugRunRecovery("LOCKED_BOOT_COMPLETED")
                service.debugRunRecovery("BOOT_COMPLETED")
                service.debugRunRecovery("PACKAGE_REPLACED")
            }

            val after = kotlinx.coroutines.runBlocking {
                service.debugGetAlarmTriggerCheckpoints(alarmId)
            }.associateBy { it.triggerId }

            assertEquals("Trigger count changed after simulated reboot/package recovery", before.size, after.size)
            before.forEach { (triggerId, pre) ->
                val post = after[triggerId]
                assertNotNull("Trigger missing after recovery: $triggerId", post)
                assertEquals(pre.requestCode, post!!.requestCode)
                assertEquals(pre.generation, post.generation)
                assertEquals(pre.scheduledUtcMillis, post.scheduledUtcMillis)
            }
        } finally {
            kotlinx.coroutines.runBlocking {
                service.deleteAlarm(alarmId)
            }
        }
    }

    @Test
    fun futureEvent_overlappingSchedules_surviveRecoveryWithoutCollisions() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val service = AlarmCoreService(context)
        val zone = ZoneId.systemDefault()
        val anchor = ZonedDateTime.now(zone).plusMonths(1).withDayOfMonth(10).withHour(13).withMinute(0).withSecond(0).withNano(0)
        val alarmIdA = System.currentTimeMillis()
        val alarmIdB = alarmIdA + 1

        try {
            kotlinx.coroutines.runBlocking {
                service.createAlarm(buildAnchoredCommand(alarmIdA, anchor))
                service.createAlarm(buildAnchoredCommand(alarmIdB, anchor))
                service.debugRunRecovery("BOOT_COMPLETED")
            }

            val a = kotlinx.coroutines.runBlocking { service.debugGetAlarmTriggerCheckpoints(alarmIdA) }
            val b = kotlinx.coroutines.runBlocking { service.debugGetAlarmTriggerCheckpoints(alarmIdB) }
            val overlap = a.map { it.triggerId }.toSet().intersect(b.map { it.triggerId }.toSet())
            assertTrue("Overlapping future events must not share trigger IDs", overlap.isEmpty())
        } finally {
            kotlinx.coroutines.runBlocking {
                service.deleteAlarm(alarmIdA)
                service.deleteAlarm(alarmIdB)
            }
        }
    }

    private fun buildAnchoredCommand(
        alarmId: Long,
        anchor: ZonedDateTime,
    ): CreateAlarmCommandDto {
        return CreateAlarmCommandDto(
            alarmId = alarmId,
            title = "Recovery Reliability Test",
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
        )
    }

    private fun runShell(command: String): String {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        instrumentation.uiAutomation.executeShellCommand(command).use { parcel ->
            return FileInputStream(parcel.fileDescriptor).bufferedReader().readText()
        }
    }
}
