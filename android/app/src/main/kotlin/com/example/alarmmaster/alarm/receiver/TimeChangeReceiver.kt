package com.example.alarmmaster.alarm.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.alarmmaster.alarm.reliability.RecoveryReason

class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val reason = when (intent?.action) {
            Intent.ACTION_TIMEZONE_CHANGED -> RecoveryReason.TIMEZONE_CHANGED
            Intent.ACTION_DATE_CHANGED -> RecoveryReason.DATE_CHANGED
            else -> RecoveryReason.TIME_SET
        }
        dispatchRecovery(context, reason)
    }
}
