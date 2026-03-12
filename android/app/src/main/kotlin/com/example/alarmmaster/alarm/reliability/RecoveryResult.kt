package com.example.alarmmaster.alarm.reliability

data class RecoveryResult(
    val reason: RecoveryReason,
    val examinedAlarms: Int,
    val restoredTriggers: Int,
    val staleRemoved: Int,
    val failures: Int,
    val atRiskAlarms: Int,
    val status: String,
    val repaired: Boolean,
)
