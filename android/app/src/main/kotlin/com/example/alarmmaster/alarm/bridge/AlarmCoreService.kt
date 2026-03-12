package com.example.alarmmaster.alarm.bridge

import android.content.Context
import android.content.pm.ApplicationInfo
import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.core.AlarmRuntime
import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TimezonePolicy
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.TemplateRepository
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.scheduler.AlarmPlanner
import com.example.alarmmaster.alarm.scheduler.AlarmScheduler
import com.example.alarmmaster.bridge.gen.AlarmHistoryDto
import com.example.alarmmaster.bridge.gen.AlarmPlanDto
import com.example.alarmmaster.bridge.gen.BackupImportResultDto
import com.example.alarmmaster.bridge.gen.CreateAlarmCommandDto
import com.example.alarmmaster.bridge.gen.OemGuidanceDto
import com.example.alarmmaster.bridge.gen.ReliabilitySnapshotDto
import com.example.alarmmaster.bridge.gen.SoundProfileDto
import com.example.alarmmaster.bridge.gen.StatsSummaryDto
import com.example.alarmmaster.bridge.gen.StatsTrendPointDto
import com.example.alarmmaster.bridge.gen.TemplateDto
import com.example.alarmmaster.bridge.gen.TestAlarmResultDto
import com.example.alarmmaster.bridge.gen.OnboardingReadinessDto
import com.example.alarmmaster.bridge.gen.TriggerDto
import com.example.alarmmaster.bridge.gen.UpdateAlarmCommandDto

data class QaScheduleRegistryEntry(
    val triggerId: String,
    val alarmId: Long,
    val requestCode: Int,
    val scheduledUtcMillis: Long,
    val active: Boolean,
)

class AlarmCoreService(context: Context) : AlarmCoreGateway {
    private val appContext = context.applicationContext
    private val runtime = AlarmRuntime.get(appContext)

    private val alarmRepository: AlarmRepository = runtime.alarmRepository
    private val triggerRepository: TriggerRepository = runtime.triggerRepository
    private val historyRepository: HistoryRepository = runtime.historyRepository
    private val templateRepository: TemplateRepository = runtime.templateRepository

    private val planner: AlarmPlanner = runtime.planner
    private val alarmScheduler: AlarmScheduler = runtime.alarmScheduler
    private val repairer = runtime.repairer
    private val recoveryCoordinator = runtime.recoveryCoordinator
    private val backupExporter = runtime.backupExporter
    private val backupImporter = runtime.backupImporter

    init {
        runtime.ensureChannels()
    }

    override suspend fun createAlarm(command: CreateAlarmCommandDto): AlarmPlanDto {
        val now = System.currentTimeMillis()
        val alarmId = command.alarmId ?: now
        val existing = alarmRepository.getById(alarmId)

        val plan = command.toDomain(
            alarmId = alarmId,
            createdAt = existing?.createdAtUtcMillis ?: now,
            updatedAt = now,
        )

        alarmRepository.upsert(plan)
        val triggers = replanAndSchedule(plan)
        historyRepository.record(plan.alarmId, "", "CREATED", "triggerCount=${triggers.size}")
        updateRecoveryIndex()
        return plan.toDto(triggers)
    }

    override suspend fun updateAlarm(command: UpdateAlarmCommandDto): AlarmPlanDto {
        val now = System.currentTimeMillis()
        val existing = alarmRepository.getById(command.alarmId)
            ?: throw IllegalArgumentException("Alarm not found: ${command.alarmId}")

        val plan = command.toDomain(
            createdAt = existing.createdAtUtcMillis,
            updatedAt = now,
        )

        alarmRepository.upsert(plan)
        val triggers = replanAndSchedule(plan)
        historyRepository.record(plan.alarmId, "", "UPDATED", "triggerCount=${triggers.size}")
        updateRecoveryIndex()
        return plan.toDto(triggers)
    }

    override suspend fun deleteAlarm(alarmId: Long) {
        val existingTriggers = triggerRepository.getByAlarmId(alarmId)
        alarmScheduler.cancelAllForAlarm(alarmId, existingTriggers)
        triggerRepository.clearForAlarm(alarmId)
        alarmRepository.delete(alarmId)
        historyRepository.record(alarmId, "", "DELETED", "")
        updateRecoveryIndex()
    }

    override suspend fun enableAlarm(alarmId: Long): AlarmPlanDto {
        val existing = alarmRepository.getById(alarmId)
            ?: throw IllegalArgumentException("Alarm not found: $alarmId")
        val updated = existing.copy(enabled = true, updatedAtUtcMillis = System.currentTimeMillis())
        alarmRepository.upsert(updated)
        val triggers = replanAndSchedule(updated)
        ensureEnabledAlarmHasFutureTriggers(updated, triggers, "ENABLE_REJECTED_NO_FUTURE_TRIGGERS")
        historyRepository.record(alarmId, "", "ENABLED", "triggerCount=${triggers.size}")
        updateRecoveryIndex()
        return updated.toDto(triggers)
    }

    override suspend fun disableAlarm(alarmId: Long): AlarmPlanDto {
        val existing = alarmRepository.getById(alarmId)
            ?: throw IllegalArgumentException("Alarm not found: $alarmId")
        val updated = existing.copy(enabled = false, updatedAtUtcMillis = System.currentTimeMillis())
        alarmRepository.upsert(updated)
        val triggers = replanAndSchedule(updated)
        historyRepository.record(alarmId, "", "DISABLED", "")
        updateRecoveryIndex()
        return updated.toDto(triggers)
    }

    override suspend fun getUpcomingAlarms(): List<AlarmPlanDto> {
        return alarmRepository.getAll().map { plan ->
            val triggers = triggerRepository.getByAlarmId(plan.alarmId)
            plan.toDto(triggers)
        }
    }

    override suspend fun getAlarmDetail(alarmId: Long): AlarmPlanDto? {
        val plan = alarmRepository.getById(alarmId) ?: return null
        val triggers = triggerRepository.getByAlarmId(alarmId)
        return plan.toDto(triggers)
    }

    override suspend fun getAlarmHistory(alarmId: Long): List<AlarmHistoryDto> {
        return historyRepository.getByAlarmId(alarmId).map {
            AlarmHistoryDto(
                historyId = it.historyId,
                alarmId = it.alarmId,
                triggerId = it.triggerId,
                eventType = it.eventType,
                occurredAtUtcMillis = it.occurredAtUtcMillis,
                meta = it.meta,
            )
        }
    }

    override suspend fun getReliabilitySnapshot(): ReliabilitySnapshotDto {
        val snapshot = runtime.reliabilityChecker.snapshot(engineMode = AlarmRuntimePolicy.ENGINE_MODE)
        return ReliabilitySnapshotDto(
            exactAlarmPermissionGranted = snapshot.exactAlarmPermissionGranted,
            notificationsPermissionGranted = snapshot.notificationsPermissionGranted,
            canScheduleExactAlarms = snapshot.canScheduleExactAlarms,
            engineMode = snapshot.engineMode,
            schedulerHealth = snapshot.schedulerHealth,
            nativeRingPipelineEnabled = snapshot.nativeRingPipelineEnabled,
            legacyEmergencyRingFallbackEnabled = snapshot.legacyEmergencyRingFallbackEnabled,
            directBootReady = snapshot.directBootReady,
            channelHealth = snapshot.channelHealth,
            fullScreenReady = snapshot.fullScreenReady,
            batteryOptimizationRisk = snapshot.batteryOptimizationRisk,
            scheduleRegistryHealth = snapshot.scheduleRegistryHealth,
            lastRecoveryReason = snapshot.lastRecoveryReason,
            lastRecoveryAtUtcMillis = snapshot.lastRecoveryAtUtcMillis,
            lastRecoveryStatus = snapshot.lastRecoveryStatus,
            legacyFallbackDefaultEnabled = snapshot.legacyFallbackDefaultEnabled,
        )
    }

    override suspend fun getRecentHistory(limit: Long, alarmId: Long?): List<AlarmHistoryDto> {
        val safeLimit = limit.coerceIn(1L, 200L).toInt()
        return runtime.historyReadService.getRecent(safeLimit, alarmId).map {
            AlarmHistoryDto(
                historyId = it.historyId,
                alarmId = it.alarmId,
                triggerId = it.triggerId,
                eventType = it.eventType,
                occurredAtUtcMillis = it.occurredAtUtcMillis,
                meta = it.meta,
            )
        }
    }

    override suspend fun exportDiagnostics(): String {
        val lastRecovery = recoveryCoordinator.getLastRecoveryState()
        return runtime.diagnosticsExporter.export(lastRecovery)
    }

    override suspend fun runTestAlarm(): TestAlarmResultDto {
        val result = runtime.testAlarmRunner.run()
        return TestAlarmResultDto(
            success = result.success,
            message = result.message,
            scheduledAtUtcMillis = result.scheduledAtUtcMillis,
        )
    }

    override suspend fun openSystemSettings(target: String): Boolean {
        return runtime.settingsNavigator.open(target)
    }

    override suspend fun getSoundCatalog(): List<SoundProfileDto> {
        return runtime.soundCatalogRepository.getSoundProfiles().map {
            SoundProfileDto(
                id = it.id,
                name = it.name,
                tag = it.tag,
                category = it.category,
                vibrationProfileIds = it.vibrationProfileIds,
            )
        }
    }

    override suspend fun previewSound(soundId: String): Boolean {
        return runtime.previewAudioController.startPreview(soundId)
    }

    override suspend fun stopSoundPreview(): Boolean {
        runtime.previewAudioController.stop()
        return true
    }

    override suspend fun getTemplates(): List<TemplateDto> {
        ensureBuiltInTemplates()
        return templateRepository.getAll().map { it.toDto() }
    }

    override suspend fun saveTemplate(template: TemplateDto): TemplateDto {
        val saved = templateRepository.upsert(template.toDomain())
        return saved.toDto()
    }

    override suspend fun deleteTemplate(templateId: Long) {
        templateRepository.delete(templateId)
    }

    override suspend fun applyTemplate(templateId: Long): TemplateDto? {
        return templateRepository.getById(templateId)?.toDto()
    }

    override suspend fun exportBackup(): String {
        return backupExporter.exportJson()
    }

    override suspend fun importBackup(payload: String): BackupImportResultDto {
        val result = backupImporter.importJson(payload = payload, replaceExisting = true)
        val repaired = repairer.repairFutureScheduleDetailed()
        updateRecoveryIndex()
        historyRepository.record(
            alarmId = 0,
            triggerId = "",
            eventType = "REPAIR_PERFORMED",
            meta = "reason=BACKUP_IMPORT restored=${repaired.restored} staleRemoved=${repaired.staleRemoved}",
        )
        return BackupImportResultDto(
            success = result.success,
            message = result.message,
            restoredAlarms = result.restoredAlarms.toLong(),
            restoredTemplates = result.restoredTemplates.toLong(),
        )
    }

    override suspend fun getOemGuidance(): OemGuidanceDto {
        val snapshot = runtime.reliabilityChecker.snapshot(engineMode = AlarmRuntimePolicy.ENGINE_MODE)
        val guidance = runtime.oemGuidanceProvider.getGuidance(
            schedulerHealth = snapshot.schedulerHealth,
            batteryOptimizationRisk = snapshot.batteryOptimizationRisk,
        )
        return OemGuidanceDto(
            manufacturer = guidance.manufacturer,
            title = guidance.title,
            summary = guidance.summary,
            steps = guidance.steps,
            settingsTargets = guidance.settingsTargets,
        )
    }

    override suspend fun previewPlannedTriggers(command: CreateAlarmCommandDto): List<TriggerDto> {
        val now = System.currentTimeMillis()
        val alarmId = command.alarmId ?: now
        val plan = command.toDomain(
            alarmId = alarmId,
            createdAt = now,
            updatedAt = now,
        )
        val generation = ((plan.updatedAtUtcMillis / 1000L) % 100_000L).toInt()
        return planner.planTriggers(plan, generation).map {
            TriggerDto(
                triggerId = it.triggerId,
                alarmId = it.alarmId,
                kind = it.kind.name,
                scheduledLocalIso = it.scheduledLocalIso,
                scheduledUtcMillis = it.scheduledUtcMillis,
                requestCode = it.requestCode.toLong(),
                status = it.status.name,
                generation = it.generation.toLong(),
            )
        }
    }

    override suspend fun getStatsSummary(range: String): StatsSummaryDto {
        val stats = runtime.statsAggregationService.getSummary(range)
        return StatsSummaryDto(
            totalFired = stats.totalFired.toLong(),
            totalDismissed = stats.totalDismissed.toLong(),
            totalSnoozed = stats.totalSnoozed.toLong(),
            totalMissed = stats.totalMissed.toLong(),
            repairedCount = stats.repairedCount.toLong(),
            dismissRate = stats.dismissRate,
            snoozeRate = stats.snoozeRate,
            streakDays = stats.streakDays.toLong(),
        )
    }

    override suspend fun getStatsTrends(range: String): List<StatsTrendPointDto> {
        return runtime.statsAggregationService.getTrends(range).map {
            StatsTrendPointDto(
                dayUtcStartMillis = it.dayUtcStartMillis,
                fired = it.fired.toLong(),
                dismissed = it.dismissed.toLong(),
                snoozed = it.snoozed.toLong(),
                missed = it.missed.toLong(),
                repaired = it.repaired.toLong(),
            )
        }
    }

    override suspend fun getOnboardingReadiness(): OnboardingReadinessDto {
        val snapshot = runtime.reliabilityChecker.snapshot(engineMode = AlarmRuntimePolicy.ENGINE_MODE)
        return OnboardingReadinessDto(
            exactAlarmReady = snapshot.canScheduleExactAlarms,
            notificationsReady = snapshot.notificationsPermissionGranted,
            channelsReady = snapshot.channelHealth == "healthy",
            batteryOptimizationRisk = snapshot.batteryOptimizationRisk,
            directBootReady = snapshot.directBootReady,
            nativeRingPipelineEnabled = snapshot.nativeRingPipelineEnabled,
            legacyFallbackDefaultEnabled = snapshot.legacyFallbackDefaultEnabled,
        )
    }

    suspend fun repairSchedule(): Int {
        return repairer.repairFutureScheduleDetailed().restored
    }

    /**
     * Debug/test-only hook: list persisted future triggers from native storage.
     */
    suspend fun debugListFutureTriggers(
        nowUtcMillis: Long = System.currentTimeMillis(),
    ): List<TriggerDto> {
        ensureDebugBuild()
        return triggerRepository.getFuture(nowUtcMillis).map {
            TriggerDto(
                triggerId = it.triggerId,
                alarmId = it.alarmId,
                kind = it.kind.name,
                scheduledLocalIso = it.scheduledLocalIso,
                scheduledUtcMillis = it.scheduledUtcMillis,
                requestCode = it.requestCode.toLong(),
                status = it.status.name,
                generation = it.generation.toLong(),
            )
        }
    }

    /**
     * Debug/test-only hook: list all triggers for a specific alarm (scheduled and historical states).
     */
    suspend fun debugGetAlarmTriggerCheckpoints(alarmId: Long): List<TriggerDto> {
        ensureDebugBuild()
        return triggerRepository.getByAlarmId(alarmId).map {
            TriggerDto(
                triggerId = it.triggerId,
                alarmId = it.alarmId,
                kind = it.kind.name,
                scheduledLocalIso = it.scheduledLocalIso,
                scheduledUtcMillis = it.scheduledUtcMillis,
                requestCode = it.requestCode.toLong(),
                status = it.status.name,
                generation = it.generation.toLong(),
            )
        }.sortedBy { it.scheduledUtcMillis }
    }

    /**
     * Debug/test-only hook: list active scheduler registry rows.
     */
    suspend fun debugListScheduleRegistry(): List<QaScheduleRegistryEntry> {
        ensureDebugBuild()
        return runtime.database.scheduleRegistryDao().getActive().map {
            QaScheduleRegistryEntry(
                triggerId = it.triggerId,
                alarmId = it.alarmId,
                requestCode = it.requestCode,
                scheduledUtcMillis = it.scheduledUtcMillis,
                active = it.active,
            )
        }
    }

    /**
     * Debug/test-only hook: simulate missing scheduler registry entry while keeping trigger row.
     */
    suspend fun debugCorruptSchedule(triggerId: String): Boolean {
        ensureDebugBuild()
        val dao = runtime.database.scheduleRegistryDao()
        val existed = dao.getActiveByTriggerId(triggerId) != null
        dao.deleteByTriggerId(triggerId)
        return existed
    }

    /**
     * Debug/test-only hook: inject a stale active registry row.
     */
    suspend fun debugInsertStaleScheduleRegistryEntry(
        triggerId: String,
        alarmId: Long,
        requestCode: Int,
        scheduledUtcMillis: Long,
    ) {
        ensureDebugBuild()
        runtime.database.scheduleRegistryDao().upsert(
            com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity(
                triggerId = triggerId,
                alarmId = alarmId,
                requestCode = requestCode,
                scheduledUtcMillis = scheduledUtcMillis,
                active = true,
            ),
        )
    }

    /**
     * Debug/test-only hook: execute startup sanity recovery deterministically from tests.
     */
    suspend fun debugRunStartupSanity(): String {
        ensureDebugBuild()
        return runtime.startupSanityChecker.run().status
    }

    /**
     * Debug/test-only hook: run a specific recovery reason deterministically.
     */
    suspend fun debugRunRecovery(reason: String): String {
        ensureDebugBuild()
        val parsed = runCatching {
            com.example.alarmmaster.alarm.reliability.RecoveryReason.valueOf(reason)
        }.getOrElse {
            throw IllegalArgumentException("Unknown recovery reason: $reason")
        }
        return recoveryCoordinator.recover(parsed).status
    }

    private suspend fun replanAndSchedule(plan: AlarmPlan): List<com.example.alarmmaster.alarm.domain.TriggerInstance> {
        val existingTriggers = triggerRepository.getByAlarmId(plan.alarmId)
        alarmScheduler.cancelAllForAlarm(plan.alarmId, existingTriggers)

        val generation = ((plan.updatedAtUtcMillis / 1000L) % 100_000L).toInt()
        val plannedTriggers = if (plan.enabled) {
            planner.planTriggers(plan, generation)
        } else {
            emptyList()
        }

        triggerRepository.replaceForAlarm(plan.alarmId, plannedTriggers)
        alarmScheduler.scheduleAll(plannedTriggers)
        return plannedTriggers
    }

    private suspend fun ensureEnabledAlarmHasFutureTriggers(
        plan: AlarmPlan,
        triggers: List<com.example.alarmmaster.alarm.domain.TriggerInstance>,
        eventType: String,
    ) {
        if (!plan.enabled || triggers.isNotEmpty()) return

        val reverted = plan.copy(enabled = false, updatedAtUtcMillis = System.currentTimeMillis())
        alarmRepository.upsert(reverted)
        historyRepository.record(
            alarmId = plan.alarmId,
            triggerId = "",
            eventType = eventType,
            meta = "reason=no_future_triggers requestedEnabled=true",
        )
        updateRecoveryIndex()
        throw IllegalStateException("No future triggers available for alarm ${plan.alarmId}")
    }

    private suspend fun updateRecoveryIndex() {
        recoveryCoordinator.refreshRecoveryIndex()
    }

    private fun ensureDebugBuild() {
        val debug = (appContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        check(debug) { "Debug QA hooks are only available in debug builds." }
    }

    private fun CreateAlarmCommandDto.toDomain(
        alarmId: Long,
        createdAt: Long,
        updatedAt: Long,
    ): AlarmPlan {
        return AlarmPlan(
            alarmId = alarmId,
            title = title,
            hour24 = hour24.toInt(),
            minute = minute.toInt(),
            repeatDays = repeatDays,
            enabled = enabled,
            sound = sound,
            challenge = challenge,
            snoozeCount = snoozeCount.toInt(),
            snoozeDuration = snoozeDuration.toInt(),
            vibration = vibration,
            vibrationProfileId = vibrationProfileId,
            escalationPolicy = escalationPolicy,
            nagPolicy = nagPolicy,
            primaryAction = primaryAction,
            challengePolicy = challengePolicy,
            anchorUtcMillis = anchorUtcMillis,
            timezoneId = timezoneId,
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = preReminderMinutes.map { it.toInt() },
            recurrenceType = recurrenceType,
            recurrenceInterval = recurrenceInterval?.toInt(),
            recurrenceWeekdays = recurrenceWeekdays.map { it.toInt() },
            recurrenceDayOfMonth = recurrenceDayOfMonth?.toInt(),
            recurrenceOrdinal = recurrenceOrdinal?.toInt(),
            recurrenceOrdinalWeekday = recurrenceOrdinalWeekday?.toInt(),
            recurrenceExclusionDates = recurrenceExclusionDates,
            reminderOffsetsMinutes = reminderOffsetsMinutes.map { it.toInt() },
            reminderBeforeOnly = reminderBeforeOnly,
            createdAtUtcMillis = createdAt,
            updatedAtUtcMillis = updatedAt,
        )
    }

    private fun UpdateAlarmCommandDto.toDomain(
        createdAt: Long,
        updatedAt: Long,
    ): AlarmPlan {
        return AlarmPlan(
            alarmId = alarmId,
            title = title,
            hour24 = hour24.toInt(),
            minute = minute.toInt(),
            repeatDays = repeatDays,
            enabled = enabled,
            sound = sound,
            challenge = challenge,
            snoozeCount = snoozeCount.toInt(),
            snoozeDuration = snoozeDuration.toInt(),
            vibration = vibration,
            vibrationProfileId = vibrationProfileId,
            escalationPolicy = escalationPolicy,
            nagPolicy = nagPolicy,
            primaryAction = primaryAction,
            challengePolicy = challengePolicy,
            anchorUtcMillis = anchorUtcMillis,
            timezoneId = timezoneId,
            timezonePolicy = TimezonePolicy.FIXED_LOCAL_TIME,
            preReminderMinutes = preReminderMinutes.map { it.toInt() },
            recurrenceType = recurrenceType,
            recurrenceInterval = recurrenceInterval?.toInt(),
            recurrenceWeekdays = recurrenceWeekdays.map { it.toInt() },
            recurrenceDayOfMonth = recurrenceDayOfMonth?.toInt(),
            recurrenceOrdinal = recurrenceOrdinal?.toInt(),
            recurrenceOrdinalWeekday = recurrenceOrdinalWeekday?.toInt(),
            recurrenceExclusionDates = recurrenceExclusionDates,
            reminderOffsetsMinutes = reminderOffsetsMinutes.map { it.toInt() },
            reminderBeforeOnly = reminderBeforeOnly,
            createdAtUtcMillis = createdAt,
            updatedAtUtcMillis = updatedAt,
        )
    }

    private fun AlarmPlan.toDto(triggers: List<com.example.alarmmaster.alarm.domain.TriggerInstance>): AlarmPlanDto {
        return AlarmPlanDto(
            alarmId = alarmId,
            title = title,
            hour24 = hour24.toLong(),
            minute = minute.toLong(),
            repeatDays = repeatDays,
            enabled = enabled,
            sound = sound,
            challenge = challenge,
            snoozeCount = snoozeCount.toLong(),
            snoozeDuration = snoozeDuration.toLong(),
            vibration = vibration,
            vibrationProfileId = vibrationProfileId,
            escalationPolicy = escalationPolicy,
            nagPolicy = nagPolicy,
            primaryAction = primaryAction,
            challengePolicy = challengePolicy,
            anchorUtcMillis = anchorUtcMillis,
            timezoneId = timezoneId,
            timezonePolicy = timezonePolicy.name,
            preReminderMinutes = preReminderMinutes.map { it.toLong() },
            recurrenceType = recurrenceType,
            recurrenceInterval = recurrenceInterval?.toLong(),
            recurrenceWeekdays = recurrenceWeekdays.map { it.toLong() },
            recurrenceDayOfMonth = recurrenceDayOfMonth?.toLong(),
            recurrenceOrdinal = recurrenceOrdinal?.toLong(),
            recurrenceOrdinalWeekday = recurrenceOrdinalWeekday?.toLong(),
            recurrenceExclusionDates = recurrenceExclusionDates,
            reminderOffsetsMinutes = reminderOffsetsMinutes.map { it.toLong() },
            reminderBeforeOnly = reminderBeforeOnly,
            createdAtUtcMillis = createdAtUtcMillis,
            updatedAtUtcMillis = updatedAtUtcMillis,
            triggers = triggers.map {
                TriggerDto(
                    triggerId = it.triggerId,
                    alarmId = it.alarmId,
                    kind = it.kind.name,
                    scheduledLocalIso = it.scheduledLocalIso,
                    scheduledUtcMillis = it.scheduledUtcMillis,
                    requestCode = it.requestCode.toLong(),
                    status = it.status.name,
                    generation = it.generation.toLong(),
                )
            },
        )
    }

    private suspend fun ensureBuiltInTemplates() {
        if (templateRepository.getAll().isNotEmpty()) return

        val defaults = listOf(
            com.example.alarmmaster.alarm.domain.AlarmTemplate(
                templateId = 0,
                name = "Meeting Reminder",
                title = "Meeting",
                hour24 = 9,
                minute = 0,
                repeatDays = listOf("Mon", "Tue", "Wed", "Thu", "Fri"),
                sound = "Default Alarm",
                vibration = true,
                vibrationProfileId = "default",
                escalationPolicy = "gentle",
                nagPolicy = null,
                primaryAction = null,
                challenge = "None",
                challengePolicy = null,
                snoozeCount = 3,
                snoozeDuration = 5,
                recurrenceType = "WEEKDAYS",
                recurrenceInterval = 1,
                recurrenceWeekdays = listOf(1, 2, 3, 4, 5),
                recurrenceDayOfMonth = null,
                recurrenceOrdinal = null,
                recurrenceOrdinalWeekday = null,
                recurrenceExclusionDates = emptyList(),
                reminderOffsetsMinutes = listOf(60),
                reminderBeforeOnly = false,
                timezonePolicy = "FIXED_LOCAL_TIME",
            ),
            com.example.alarmmaster.alarm.domain.AlarmTemplate(
                templateId = 0,
                name = "Exam Wake-up",
                title = "Exam Day",
                hour24 = 6,
                minute = 0,
                repeatDays = emptyList(),
                sound = "Classic Bell",
                vibration = true,
                vibrationProfileId = "default",
                escalationPolicy = "strong",
                nagPolicy = "short_retry",
                primaryAction = null,
                challenge = "Math Puzzle",
                challengePolicy = "required",
                snoozeCount = 1,
                snoozeDuration = 5,
                recurrenceType = null,
                recurrenceInterval = null,
                recurrenceWeekdays = emptyList(),
                recurrenceDayOfMonth = null,
                recurrenceOrdinal = null,
                recurrenceOrdinalWeekday = null,
                recurrenceExclusionDates = emptyList(),
                reminderOffsetsMinutes = listOf(1440, 60),
                reminderBeforeOnly = false,
                timezonePolicy = "FIXED_LOCAL_TIME",
            ),
            com.example.alarmmaster.alarm.domain.AlarmTemplate(
                templateId = 0,
                name = "Medication Reminder",
                title = "Medication",
                hour24 = 8,
                minute = 0,
                repeatDays = listOf("Daily"),
                sound = "Soft Chime",
                vibration = true,
                vibrationProfileId = "short",
                escalationPolicy = "gentle",
                nagPolicy = null,
                primaryAction = null,
                challenge = "None",
                challengePolicy = null,
                snoozeCount = 2,
                snoozeDuration = 10,
                recurrenceType = "DAILY",
                recurrenceInterval = 1,
                recurrenceWeekdays = emptyList(),
                recurrenceDayOfMonth = null,
                recurrenceOrdinal = null,
                recurrenceOrdinalWeekday = null,
                recurrenceExclusionDates = emptyList(),
                reminderOffsetsMinutes = emptyList(),
                reminderBeforeOnly = false,
                timezonePolicy = "FIXED_LOCAL_TIME",
            ),
            com.example.alarmmaster.alarm.domain.AlarmTemplate(
                templateId = 0,
                name = "Travel Departure",
                title = "Travel",
                hour24 = 7,
                minute = 30,
                repeatDays = emptyList(),
                sound = "Default Alarm",
                vibration = true,
                vibrationProfileId = "default",
                escalationPolicy = "strong",
                nagPolicy = null,
                primaryAction = "OPEN_MAP",
                challenge = "None",
                challengePolicy = null,
                snoozeCount = 2,
                snoozeDuration = 10,
                recurrenceType = null,
                recurrenceInterval = null,
                recurrenceWeekdays = emptyList(),
                recurrenceDayOfMonth = null,
                recurrenceOrdinal = null,
                recurrenceOrdinalWeekday = null,
                recurrenceExclusionDates = emptyList(),
                reminderOffsetsMinutes = listOf(10080, 1440, 60),
                reminderBeforeOnly = false,
                timezonePolicy = "FIXED_LOCAL_TIME",
            ),
            com.example.alarmmaster.alarm.domain.AlarmTemplate(
                templateId = 0,
                name = "Deep Sleep Challenge",
                title = "Wake Up",
                hour24 = 5,
                minute = 45,
                repeatDays = listOf("Mon", "Tue", "Wed", "Thu", "Fri"),
                sound = "Classic Bell",
                vibration = true,
                vibrationProfileId = "intense",
                escalationPolicy = "strong",
                nagPolicy = "retry_15",
                primaryAction = null,
                challenge = "Memory Tiles",
                challengePolicy = "required",
                snoozeCount = 0,
                snoozeDuration = 5,
                recurrenceType = "WEEKDAYS",
                recurrenceInterval = 1,
                recurrenceWeekdays = listOf(1, 2, 3, 4, 5),
                recurrenceDayOfMonth = null,
                recurrenceOrdinal = null,
                recurrenceOrdinalWeekday = null,
                recurrenceExclusionDates = emptyList(),
                reminderOffsetsMinutes = emptyList(),
                reminderBeforeOnly = false,
                timezonePolicy = "FIXED_LOCAL_TIME",
            ),
        )

        defaults.forEach { templateRepository.upsert(it) }
    }

    private fun TemplateDto.toDomain(): com.example.alarmmaster.alarm.domain.AlarmTemplate {
        return com.example.alarmmaster.alarm.domain.AlarmTemplate(
            templateId = templateId,
            name = name,
            title = title,
            hour24 = hour24.toInt(),
            minute = minute.toInt(),
            repeatDays = repeatDays,
            sound = sound,
            vibration = vibration,
            vibrationProfileId = vibrationProfileId,
            escalationPolicy = escalationPolicy,
            nagPolicy = nagPolicy,
            primaryAction = primaryAction,
            challenge = challenge,
            challengePolicy = challengePolicy,
            snoozeCount = snoozeCount.toInt(),
            snoozeDuration = snoozeDuration.toInt(),
            recurrenceType = recurrenceType,
            recurrenceInterval = recurrenceInterval?.toInt(),
            recurrenceWeekdays = recurrenceWeekdays.map { it.toInt() },
            recurrenceDayOfMonth = recurrenceDayOfMonth?.toInt(),
            recurrenceOrdinal = recurrenceOrdinal?.toInt(),
            recurrenceOrdinalWeekday = recurrenceOrdinalWeekday?.toInt(),
            recurrenceExclusionDates = recurrenceExclusionDates,
            reminderOffsetsMinutes = reminderOffsetsMinutes.map { it.toInt() },
            reminderBeforeOnly = reminderBeforeOnly,
            timezonePolicy = timezonePolicy,
        )
    }

    private fun com.example.alarmmaster.alarm.domain.AlarmTemplate.toDto(): TemplateDto {
        return TemplateDto(
            templateId = templateId,
            name = name,
            title = title,
            hour24 = hour24.toLong(),
            minute = minute.toLong(),
            repeatDays = repeatDays,
            sound = sound,
            vibration = vibration,
            vibrationProfileId = vibrationProfileId,
            escalationPolicy = escalationPolicy,
            nagPolicy = nagPolicy,
            primaryAction = primaryAction,
            challenge = challenge,
            challengePolicy = challengePolicy,
            snoozeCount = snoozeCount.toLong(),
            snoozeDuration = snoozeDuration.toLong(),
            recurrenceType = recurrenceType,
            recurrenceInterval = recurrenceInterval?.toLong(),
            recurrenceWeekdays = recurrenceWeekdays.map { it.toLong() },
            recurrenceDayOfMonth = recurrenceDayOfMonth?.toLong(),
            recurrenceOrdinal = recurrenceOrdinal?.toLong(),
            recurrenceOrdinalWeekday = recurrenceOrdinalWeekday?.toLong(),
            recurrenceExclusionDates = recurrenceExclusionDates,
            reminderOffsetsMinutes = reminderOffsetsMinutes.map { it.toLong() },
            reminderBeforeOnly = reminderBeforeOnly,
            timezonePolicy = timezonePolicy,
        )
    }
}
