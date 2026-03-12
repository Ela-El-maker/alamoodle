package com.example.alarmmaster.alarm.bridge

import com.example.alarmmaster.bridge.gen.AlarmHistoryDto
import com.example.alarmmaster.bridge.gen.AlarmPlanDto
import com.example.alarmmaster.bridge.gen.BackupImportResultDto
import com.example.alarmmaster.bridge.gen.CreateAlarmCommandDto
import com.example.alarmmaster.bridge.gen.OnboardingReadinessDto
import com.example.alarmmaster.bridge.gen.OemGuidanceDto
import com.example.alarmmaster.bridge.gen.ReliabilitySnapshotDto
import com.example.alarmmaster.bridge.gen.SoundProfileDto
import com.example.alarmmaster.bridge.gen.StatsSummaryDto
import com.example.alarmmaster.bridge.gen.StatsTrendPointDto
import com.example.alarmmaster.bridge.gen.TemplateDto
import com.example.alarmmaster.bridge.gen.TestAlarmResultDto
import com.example.alarmmaster.bridge.gen.TriggerDto
import com.example.alarmmaster.bridge.gen.UpdateAlarmCommandDto
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class GuardianAlarmHostApiImplTest {
    @Test
    fun createAlarm_routesToCoreGateway_andReturnsTypedDto() {
        val fakeGateway = FakeAlarmCoreGateway()
        val host = GuardianAlarmHostApiImpl(fakeGateway)
        val command = CreateAlarmCommandDto(
            alarmId = 99L,
            title = "Route Test",
            hour24 = 10L,
            minute = 0L,
            repeatDays = listOf("Fri"),
            enabled = true,
            sound = "Default Alarm",
            challenge = "None",
            snoozeCount = 3L,
            snoozeDuration = 5L,
            vibration = true,
            vibrationProfileId = null,
            escalationPolicy = null,
            nagPolicy = null,
            primaryAction = null,
            challengePolicy = null,
            anchorUtcMillis = 1_774_400_000_000L,
            timezoneId = "UTC",
            timezonePolicy = "FIXED_LOCAL_TIME",
            preReminderMinutes = listOf(60L),
            recurrenceType = null,
            recurrenceInterval = null,
            recurrenceWeekdays = emptyList(),
            recurrenceDayOfMonth = null,
            recurrenceOrdinal = null,
            recurrenceOrdinalWeekday = null,
            recurrenceExclusionDates = emptyList(),
            reminderOffsetsMinutes = listOf(60L),
            reminderBeforeOnly = false,
        )

        val result = host.createAlarm(command)

        assertEquals(99L, fakeGateway.lastCreateCommand?.alarmId)
        assertEquals(99L, result.alarmId)
        assertEquals("Route Test", result.title)
        assertNotNull(result.triggers)
    }

    private class FakeAlarmCoreGateway : AlarmCoreGateway {
        var lastCreateCommand: CreateAlarmCommandDto? = null

        override suspend fun createAlarm(command: CreateAlarmCommandDto): AlarmPlanDto {
            lastCreateCommand = command
            return samplePlan(command.alarmId ?: 99L, command.title)
        }

        override suspend fun updateAlarm(command: UpdateAlarmCommandDto): AlarmPlanDto {
            return samplePlan(command.alarmId, command.title)
        }

        override suspend fun deleteAlarm(alarmId: Long) = Unit

        override suspend fun enableAlarm(alarmId: Long): AlarmPlanDto {
            return samplePlan(alarmId, "Enabled")
        }

        override suspend fun disableAlarm(alarmId: Long): AlarmPlanDto {
            return samplePlan(alarmId, "Disabled")
        }

        override suspend fun getUpcomingAlarms(): List<AlarmPlanDto> {
            return listOf(samplePlan(1L, "One"))
        }

        override suspend fun getAlarmDetail(alarmId: Long): AlarmPlanDto {
            return samplePlan(alarmId, "Detail")
        }

        override suspend fun getAlarmHistory(alarmId: Long): List<AlarmHistoryDto> {
            return emptyList()
        }

        override suspend fun getReliabilitySnapshot(): ReliabilitySnapshotDto {
            return ReliabilitySnapshotDto(
                exactAlarmPermissionGranted = true,
                notificationsPermissionGranted = true,
                canScheduleExactAlarms = true,
                engineMode = "shadow_native",
                schedulerHealth = "healthy",
                nativeRingPipelineEnabled = true,
                legacyEmergencyRingFallbackEnabled = true,
                directBootReady = true,
                channelHealth = "healthy",
                fullScreenReady = true,
                batteryOptimizationRisk = "low",
                scheduleRegistryHealth = "healthy",
                lastRecoveryReason = "STARTUP_SANITY",
                lastRecoveryAtUtcMillis = 1L,
                lastRecoveryStatus = "ok",
                legacyFallbackDefaultEnabled = false,
            )
        }

        override suspend fun getRecentHistory(limit: Long, alarmId: Long?): List<AlarmHistoryDto> {
            return emptyList()
        }

        override suspend fun exportDiagnostics(): String {
            return "{}"
        }

        override suspend fun runTestAlarm(): TestAlarmResultDto {
            return TestAlarmResultDto(true, "ok", 1L)
        }

        override suspend fun openSystemSettings(target: String): Boolean {
            return true
        }

        override suspend fun getSoundCatalog(): List<SoundProfileDto> {
            return emptyList()
        }

        override suspend fun previewSound(soundId: String): Boolean {
            return true
        }

        override suspend fun stopSoundPreview(): Boolean {
            return true
        }

        override suspend fun getTemplates(): List<TemplateDto> {
            return emptyList()
        }

        override suspend fun saveTemplate(template: TemplateDto): TemplateDto {
            return template
        }

        override suspend fun deleteTemplate(templateId: Long) = Unit

        override suspend fun applyTemplate(templateId: Long): TemplateDto? = null

        override suspend fun exportBackup(): String {
            return "{}"
        }

        override suspend fun importBackup(payload: String): BackupImportResultDto {
            return BackupImportResultDto(
                success = true,
                message = "ok",
                restoredAlarms = 0,
                restoredTemplates = 0,
            )
        }

        override suspend fun getOemGuidance(): OemGuidanceDto {
            return OemGuidanceDto(
                manufacturer = "generic",
                title = "guidance",
                summary = "summary",
                steps = emptyList(),
                settingsTargets = emptyList(),
            )
        }

        override suspend fun previewPlannedTriggers(command: CreateAlarmCommandDto): List<TriggerDto> {
            return emptyList()
        }

        override suspend fun getStatsSummary(range: String): StatsSummaryDto {
            return StatsSummaryDto(
                totalFired = 0,
                totalDismissed = 0,
                totalSnoozed = 0,
                totalMissed = 0,
                repairedCount = 0,
                dismissRate = 0.0,
                snoozeRate = 0.0,
                streakDays = 0,
            )
        }

        override suspend fun getStatsTrends(range: String): List<StatsTrendPointDto> {
            return emptyList()
        }

        override suspend fun getOnboardingReadiness(): OnboardingReadinessDto {
            return OnboardingReadinessDto(
                exactAlarmReady = true,
                notificationsReady = true,
                channelsReady = true,
                batteryOptimizationRisk = "low",
                directBootReady = true,
                nativeRingPipelineEnabled = true,
                legacyFallbackDefaultEnabled = false,
            )
        }

        private fun samplePlan(id: Long, title: String): AlarmPlanDto {
            return AlarmPlanDto(
                alarmId = id,
                title = title,
                hour24 = 10L,
                minute = 0L,
                repeatDays = listOf("Fri"),
                enabled = true,
                sound = "Default Alarm",
                challenge = "None",
                snoozeCount = 3L,
                snoozeDuration = 5L,
                vibration = true,
                vibrationProfileId = null,
                escalationPolicy = null,
                nagPolicy = null,
                primaryAction = null,
                challengePolicy = null,
                anchorUtcMillis = 1_774_400_000_000L,
                timezoneId = "UTC",
                timezonePolicy = "FIXED_LOCAL_TIME",
                preReminderMinutes = listOf(60L),
                recurrenceType = null,
                recurrenceInterval = null,
                recurrenceWeekdays = emptyList(),
                recurrenceDayOfMonth = null,
                recurrenceOrdinal = null,
                recurrenceOrdinalWeekday = null,
                recurrenceExclusionDates = emptyList(),
                reminderOffsetsMinutes = listOf(60L),
                reminderBeforeOnly = false,
                createdAtUtcMillis = 100L,
                updatedAtUtcMillis = 100L,
                triggers = emptyList(),
            )
        }
    }
}
