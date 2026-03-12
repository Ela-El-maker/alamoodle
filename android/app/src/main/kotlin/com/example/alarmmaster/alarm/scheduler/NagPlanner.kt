package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.NagPolicy

class NagPlanner {
    fun shouldScheduleNag(policy: NagPolicy, elapsedMillis: Long, retryCount: Int): Boolean {
        if (!policy.enabled) return false
        if (retryCount >= policy.maxRetries) return false
        val windowMillis = policy.retryWindowMinutes.coerceAtLeast(1) * 60_000L
        return elapsedMillis <= windowMillis
    }

    fun nextRetryDelayMillis(policy: NagPolicy): Long {
        return policy.retryIntervalMinutes.coerceAtLeast(9) * 60_000L
    }
}
