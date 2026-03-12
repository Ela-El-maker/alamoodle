package com.example.alarmmaster.alarm.bridge

import com.example.alarmmaster.bridge.gen.AlarmHistoryDto
import com.example.alarmmaster.bridge.gen.AlarmPlanDto
import com.example.alarmmaster.bridge.gen.BackupImportResultDto
import com.example.alarmmaster.bridge.gen.CreateAlarmCommandDto
import com.example.alarmmaster.bridge.gen.GuardianAlarmHostApi
import com.example.alarmmaster.bridge.gen.OnboardingReadinessDto
import com.example.alarmmaster.bridge.gen.OemGuidanceDto
import com.example.alarmmaster.bridge.gen.ReliabilitySnapshotDto
import com.example.alarmmaster.bridge.gen.SoundProfileDto
import com.example.alarmmaster.bridge.gen.StatsSummaryDto
import com.example.alarmmaster.bridge.gen.StatsTrendPointDto
import com.example.alarmmaster.bridge.gen.TemplateDto
import com.example.alarmmaster.bridge.gen.TestAlarmResultDto
import com.example.alarmmaster.bridge.gen.TriggerDto
import com.example.alarmmaster.bridge.gen.UpdateAlarmCommandDto
import kotlinx.coroutines.runBlocking

class GuardianAlarmHostApiImpl(
    private val coreService: AlarmCoreGateway,
) : GuardianAlarmHostApi {
    override fun createAlarm(command: CreateAlarmCommandDto): AlarmPlanDto = runBlocking {
        coreService.createAlarm(command)
    }

    override fun updateAlarm(command: UpdateAlarmCommandDto): AlarmPlanDto = runBlocking {
        coreService.updateAlarm(command)
    }

    override fun deleteAlarm(alarmId: Long) = runBlocking {
        coreService.deleteAlarm(alarmId)
    }

    override fun enableAlarm(alarmId: Long): AlarmPlanDto = runBlocking {
        coreService.enableAlarm(alarmId)
    }

    override fun disableAlarm(alarmId: Long): AlarmPlanDto = runBlocking {
        coreService.disableAlarm(alarmId)
    }

    override fun getUpcomingAlarms(): List<AlarmPlanDto> = runBlocking {
        coreService.getUpcomingAlarms()
    }

    override fun getAlarmDetail(alarmId: Long): AlarmPlanDto? = runBlocking {
        coreService.getAlarmDetail(alarmId)
    }

    override fun getAlarmHistory(alarmId: Long): List<AlarmHistoryDto> = runBlocking {
        coreService.getAlarmHistory(alarmId)
    }

    override fun getReliabilitySnapshot(): ReliabilitySnapshotDto = runBlocking {
        coreService.getReliabilitySnapshot()
    }

    override fun getRecentHistory(limit: Long, alarmId: Long?): List<AlarmHistoryDto> = runBlocking {
        coreService.getRecentHistory(limit, alarmId)
    }

    override fun exportDiagnostics(): String = runBlocking {
        coreService.exportDiagnostics()
    }

    override fun runTestAlarm(): TestAlarmResultDto = runBlocking {
        coreService.runTestAlarm()
    }

    override fun openSystemSettings(target: String): Boolean = runBlocking {
        coreService.openSystemSettings(target)
    }

    override fun getSoundCatalog(): List<SoundProfileDto> = runBlocking {
        coreService.getSoundCatalog()
    }

    override fun previewSound(soundId: String): Boolean = runBlocking {
        coreService.previewSound(soundId)
    }

    override fun stopSoundPreview(): Boolean = runBlocking {
        coreService.stopSoundPreview()
    }

    override fun getTemplates(): List<TemplateDto> = runBlocking {
        coreService.getTemplates()
    }

    override fun saveTemplate(template: TemplateDto): TemplateDto = runBlocking {
        coreService.saveTemplate(template)
    }

    override fun deleteTemplate(templateId: Long) = runBlocking {
        coreService.deleteTemplate(templateId)
    }

    override fun applyTemplate(templateId: Long): TemplateDto? = runBlocking {
        coreService.applyTemplate(templateId)
    }

    override fun exportBackup(): String = runBlocking {
        coreService.exportBackup()
    }

    override fun importBackup(payload: String): BackupImportResultDto = runBlocking {
        coreService.importBackup(payload)
    }

    override fun getOemGuidance(): OemGuidanceDto = runBlocking {
        coreService.getOemGuidance()
    }

    override fun previewPlannedTriggers(command: CreateAlarmCommandDto): List<TriggerDto> = runBlocking {
        coreService.previewPlannedTriggers(command)
    }

    override fun getStatsSummary(range: String): StatsSummaryDto = runBlocking {
        coreService.getStatsSummary(range)
    }

    override fun getStatsTrends(range: String): List<StatsTrendPointDto> = runBlocking {
        coreService.getStatsTrends(range)
    }

    override fun getOnboardingReadiness(): OnboardingReadinessDto = runBlocking {
        coreService.getOnboardingReadiness()
    }
}
