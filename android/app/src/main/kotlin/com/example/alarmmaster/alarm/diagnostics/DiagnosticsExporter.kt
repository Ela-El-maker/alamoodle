package com.example.alarmmaster.alarm.diagnostics

import android.content.Context
import android.os.Build
import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.data.LastRecoveryState
import com.example.alarmmaster.alarm.domain.AlarmHistoryRecord
import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.reliability.ReliabilityChecker
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.scheduler.ExactAlarmPermissionGate
import java.util.UUID

class DiagnosticsExporter(
    private val context: Context,
    private val alarmRepository: AlarmRepository,
    private val triggerRepository: TriggerRepository,
    private val historyRepository: HistoryRepository,
    private val reliabilityChecker: ReliabilityChecker,
    private val exactAlarmPermissionGate: ExactAlarmPermissionGate,
) {
    suspend fun export(lastRecovery: LastRecoveryState, historyLimit: Int = 30): String {
        val traceId = UUID.randomUUID().toString()
        val exportedAtUtcMillis = System.currentTimeMillis()
        val alarms = alarmRepository.getAll()
        val triggerMap = alarms.associate { it.alarmId to triggerRepository.getByAlarmId(it.alarmId) }
        val history = historyRepository.getRecent(historyLimit)
        val reliability = reliabilityChecker.snapshot(AlarmRuntimePolicy.ENGINE_MODE)
        val appVersion = resolveAppVersion()
        val versionCode = resolveVersionCode()

        return buildString {
            append("{\n")
            append("  \"traceId\": \"").append(traceId).append("\",\n")
            append("  \"exportedAtUtcMillis\": ").append(exportedAtUtcMillis).append(",\n")
            append("  \"appVersion\": \"").append(appVersion).append("\",\n")
            append("  \"appVersionCode\": ").append(versionCode).append(",\n")
            append("  \"packageName\": \"").append(context.packageName).append("\",\n")
            append("  \"deviceManufacturer\": \"").append(Build.MANUFACTURER.orEmpty()).append("\",\n")
            append("  \"deviceModel\": \"").append(Build.MODEL.orEmpty()).append("\",\n")
            append("  \"sdkInt\": ").append(Build.VERSION.SDK_INT).append(",\n")
            append("  \"engineMode\": \"").append(AlarmRuntimePolicy.ENGINE_MODE).append("\",\n")
            append("  \"canScheduleExactAlarms\": ").append(exactAlarmPermissionGate.canScheduleExactAlarms()).append(",\n")
            append("  \"lastRecovery\": ").append(lastRecovery.toJson()).append(",\n")
            append("  \"reliability\": ").append(reliability.toJson()).append(",\n")
            append("  \"alarms\": ").append(alarms.toJson(triggerMap)).append(",\n")
            append("  \"recentHistory\": ").append(history.toJson()).append("\n")
            append("}")
        }
    }

    private fun resolveAppVersion(): String {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        return packageInfo.versionName ?: "unknown"
    }

    private fun resolveVersionCode(): Long {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        return packageInfo.longVersionCode
    }

    private fun AlarmPlan.toJson(triggers: List<TriggerInstance>): String {
        return buildString {
            append("{\"alarmId\":").append(alarmId)
            append(",\"title\":\"").append(title.replace("\"", "'")).append("\"")
            append(",\"enabled\":").append(enabled)
            append(",\"timezoneId\":\"").append(timezoneId).append("\"")
            append(",\"anchorUtcMillis\":").append(anchorUtcMillis ?: "null")
            append(",\"triggerCount\":").append(triggers.size)
            append("}")
        }
    }

    private fun List<AlarmPlan>.toJson(triggerMap: Map<Long, List<TriggerInstance>>): String {
        return joinToString(prefix = "[", postfix = "]") { plan ->
            plan.toJson(triggerMap[plan.alarmId].orEmpty())
        }
    }

    private fun List<AlarmHistoryRecord>.toJson(): String {
        return joinToString(prefix = "[", postfix = "]") { record ->
            val classification = AlarmFailureClassifier.classify(record.eventType)
            "{\"alarmId\":${record.alarmId},\"triggerId\":\"${record.triggerId}\",\"eventType\":\"${record.eventType}\",\"classification\":\"$classification\",\"occurredAtUtcMillis\":${record.occurredAtUtcMillis},\"meta\":\"${record.meta.replace("\"", "'")}\"}"
        }
    }

    private fun LastRecoveryState.toJson(): String {
        return "{\"reason\":\"$reason\",\"status\":\"$status\",\"atUtcMillis\":${atUtcMillis ?: "null"}}"
    }

    private fun com.example.alarmmaster.alarm.domain.ReliabilitySnapshot.toJson(): String {
        return "{\"schedulerHealth\":\"$schedulerHealth\",\"channelHealth\":\"$channelHealth\",\"directBootReady\":$directBootReady,\"fullScreenReady\":$fullScreenReady,\"batteryOptimizationRisk\":\"$batteryOptimizationRisk\",\"scheduleRegistryHealth\":\"$scheduleRegistryHealth\"}"
    }
}
