package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.TriggerInstance

interface AlarmScheduler {
    fun scheduleTrigger(trigger: TriggerInstance)
    fun scheduleAll(triggers: List<TriggerInstance>)
    fun cancelTrigger(trigger: TriggerInstance)
    fun cancelAllForAlarm(alarmId: Long, triggers: List<TriggerInstance>)
}
