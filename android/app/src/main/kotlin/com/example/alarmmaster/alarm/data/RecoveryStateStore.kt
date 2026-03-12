package com.example.alarmmaster.alarm.data

interface RecoveryStateStore {
    suspend fun setEnabledAlarmIds(ids: List<Long>)
    suspend fun getEnabledAlarmIds(): List<Long>
    suspend fun setRecoveryIndex(entries: List<RecoveryIndexEntry>)
    suspend fun getRecoveryIndex(): List<RecoveryIndexEntry>
    suspend fun setLastRecoveryState(state: LastRecoveryState)
    suspend fun getLastRecoveryState(): LastRecoveryState
}
