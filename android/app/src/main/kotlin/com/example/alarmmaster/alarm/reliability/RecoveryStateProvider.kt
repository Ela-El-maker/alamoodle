package com.example.alarmmaster.alarm.reliability

import com.example.alarmmaster.alarm.data.LastRecoveryState

interface RecoveryStateProvider {
    suspend fun getLastRecoveryState(): LastRecoveryState
}
