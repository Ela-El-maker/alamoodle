package com.example.alarmmaster.alarm.bridge

import com.example.alarmmaster.bridge.gen.AlarmHistoryDto
import com.example.alarmmaster.bridge.gen.AlarmPlanDto
import com.example.alarmmaster.bridge.gen.BackupImportResultDto
import com.example.alarmmaster.bridge.gen.CreateAlarmCommandDto
import com.example.alarmmaster.bridge.gen.OemGuidanceDto
import com.example.alarmmaster.bridge.gen.ReliabilitySnapshotDto
import com.example.alarmmaster.bridge.gen.SoundProfileDto
import com.example.alarmmaster.bridge.gen.StatsSummaryDto
import com.example.alarmmaster.bridge.gen.StatsTrendPointDto
import com.example.alarmmaster.bridge.gen.TemplateDto
import com.example.alarmmaster.bridge.gen.TestAlarmResultDto
import com.example.alarmmaster.bridge.gen.TriggerDto
import com.example.alarmmaster.bridge.gen.OnboardingReadinessDto
import com.example.alarmmaster.bridge.gen.UpdateAlarmCommandDto

interface AlarmCoreGateway {
    suspend fun createAlarm(command: CreateAlarmCommandDto): AlarmPlanDto
    suspend fun updateAlarm(command: UpdateAlarmCommandDto): AlarmPlanDto
    suspend fun deleteAlarm(alarmId: Long)
    suspend fun enableAlarm(alarmId: Long): AlarmPlanDto
    suspend fun disableAlarm(alarmId: Long): AlarmPlanDto
    suspend fun getUpcomingAlarms(): List<AlarmPlanDto>
    suspend fun getAlarmDetail(alarmId: Long): AlarmPlanDto?
    suspend fun getAlarmHistory(alarmId: Long): List<AlarmHistoryDto>
    suspend fun getReliabilitySnapshot(): ReliabilitySnapshotDto
    suspend fun getRecentHistory(limit: Long, alarmId: Long?): List<AlarmHistoryDto>
    suspend fun exportDiagnostics(): String
    suspend fun runTestAlarm(): TestAlarmResultDto
    suspend fun openSystemSettings(target: String): Boolean
    suspend fun getSoundCatalog(): List<SoundProfileDto>
    suspend fun previewSound(soundId: String): Boolean
    suspend fun stopSoundPreview(): Boolean
    suspend fun getTemplates(): List<TemplateDto>
    suspend fun saveTemplate(template: TemplateDto): TemplateDto
    suspend fun deleteTemplate(templateId: Long)
    suspend fun applyTemplate(templateId: Long): TemplateDto?
    suspend fun exportBackup(): String
    suspend fun importBackup(payload: String): BackupImportResultDto
    suspend fun getOemGuidance(): OemGuidanceDto
    suspend fun previewPlannedTriggers(command: CreateAlarmCommandDto): List<TriggerDto>
    suspend fun getStatsSummary(range: String): StatsSummaryDto
    suspend fun getStatsTrends(range: String): List<StatsTrendPointDto>
    suspend fun getOnboardingReadiness(): OnboardingReadinessDto
}
