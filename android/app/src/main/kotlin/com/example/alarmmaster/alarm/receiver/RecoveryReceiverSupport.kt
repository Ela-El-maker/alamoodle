package com.example.alarmmaster.alarm.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.os.UserManager
import android.util.Log
import com.example.alarmmaster.alarm.core.AlarmRuntime
import com.example.alarmmaster.alarm.diagnostics.EventLogger
import com.example.alarmmaster.alarm.reliability.RecoveryReason
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

internal fun BroadcastReceiver.dispatchRecovery(context: Context, reason: RecoveryReason) {
    val pendingResult = goAsync()
    CoroutineScope(Dispatchers.IO).launch {
        val appContext = context.applicationContext
        val unlocked = isUserUnlocked(appContext)
        try {
            Log.i(
                "AlarmCore",
                "RECOVERY_DISPATCH_RECEIVED reason=${reason.name} receiver=${this@dispatchRecovery::class.java.simpleName} unlocked=$unlocked",
            )

            if (!unlocked) {
                DirectBootRecoveryFallback.recover(appContext, reason)
                return@launch
            }

            val runtime = AlarmRuntime.get(appContext)
            runtime.eventLogger.log(
                "RECOVERY_DISPATCHED",
                "reason=${reason.name} receiver=${this@dispatchRecovery::class.java.simpleName}",
            )
            runtime.recoveryCoordinator.recover(reason)
        } catch (t: Throwable) {
            Log.e(
                "AlarmCore",
                "RECOVERY_DISPATCH_ERROR reason=${reason.name} receiver=${this@dispatchRecovery::class.java.simpleName} unlocked=$unlocked",
                t,
            )

            if (!unlocked) {
                runCatching {
                    DirectBootRecoveryFallback.recover(appContext, reason)
                }
            }

            runCatching {
                val loggerContext = if (appContext.isDeviceProtectedStorage) appContext else appContext.createDeviceProtectedStorageContext()
                EventLogger(loggerContext).log(
                    "RECOVERY_DISPATCH_FAILED",
                    "reason=${reason.name} receiver=${this@dispatchRecovery::class.java.simpleName} error=${t.message ?: "unknown"}",
                )
            }
        } finally {
            pendingResult.finish()
        }
    }
}

private fun isUserUnlocked(context: Context): Boolean {
    val userManager = context.getSystemService(UserManager::class.java)
    return userManager?.isUserUnlocked ?: true
}
