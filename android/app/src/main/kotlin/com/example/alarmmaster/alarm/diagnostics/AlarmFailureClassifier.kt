package com.example.alarmmaster.alarm.diagnostics

object AlarmFailureClassifier {
    fun classify(eventType: String): String {
        return when (eventType) {
            "RESTORED_AFTER_BOOT",
            "RESTORED_AFTER_LOCKED_BOOT",
            "RESTORED_AFTER_PACKAGE_REPLACED",
            "RESTORED_AFTER_TIME_CHANGE",
            -> eventType
            "TRIGGER_STALE",
            "TRIGGER_IGNORED_DUPLICATE",
            -> "IGNORED_STALE"
            "TRIGGER_SERVICE_START_FAILED" -> "FAILED_START"
            "TRIGGER_LATE_DEGRADED" -> "MISSED"
            else -> "UNKNOWN"
        }
    }
}
