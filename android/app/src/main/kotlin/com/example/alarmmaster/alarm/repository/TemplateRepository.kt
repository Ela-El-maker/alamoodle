package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.domain.AlarmTemplate

interface TemplateRepository {
    suspend fun getAll(): List<AlarmTemplate>
    suspend fun getById(templateId: Long): AlarmTemplate?
    suspend fun upsert(template: AlarmTemplate): AlarmTemplate
    suspend fun delete(templateId: Long)
    suspend fun clearAll()
}
