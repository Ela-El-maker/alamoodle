package com.example.alarmmaster.alarm.reliability

enum class RecoveryReason {
    BOOT_COMPLETED,
    LOCKED_BOOT_COMPLETED,
    TIMEZONE_CHANGED,
    TIME_SET,
    DATE_CHANGED,
    PACKAGE_REPLACED,
    STARTUP_SANITY,
    USER_UNLOCKED,
}
