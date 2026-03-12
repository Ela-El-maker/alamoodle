package com.example.alarmmaster.alarm.service

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import com.example.alarmmaster.alarm.diagnostics.EventLogger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class PrimaryActionLauncherTest {
    @Test
    fun launch_urlAction_startsIntentAndLogsSuccess() {
        val base = ApplicationProvider.getApplicationContext<Context>()
        val context = RecordingContext(base)
        val logger = RecordingLogger()
        val launcher = PrimaryActionLauncher(context, logger)

        val result = launcher.launch("""{"type":"url","value":"https://example.com"}""")

        assertTrue(result)
        assertNotNull(context.lastIntent)
        assertEquals(Intent.ACTION_VIEW, context.lastIntent?.action)
        assertTrue(logger.events.any { it.first == "PRIMARY_ACTION_LAUNCHED" })
    }

    @Test
    fun launch_missingHandler_logsFailure() {
        val base = ApplicationProvider.getApplicationContext<Context>()
        val context = RecordingContext(base, throwNotFound = true)
        val logger = RecordingLogger()
        val launcher = PrimaryActionLauncher(context, logger)

        val result = launcher.launch("""{"type":"maps","value":"Nairobi"}""")

        assertFalse(result)
        assertTrue(logger.events.any { it.first == "PRIMARY_ACTION_FAILED" })
    }

    @Test
    fun launch_unknownType_returnsFalse() {
        val base = ApplicationProvider.getApplicationContext<Context>()
        val context = RecordingContext(base)
        val logger = RecordingLogger()
        val launcher = PrimaryActionLauncher(context, logger)

        val result = launcher.launch("""{"type":"unknown","value":"x"}""")

        assertFalse(result)
    }
}

private class RecordingContext(
    base: Context,
    private val throwNotFound: Boolean = false,
) : ContextWrapper(base) {
    var lastIntent: Intent? = null

    override fun startActivity(intent: Intent) {
        if (throwNotFound) {
            throw ActivityNotFoundException("No handler")
        }
        lastIntent = intent
    }
}

private class RecordingLogger : EventLogger(null) {
    val events = mutableListOf<Pair<String, String>>()

    override fun log(event: String, meta: String) {
        events += event to meta
    }
}
