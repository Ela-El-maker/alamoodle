package com.example.alarmmaster.alarm.domain

data class SoundProfile(
    val id: String,
    val name: String,
    val tag: String,
    val category: String,
    val vibrationProfileIds: List<String>,
)

data class VibrationProfile(
    val id: String,
    val name: String,
    val pattern: LongArray,
)

data class EscalationPolicy(
    val enabled: Boolean,
    val startVolume: Float = 0.45f,
    val endVolume: Float = 1.0f,
    val stepSeconds: Int = 20,
    val maxSteps: Int = 3,
) {
    companion object {
        val DISABLED = EscalationPolicy(enabled = false)
    }
}

data class NagPolicy(
    val enabled: Boolean,
    val retryWindowMinutes: Int = 30,
    val maxRetries: Int = 2,
    val retryIntervalMinutes: Int = 10,
) {
    companion object {
        val DISABLED = NagPolicy(enabled = false)
    }
}

data class PrimaryAction(
    val type: String,
    val value: String,
)

data class ChallengePolicy(
    val mode: String,
) {
    fun requiresQr() = mode.equals("qr", ignoreCase = true)
    fun requiresMath() = mode.equals("math", ignoreCase = true)
    fun requiresMemory() = mode.equals("memory", ignoreCase = true)

    companion object {
        val NONE = ChallengePolicy("none")
    }
}

data class StatsSummary(
    val totalFired: Int,
    val totalDismissed: Int,
    val totalSnoozed: Int,
    val totalMissed: Int,
    val repairedCount: Int,
    val dismissRate: Double,
    val snoozeRate: Double,
    val streakDays: Int,
)

data class StatsTrendPoint(
    val dayUtcStartMillis: Long,
    val fired: Int,
    val dismissed: Int,
    val snoozed: Int,
    val missed: Int,
    val repaired: Int,
)

data class OnboardingReadiness(
    val exactAlarmReady: Boolean,
    val notificationsReady: Boolean,
    val channelsReady: Boolean,
    val batteryOptimizationRisk: String,
    val directBootReady: Boolean,
    val nativeRingPipelineEnabled: Boolean,
    val legacyFallbackDefaultEnabled: Boolean,
)
