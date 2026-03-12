package com.example.alarmmaster.alarm.receiver

import com.example.alarmmaster.alarm.domain.AlarmPlan
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerStatus

enum class TriggerValidationResult {
    VALID,
    MISSING_TRIGGER,
    STALE_GENERATION,
    DISABLED_ALARM,
    ALREADY_CONSUMED,
}

object AlarmTriggerValidator {
    fun validate(
        payloadGeneration: Int,
        dbTrigger: TriggerInstance?,
        plan: AlarmPlan?,
    ): TriggerValidationResult {
        if (dbTrigger == null) return TriggerValidationResult.MISSING_TRIGGER
        if (dbTrigger.generation != payloadGeneration) return TriggerValidationResult.STALE_GENERATION
        if (plan?.enabled != true) return TriggerValidationResult.DISABLED_ALARM
        if (dbTrigger.status != TriggerStatus.SCHEDULED) return TriggerValidationResult.ALREADY_CONSUMED
        return TriggerValidationResult.VALID
    }
}
