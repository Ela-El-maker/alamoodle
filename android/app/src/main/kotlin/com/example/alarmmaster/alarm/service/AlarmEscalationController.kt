package com.example.alarmmaster.alarm.service

import com.example.alarmmaster.alarm.domain.EscalationPolicy
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.max

class AlarmEscalationController {
    private var escalationJob: Job? = null

    fun start(
        policy: EscalationPolicy,
        onVolumeStep: (Float) -> Unit,
    ) {
        stop()
        if (!policy.enabled) return
        val totalSteps = max(1, policy.maxSteps)
        escalationJob = CoroutineScope(Dispatchers.Default).launch {
            val delta = (policy.endVolume - policy.startVolume) / totalSteps.toFloat()
            repeat(totalSteps + 1) { idx ->
                val next = (policy.startVolume + (delta * idx)).coerceIn(0f, 1f)
                onVolumeStep(next)
                delay((policy.stepSeconds.coerceAtLeast(1) * 1000L))
            }
        }
    }

    fun stop() {
        escalationJob?.cancel()
        escalationJob = null
    }
}
