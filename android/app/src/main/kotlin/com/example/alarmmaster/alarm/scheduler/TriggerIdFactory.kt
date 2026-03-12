package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.TriggerKind
import kotlin.math.abs

class TriggerIdFactory {
    fun buildTriggerId(
        alarmId: Long,
        kind: TriggerKind,
        index: Int,
        generation: Int,
        scheduledUtcMillis: Long,
    ): String {
        return "$alarmId-$generation-${kind.name.lowercase()}-$index-$scheduledUtcMillis"
    }

    fun buildRequestCode(
        alarmId: Long,
        kind: TriggerKind,
        index: Int,
        generation: Int,
    ): Int {
        val kindCode = when (kind) {
            TriggerKind.MAIN -> 1
            TriggerKind.PRE -> 2
            TriggerKind.SNOOZE -> 3
        }
        val raw = alarmId * 100_000L + generation * 1_000L + kindCode * 100L + index
        return abs((raw % Int.MAX_VALUE).toInt())
    }
}
