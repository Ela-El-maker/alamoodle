package com.example.alarmmaster.alarm.service

enum class RingSessionState {
    IDLE,
    RINGING,
    DISMISSED,
    SNOOZED,
    ACTIONED,
}

object RingSessionStateMachine {
    fun transition(current: RingSessionState, event: String): RingSessionState {
        return when (current) {
            RingSessionState.IDLE -> if (event == "start") RingSessionState.RINGING else RingSessionState.IDLE
            RingSessionState.RINGING -> when (event) {
                "dismiss" -> RingSessionState.DISMISSED
                "snooze" -> RingSessionState.SNOOZED
                "primary" -> RingSessionState.ACTIONED
                else -> RingSessionState.RINGING
            }
            RingSessionState.DISMISSED,
            RingSessionState.SNOOZED,
            RingSessionState.ACTIONED,
            -> current
        }
    }
}
