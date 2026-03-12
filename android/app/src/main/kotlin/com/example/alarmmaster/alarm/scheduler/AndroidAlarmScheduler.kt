package com.example.alarmmaster.alarm.scheduler

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.alarmmaster.alarm.config.AlarmRuntimePolicy
import com.example.alarmmaster.alarm.data.dao.ScheduleRegistryDao
import com.example.alarmmaster.alarm.data.entities.ScheduleRegistryEntity
import com.example.alarmmaster.alarm.domain.TriggerInstance
import com.example.alarmmaster.alarm.domain.TriggerKind
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class AndroidAlarmScheduler(
    private val context: Context,
    private val scheduleRegistryDao: ScheduleRegistryDao,
    private val alarmIntentFactory: AlarmIntentFactory,
) : AlarmScheduler {
    companion object {
        private const val TAG = "AndroidAlarmScheduler"
    }

    private val alarmManager: AlarmManager = context.getSystemService(AlarmManager::class.java)
    private val ioScope = CoroutineScope(Dispatchers.IO)

    override fun scheduleTrigger(trigger: TriggerInstance) {
        alarmIntentFactory.cancelLegacyBroadcast(trigger)
        val pendingIntent = alarmIntentFactory.build(trigger)
        Log.i(
            TAG,
            "op=schedule source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} triggerId=${trigger.triggerId} kind=${trigger.kind} alarmId=${trigger.alarmId}",
        )

        when (trigger.kind) {
            TriggerKind.MAIN -> {
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val showIntent = PendingIntent.getActivity(
                    context,
                    trigger.requestCode,
                    launchIntent ?: Intent(),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
                val info = AlarmManager.AlarmClockInfo(trigger.scheduledUtcMillis, showIntent)
                alarmManager.setAlarmClock(info, pendingIntent)
            }
            TriggerKind.PRE,
            TriggerKind.SNOOZE,
            -> {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    trigger.scheduledUtcMillis,
                    pendingIntent,
                )
            }
        }

        ioScope.launch {
            scheduleRegistryDao.upsert(
                ScheduleRegistryEntity(
                    triggerId = trigger.triggerId,
                    alarmId = trigger.alarmId,
                    requestCode = trigger.requestCode,
                    scheduledUtcMillis = trigger.scheduledUtcMillis,
                    active = true,
                ),
            )
        }
    }

    override fun scheduleAll(triggers: List<TriggerInstance>) {
        triggers.forEach(::scheduleTrigger)
    }

    override fun cancelTrigger(trigger: TriggerInstance) {
        val pendingIntent = alarmIntentFactory.build(trigger)
        alarmManager.cancel(pendingIntent)
        Log.i(
            TAG,
            "op=cancel source=native pipeline=native_ring fallback_delivery=${AlarmRuntimePolicy.LEGACY_DELIVERY_FALLBACK_ENABLED} triggerId=${trigger.triggerId} alarmId=${trigger.alarmId}",
        )
        ioScope.launch {
            scheduleRegistryDao.setActive(trigger.triggerId, false)
        }
    }

    override fun cancelAllForAlarm(alarmId: Long, triggers: List<TriggerInstance>) {
        triggers.forEach(::cancelTrigger)
        ioScope.launch {
            scheduleRegistryDao.deleteByAlarmId(alarmId)
        }
    }
}
