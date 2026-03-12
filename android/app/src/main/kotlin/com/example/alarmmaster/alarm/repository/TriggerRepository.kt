package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.domain.TriggerInstance

interface TriggerRepository {
    suspend fun replaceForAlarm(alarmId: Long, triggers: List<TriggerInstance>)
    suspend fun getByAlarmId(alarmId: Long): List<TriggerInstance>
    suspend fun getFuture(fromUtcMillis: Long): List<TriggerInstance>
    suspend fun getByTriggerId(triggerId: String): TriggerInstance?
    suspend fun upsertTrigger(trigger: TriggerInstance)
    suspend fun updateStatus(triggerId: String, status: String)
    suspend fun clearForAlarm(alarmId: Long)
}
