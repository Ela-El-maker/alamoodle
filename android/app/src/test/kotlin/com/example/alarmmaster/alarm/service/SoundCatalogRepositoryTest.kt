package com.example.alarmmaster.alarm.service

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class SoundCatalogRepositoryTest {
    @Test
    fun bundledCatalog_hasStableIds() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val repository = SoundCatalogRepository(context)

        val sounds = repository.getSoundProfiles()
        val ids = sounds.map { it.id }

        assertTrue(ids.contains("default_alarm"))
        assertTrue(ids.contains("gentle_chime"))
        assertTrue(ids.contains("digital_beep"))
        assertTrue(ids.contains("bell_tower"))
    }

    @Test
    fun vibrationProfiles_includeOffAndDefault() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val repository = SoundCatalogRepository(context)

        val profiles = repository.getVibrationProfiles()
        val off = profiles.first { it.id == "off" }
        val default = profiles.first { it.id == "default" }

        assertEquals(0, off.pattern.size)
        assertTrue(default.pattern.isNotEmpty())
    }
}
