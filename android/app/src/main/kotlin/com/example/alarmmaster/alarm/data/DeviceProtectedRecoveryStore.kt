package com.example.alarmmaster.alarm.data

import android.content.Context
import android.content.ContextWrapper

class DeviceProtectedRecoveryStore(context: Context) : RecoveryStateStore {
    private val deviceContext = if (context.isDeviceProtectedStorage) {
        context
    } else {
        ContextWrapper(context).createDeviceProtectedStorageContext()
    }

    private val delegate = RecoveryStore(deviceContext)

    override suspend fun setEnabledAlarmIds(ids: List<Long>) = delegate.setEnabledAlarmIds(ids)

    override suspend fun getEnabledAlarmIds(): List<Long> = delegate.getEnabledAlarmIds()

    override suspend fun setRecoveryIndex(entries: List<RecoveryIndexEntry>) = delegate.setRecoveryIndex(entries)

    override suspend fun getRecoveryIndex(): List<RecoveryIndexEntry> = delegate.getRecoveryIndex()

    override suspend fun setLastRecoveryState(state: LastRecoveryState) = delegate.setLastRecoveryState(state)

    override suspend fun getLastRecoveryState(): LastRecoveryState = delegate.getLastRecoveryState()
}
