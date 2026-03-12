package com.example.alarmmaster.alarm.reliability

import com.example.alarmmaster.alarm.data.LastRecoveryState
import com.example.alarmmaster.alarm.data.RecoveryIndexEntry
import com.example.alarmmaster.alarm.data.RecoveryStateStore
import com.example.alarmmaster.alarm.diagnostics.EventLogger
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import com.example.alarmmaster.alarm.domain.TriggerStatus
import com.example.alarmmaster.alarm.receiver.DriftDecision
import com.example.alarmmaster.alarm.receiver.TriggerDriftPolicy
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.scheduler.AlarmScheduler
import com.example.alarmmaster.alarm.scheduler.ScheduleRepairer
import com.example.alarmmaster.alarm.scheduler.TriggerIdFactory
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.Instant
import java.time.ZoneId

class RecoveryCoordinator(
    private val alarmRepository: AlarmRepository,
    private val triggerRepository: TriggerRepository,
    private val historyRepository: HistoryRepository,
    private val alarmScheduler: AlarmScheduler,
    private val repairer: ScheduleRepairer,
    private val recoveryStore: RecoveryStateStore,
    private val triggerIdFactory: TriggerIdFactory,
    private val eventLogger: EventLogger,
) : RecoveryStateProvider {
    private val recoveryMutex = Mutex()

    suspend fun recover(reason: RecoveryReason, nowUtcMillis: Long = System.currentTimeMillis()): RecoveryResult {
        return recoveryMutex.withLock {
            val result = if (reason == RecoveryReason.LOCKED_BOOT_COMPLETED) {
                restoreFromDeviceProtectedIndex(reason, nowUtcMillis)
            } else {
                reconcileFromRoom(reason, nowUtcMillis)
            }

            recoveryStore.setLastRecoveryState(
                LastRecoveryState(
                    reason = reason.name,
                    status = result.status,
                    atUtcMillis = nowUtcMillis,
                ),
            )
            eventLogger.log(
                "RECOVERY_COMPLETED",
                "reason=${reason.name} status=${result.status} restored=${result.restoredTriggers} staleRemoved=${result.staleRemoved} failures=${result.failures}",
            )
            result
        }
    }

    suspend fun refreshRecoveryIndex(nowUtcMillis: Long = System.currentTimeMillis()) {
        val enabled = alarmRepository.getAll().filter { it.enabled }
        val enabledIds = enabled.map { it.alarmId }
        recoveryStore.setEnabledAlarmIds(enabledIds)

        val byAlarmId = enabled.associateBy { it.alarmId }
        val future = triggerRepository.getFuture(nowUtcMillis)
            .filter { byAlarmId[it.alarmId]?.enabled == true }

        recoveryStore.setRecoveryIndex(
            future.map {
                RecoveryIndexEntry(
                    alarmId = it.alarmId,
                    triggerId = it.triggerId,
                    kind = it.kind.name,
                    scheduledUtcMillis = it.scheduledUtcMillis,
                    requestCode = it.requestCode,
                    generation = it.generation,
                )
            },
        )
    }

    override suspend fun getLastRecoveryState(): LastRecoveryState = recoveryStore.getLastRecoveryState()

    private suspend fun restoreFromDeviceProtectedIndex(
        reason: RecoveryReason,
        nowUtcMillis: Long,
    ): RecoveryResult {
        val rawEntries = recoveryStore.getRecoveryIndex()
        val entries = rawEntries.filter { entry ->
            if (entry.scheduledUtcMillis > nowUtcMillis) {
                true
            } else {
                val kind = runCatching { TriggerKind.valueOf(entry.kind) }.getOrDefault(TriggerKind.MAIN)
                val driftMs = nowUtcMillis - entry.scheduledUtcMillis
                when (kind) {
                    TriggerKind.MAIN,
                    TriggerKind.SNOOZE,
                    -> TriggerDriftPolicy.decide(kind, driftMs) == DriftDecision.RING_NOW
                    TriggerKind.PRE -> false
                }
            }
        }
        val skippedTooLate = rawEntries.size - entries.size
        var restored = 0
        var failures = 0

        entries.forEach { entry ->
            runCatching {
                alarmScheduler.scheduleTrigger(entry.toTriggerInstance(nowUtcMillis))
            }.onSuccess {
                restored += 1
            }.onFailure {
                failures += 1
            }
        }

        return RecoveryResult(
            reason = reason,
            examinedAlarms = recoveryStore.getEnabledAlarmIds().size,
            restoredTriggers = restored,
            staleRemoved = skippedTooLate.coerceAtLeast(0),
            failures = failures,
            atRiskAlarms = if (failures > 0) 1 else 0,
            status = if (failures == 0) "ok" else "degraded",
            repaired = restored > 0,
        )
    }

    private suspend fun reconcileFromRoom(
        reason: RecoveryReason,
        nowUtcMillis: Long,
    ): RecoveryResult {
        val report = repairer.repairFutureScheduleDetailed(
            nowUtcMillis = nowUtcMillis,
            forceRescheduleAll = reason == RecoveryReason.STARTUP_SANITY,
        )
        val lateRecovery = recoverLateEligibleTriggers(reason, nowUtcMillis)
        refreshRecoveryIndex(nowUtcMillis)

        val eventType = when (reason) {
            RecoveryReason.BOOT_COMPLETED -> "RESTORED_AFTER_BOOT"
            RecoveryReason.TIMEZONE_CHANGED,
            RecoveryReason.TIME_SET,
            RecoveryReason.DATE_CHANGED,
            -> "RESTORED_AFTER_TIME_CHANGE"
            RecoveryReason.PACKAGE_REPLACED -> "RESTORED_AFTER_PACKAGE_REPLACED"
            RecoveryReason.STARTUP_SANITY,
            RecoveryReason.USER_UNLOCKED,
            RecoveryReason.LOCKED_BOOT_COMPLETED,
            -> "REPAIR_PERFORMED"
        }
        historyRepository.record(
            alarmId = 0,
            triggerId = "",
            eventType = eventType,
            meta = "reason=${reason.name} restored=${report.restored + lateRecovery.restored} staleRemoved=${report.staleRemoved} lateRestored=${lateRecovery.restored} failures=${lateRecovery.failures}",
        )

        val restoredTotal = report.restored + lateRecovery.restored
        val repaired = restoredTotal > 0 || report.staleRemoved > 0
        val failures = lateRecovery.failures
        return RecoveryResult(
            reason = reason,
            examinedAlarms = alarmRepository.getAll().size,
            restoredTriggers = restoredTotal,
            staleRemoved = report.staleRemoved,
            failures = failures,
            atRiskAlarms = if (failures > 0) lateRecovery.failedAlarmIds.size else 0,
            status = when {
                failures > 0 -> "degraded"
                repaired -> "repaired"
                else -> "ok"
            },
            repaired = repaired,
        )
    }

    private suspend fun recoverLateEligibleTriggers(
        reason: RecoveryReason,
        nowUtcMillis: Long,
    ): LateRecoveryReport {
        val enabledAlarmIds = alarmRepository.getAll()
            .asSequence()
            .filter { it.enabled }
            .map { it.alarmId }
            .toSet()

        var restored = 0
        var failures = 0
        val failedAlarmIds = mutableSetOf<Long>()

        enabledAlarmIds.forEach { alarmId ->
            val candidates = triggerRepository.getByAlarmId(alarmId)
                .asSequence()
                .filter { it.status == TriggerStatus.SCHEDULED }
                .filter { it.scheduledUtcMillis <= nowUtcMillis }
                .filter {
                    when (it.kind) {
                        TriggerKind.PRE -> false
                        TriggerKind.MAIN,
                        TriggerKind.SNOOZE,
                        -> TriggerDriftPolicy.decide(it.kind, nowUtcMillis - it.scheduledUtcMillis) == DriftDecision.RING_NOW
                    }
                }
                .toList()

            candidates.forEach { trigger ->
                try {
                    alarmScheduler.scheduleTrigger(trigger)
                    historyRepository.record(
                        alarmId = trigger.alarmId,
                        triggerId = trigger.triggerId,
                        eventType = "REPAIRED_LATE_TRIGGER",
                        meta = "reason=${reason.name} kind=${trigger.kind} driftMs=${nowUtcMillis - trigger.scheduledUtcMillis}",
                    )
                    restored += 1
                } catch (t: Throwable) {
                    failures += 1
                    failedAlarmIds += trigger.alarmId
                    historyRepository.record(
                        alarmId = trigger.alarmId,
                        triggerId = trigger.triggerId,
                        eventType = "REPAIR_FAILED",
                        meta = "reason=${reason.name} stage=late_recovery kind=${trigger.kind} error=${t.message ?: "unknown"}",
                    )
                }
            }
        }

        return LateRecoveryReport(
            restored = restored,
            failures = failures,
            failedAlarmIds = failedAlarmIds,
        )
    }

    private data class LateRecoveryReport(
        val restored: Int,
        val failures: Int,
        val failedAlarmIds: Set<Long>,
    )

    private fun RecoveryIndexEntry.toTriggerInstance(nowUtcMillis: Long): TriggerInstance {
        val resolvedKind = runCatching { TriggerKind.valueOf(kind) }.getOrDefault(TriggerKind.PRE)
        val localIso = Instant.ofEpochMilli(scheduledUtcMillis)
            .atZone(ZoneId.systemDefault())
            .toLocalDateTime()
            .toString()

        val resolvedRequestCode = if (requestCode > 0) {
            requestCode
        } else {
            triggerIdFactory.buildRequestCode(
                alarmId = alarmId,
                kind = resolvedKind,
                index = (nowUtcMillis % 1000L).toInt(),
                generation = generation,
            )
        }

        return TriggerInstance(
            triggerId = triggerId,
            alarmId = alarmId,
            kind = resolvedKind,
            scheduledLocalIso = localIso,
            scheduledUtcMillis = scheduledUtcMillis,
            requestCode = resolvedRequestCode,
            status = TriggerStatus.SCHEDULED,
            generation = generation,
        )
    }
}
