package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.domain.AlarmPlan

interface AlarmRepository {
    suspend fun upsert(plan: AlarmPlan)
    suspend fun delete(alarmId: Long)
    suspend fun getById(alarmId: Long): AlarmPlan?
    suspend fun getAll(): List<AlarmPlan>
}
