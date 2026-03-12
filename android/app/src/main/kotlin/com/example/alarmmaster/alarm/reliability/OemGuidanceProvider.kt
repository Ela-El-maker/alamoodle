package com.example.alarmmaster.alarm.reliability

import android.os.Build
import com.example.alarmmaster.alarm.domain.OemGuidance

class OemGuidanceProvider {
    fun getGuidance(
        schedulerHealth: String,
        batteryOptimizationRisk: String,
    ): OemGuidance {
        val manufacturer = Build.MANUFACTURER.orEmpty().ifBlank { "unknown" }
        val normalized = manufacturer.lowercase()
        val baseSteps = mutableListOf<String>()

        if (schedulerHealth != "healthy") {
            baseSteps += "Open alarm permissions and allow exact alarms for this app."
        }
        if (batteryOptimizationRisk != "low") {
            baseSteps += "Disable battery optimization for this app to reduce missed alarms."
        }

        return when {
            normalized.contains("tecno") || normalized.contains("infinix") || normalized.contains("itel") -> OemGuidance(
                manufacturer = manufacturer,
                title = "Transsion Background Controls",
                summary = "Your device may aggressively stop background alarms. These steps may improve reliability but cannot override all OEM restrictions.",
                steps = baseSteps + listOf(
                    "Set battery mode to unrestricted for this app.",
                    "Allow Auto-start/background launch for this app.",
                    "Allow lock-screen notifications and alarm visibility.",
                    "Run a test alarm after changing settings to verify behavior.",
                ),
                settingsTargets = listOf("battery_optimization", "auto_start", "notifications", "exact_alarm"),
            )

            normalized.contains("xiaomi") || normalized.contains("redmi") || normalized.contains("poco") -> OemGuidance(
                manufacturer = manufacturer,
                title = "MIUI Background Restrictions",
                summary = "Your device may aggressively restrict background alarms. These steps may improve reliability but cannot guarantee behavior under every OEM mode.",
                steps = baseSteps + listOf(
                    "Enable Auto-start for this app in system settings.",
                    "Set battery saver to No restrictions for this app.",
                    "Lock the app in recents if your device supports it.",
                    "Run a test alarm after changing settings to verify behavior.",
                ),
                settingsTargets = listOf("auto_start", "battery_optimization", "exact_alarm", "notifications"),
            )

            normalized.contains("huawei") || normalized.contains("honor") -> OemGuidance(
                manufacturer = manufacturer,
                title = "EMUI / MagicOS Power Rules",
                summary = "Power management may stop background execution. These steps may improve reliability, but some restrictions are controlled by the OS.",
                steps = baseSteps + listOf(
                    "Allow app launch and background activity for this app.",
                    "Disable battery optimization for this app.",
                    "Allow notifications and lockscreen visibility.",
                    "Run a test alarm after changing settings to verify behavior.",
                ),
                settingsTargets = listOf("battery_optimization", "notifications", "exact_alarm"),
            )

            normalized.contains("oppo") || normalized.contains("realme") || normalized.contains("oneplus") -> OemGuidance(
                manufacturer = manufacturer,
                title = "Background Management Guidance",
                summary = "Some devices may pause alarm execution in low-power modes. These steps may improve reliability and reduce delays.",
                steps = baseSteps + listOf(
                    "Set app battery usage to unrestricted.",
                    "Allow background activity for this app.",
                    "Verify notifications and exact alarm permissions are enabled.",
                    "Run a test alarm after changing settings to verify behavior.",
                ),
                settingsTargets = listOf("battery_optimization", "notifications", "exact_alarm"),
            )

            normalized.contains("samsung") -> OemGuidance(
                manufacturer = manufacturer,
                title = "Samsung Reliability Tips",
                summary = "If alarms are delayed, these settings may improve reliability. Some One UI battery policies can still affect background timing.",
                steps = baseSteps + listOf(
                    "Exclude this app from Sleeping apps and Deep sleeping apps.",
                    "Set battery usage to unrestricted for this app.",
                    "Verify exact alarm and notification permissions.",
                    "Run a test alarm after changing settings to verify behavior.",
                ),
                settingsTargets = listOf("battery_optimization", "exact_alarm", "notifications"),
            )

            else -> OemGuidance(
                manufacturer = manufacturer,
                title = "Device Reliability Guidance",
                summary = "These settings may improve alarm reliability on your device. Background behavior can still vary by OEM and OS policy.",
                steps = baseSteps.ifEmpty {
                    listOf(
                        "Allow exact alarms for this app.",
                        "Allow notifications and lockscreen alerts.",
                        "Disable battery optimization for this app if alarms are delayed.",
                        "Run a test alarm after changing settings to verify behavior.",
                    )
                },
                settingsTargets = listOf("exact_alarm", "notifications", "battery_optimization"),
            )
        }
    }
}
