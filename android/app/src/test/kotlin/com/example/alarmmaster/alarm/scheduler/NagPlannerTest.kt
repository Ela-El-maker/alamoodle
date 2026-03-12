package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.NagPolicy
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NagPlannerTest {
    private val planner = NagPlanner()

    @Test
    fun disabledPolicy_neverSchedulesNag() {
        val shouldSchedule = planner.shouldScheduleNag(
            policy = NagPolicy.DISABLED,
            elapsedMillis = 1_000,
            retryCount = 0,
        )

        assertFalse(shouldSchedule)
    }

    @Test
    fun maxRetriesReached_stopsScheduling() {
        val policy = NagPolicy(enabled = true, maxRetries = 2)

        assertFalse(planner.shouldScheduleNag(policy, elapsedMillis = 10_000, retryCount = 2))
    }

    @Test
    fun insideRetryWindow_schedulesNag() {
        val policy = NagPolicy(enabled = true, retryWindowMinutes = 30, maxRetries = 3)

        assertTrue(planner.shouldScheduleNag(policy, elapsedMillis = 5 * 60_000L, retryCount = 1))
    }

    @Test
    fun nextRetryDelay_enforcesIdleSafeMinimum() {
        val shortPolicy = NagPolicy(enabled = true, retryIntervalMinutes = 2)
        val normalPolicy = NagPolicy(enabled = true, retryIntervalMinutes = 12)

        assertEquals(9 * 60_000L, planner.nextRetryDelayMillis(shortPolicy))
        assertEquals(12 * 60_000L, planner.nextRetryDelayMillis(normalPolicy))
    }
}
