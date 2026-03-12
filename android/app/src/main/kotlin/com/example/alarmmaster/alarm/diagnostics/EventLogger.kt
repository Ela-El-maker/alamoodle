package com.example.alarmmaster.alarm.diagnostics

import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

open class EventLogger(private val context: android.content.Context? = null) {
    open fun log(event: String, meta: String = "") {
        val line = "${timestamp()} $event ${meta.trim()}".trim()
        Log.i("AlarmCore", line)
        val ctx = context ?: return
        runCatching {
            val dir = File(ctx.filesDir, "alarm-diagnostics").apply { mkdirs() }
            File(dir, "events.log").appendText("$line\n")
        }
    }

    private fun timestamp(): String {
        return SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US).format(Date())
    }
}
