package com.example.alarmmaster.alarm.receiver

import com.example.alarmmaster.alarm.domain.TriggerKind

enum class DriftDecision {
    RING_NOW,
    IGNORE_TOO_LATE,
}

object TriggerDriftPolicy {
    private const val MAIN_GRACE_MS = 10 * 60 * 1000L
    private const val PRE_GRACE_MS = 30 * 60 * 1000L
    private const val SNOOZE_GRACE_MS = 10 * 60 * 1000L

    fun decide(kind: TriggerKind, driftMs: Long): DriftDecision {
        if (driftMs <= 0) return DriftDecision.RING_NOW
        val grace = when (kind) {
            TriggerKind.MAIN -> MAIN_GRACE_MS
            TriggerKind.PRE -> PRE_GRACE_MS
            TriggerKind.SNOOZE -> SNOOZE_GRACE_MS
        }
        return if (driftMs <= grace) DriftDecision.RING_NOW else DriftDecision.IGNORE_TOO_LATE
    }
}
