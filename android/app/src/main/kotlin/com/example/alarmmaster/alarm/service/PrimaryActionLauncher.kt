package com.example.alarmmaster.alarm.service

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.example.alarmmaster.alarm.diagnostics.EventLogger
import org.json.JSONObject

class PrimaryActionLauncher(
    private val context: Context,
    private val eventLogger: EventLogger,
) {
    fun launch(actionJson: String?): Boolean {
        if (actionJson.isNullOrBlank()) return false
        val payload = runCatching { JSONObject(actionJson) }.getOrNull() ?: return false
        val type = payload.optString("type")
        val value = payload.optString("value")
        val intent = when (type.lowercase()) {
            "url", "deep_link" -> Intent(Intent.ACTION_VIEW, Uri.parse(value))
            "maps" -> Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=${Uri.encode(value)}"))
            else -> null
        }?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ?: return false

        return try {
            context.startActivity(intent)
            eventLogger.log("PRIMARY_ACTION_LAUNCHED", "type=$type")
            true
        } catch (_: ActivityNotFoundException) {
            eventLogger.log("PRIMARY_ACTION_FAILED", "type=$type reason=no_handler")
            false
        } catch (_: Throwable) {
            eventLogger.log("PRIMARY_ACTION_FAILED", "type=$type reason=error")
            false
        }
    }
}
