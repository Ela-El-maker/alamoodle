package com.example.alarmmaster.alarm.service

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class AlarmAudioControllerTest {
    @Test
    fun startAndStop_updatesPlayingState() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val controller = AlarmAudioController(context)

        controller.start()
        assertTrue(controller.isPlaying)

        controller.stop()
        assertFalse(controller.isPlaying)
    }
}
