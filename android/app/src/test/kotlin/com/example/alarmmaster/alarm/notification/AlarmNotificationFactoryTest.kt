package com.example.alarmmaster.alarm.notification

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class AlarmNotificationFactoryTest {
    @Test
    fun buildsRingingNotification_withExpectedCategoryAndActions() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val launcher = AlarmFullScreenLauncher(context)
        val factory = AlarmNotificationFactory(context, launcher)

        val notification = factory.buildRingingNotification(
            alarmId = 1L,
            triggerId = "t-1",
            sessionId = "s-1",
            generation = 1,
            title = "Wake Up",
        )

        assertEquals(android.app.Notification.CATEGORY_ALARM, notification.category)
        assertTrue(notification.actions?.isNotEmpty() == true)
        assertTrue(notification.flags and android.app.Notification.FLAG_ONGOING_EVENT != 0)
    }

    @Test
    fun buildsFullScreenInterrupt_withFullScreenIntent() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val launcher = AlarmFullScreenLauncher(context)
        val factory = AlarmNotificationFactory(context, launcher)

        val notification = factory.buildFullScreenAlarmInterruptNotification(
            alarmId = 2L,
            triggerId = "t-2",
            sessionId = "s-2",
            generation = 2,
            title = "Medicine",
        )

        assertEquals(android.app.Notification.CATEGORY_ALARM, notification.category)
        assertNotNull(notification.fullScreenIntent)
    }
}
