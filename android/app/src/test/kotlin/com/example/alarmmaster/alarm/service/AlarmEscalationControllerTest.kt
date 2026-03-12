package com.example.alarmmaster.alarm.service

import com.example.alarmmaster.alarm.domain.EscalationPolicy
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class AlarmEscalationControllerTest {
    @Test
    fun enabledPolicy_emitsVolumeRamp() {
        val controller = AlarmEscalationController()
        val volumes = Collections.synchronizedList(mutableListOf<Float>())
        val latch = CountDownLatch(2)

        controller.start(
            policy = EscalationPolicy(
                enabled = true,
                startVolume = 0.25f,
                endVolume = 0.75f,
                stepSeconds = 1,
                maxSteps = 2,
            ),
            onVolumeStep = {
                volumes.add(it)
                latch.countDown()
            },
        )

        try {
            assertTrue("Expected at least two ramp callbacks", latch.await(2500, TimeUnit.MILLISECONDS))
            assertTrue(volumes.first() <= volumes.last())
            assertTrue(volumes.first() in 0.0f..1.0f)
            assertTrue(volumes.last() in 0.0f..1.0f)
        } finally {
            controller.stop()
        }
    }

    @Test
    fun disabledPolicy_emitsNoSteps() {
        val controller = AlarmEscalationController()
        var called = false
        controller.start(
            policy = EscalationPolicy.DISABLED,
            onVolumeStep = {
                called = true
            },
        )
        Thread.sleep(200)
        controller.stop()
        assertFalse(called)
    }
}
