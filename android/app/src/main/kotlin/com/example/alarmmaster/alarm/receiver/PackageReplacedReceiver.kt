package com.example.alarmmaster.alarm.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.alarmmaster.alarm.reliability.RecoveryReason

class PackageReplacedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        dispatchRecovery(context, RecoveryReason.PACKAGE_REPLACED)
    }
}
