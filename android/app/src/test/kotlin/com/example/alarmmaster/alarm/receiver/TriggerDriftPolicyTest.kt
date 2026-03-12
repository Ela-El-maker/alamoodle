package com.example.alarmmaster.alarm.receiver

import com.example.alarmmaster.alarm.domain.TriggerKind
import org.junit.Assert.assertEquals
import org.junit.Test

class TriggerDriftPolicyTest {
    @Test
    fun mainTrigger_ringsWithinGrace_ignoresAfterGrace() {
        assertEquals(
            DriftDecision.RING_NOW,
            TriggerDriftPolicy.decide(TriggerKind.MAIN, driftMs = 60_000L),
        )
        assertEquals(
            DriftDecision.IGNORE_TOO_LATE,
            TriggerDriftPolicy.decide(TriggerKind.MAIN, driftMs = 11 * 60 * 1000L),
        )
    }

    @Test
    fun preTrigger_hasWiderGraceWindow() {
        assertEquals(
            DriftDecision.RING_NOW,
            TriggerDriftPolicy.decide(TriggerKind.PRE, driftMs = 20 * 60 * 1000L),
        )
        assertEquals(
            DriftDecision.IGNORE_TOO_LATE,
            TriggerDriftPolicy.decide(TriggerKind.PRE, driftMs = 31 * 60 * 1000L),
        )
    }

    @Test
    fun negativeDrift_alwaysRings() {
        assertEquals(
            DriftDecision.RING_NOW,
            TriggerDriftPolicy.decide(TriggerKind.SNOOZE, driftMs = -500L),
        )
    }
}
