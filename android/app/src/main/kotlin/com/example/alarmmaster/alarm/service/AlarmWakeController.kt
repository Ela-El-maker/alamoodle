package com.example.alarmmaster.alarm.service

import android.content.Context
import android.os.PowerManager

class AlarmWakeController(context: Context) {
    private val powerManager = context.getSystemService(PowerManager::class.java)
    private var wakeLock: PowerManager.WakeLock? = null

    fun acquire() {
        if (wakeLock?.isHeld == true) return
        val lock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "alarmmaster:alarmWake")
        lock.setReferenceCounted(false)
        lock.acquire(30_000L)
        wakeLock = lock
    }

    fun release() {
        val lock = wakeLock ?: return
        if (lock.isHeld) {
            lock.release()
        }
        wakeLock = null
    }
}
