package com.example.alarmmaster.alarm.scheduler

import android.app.AlarmManager
import android.content.Context
import android.os.Build

open class ExactAlarmPermissionGate(private val context: Context) {
    open fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        return alarmManager?.canScheduleExactAlarms() ?: false
    }
}
