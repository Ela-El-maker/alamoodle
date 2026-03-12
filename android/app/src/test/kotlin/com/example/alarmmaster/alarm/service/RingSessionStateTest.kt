package com.example.alarmmaster.alarm.service

import org.junit.Assert.assertEquals
import org.junit.Test

class RingSessionStateTest {
    @Test
    fun stateTransitions_areDeterministic() {
        var current = RingSessionState.IDLE
        current = RingSessionStateMachine.transition(current, "start")
        assertEquals(RingSessionState.RINGING, current)

        current = RingSessionStateMachine.transition(current, "snooze")
        assertEquals(RingSessionState.SNOOZED, current)

        val stable = RingSessionStateMachine.transition(current, "dismiss")
        assertEquals(RingSessionState.SNOOZED, stable)
    }
}
