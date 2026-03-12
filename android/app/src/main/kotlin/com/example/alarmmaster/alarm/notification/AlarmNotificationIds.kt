package com.example.alarmmaster.alarm.notification

import kotlin.math.absoluteValue

object AlarmNotificationIds {
    private const val PRE_ALERT_BASE = 42_000
    private const val PRE_ALERT_SPAN = 9_000

    fun preAlertForTrigger(triggerId: String): Int {
        if (triggerId.isBlank()) return PRE_ALERT_BASE
        return PRE_ALERT_BASE + (triggerId.hashCode().absoluteValue % PRE_ALERT_SPAN)
    }
}
