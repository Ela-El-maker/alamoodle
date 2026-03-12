package com.example.alarmmaster.alarm.receiver

import android.content.Context
import android.content.Intent

/**
 * Backward-compatible alias receiver. Forward all work to the Sprint 2 receiver.
 */
class NativeAlarmTriggerReceiver : AlarmTriggerReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        super.onReceive(context, intent)
    }
}
