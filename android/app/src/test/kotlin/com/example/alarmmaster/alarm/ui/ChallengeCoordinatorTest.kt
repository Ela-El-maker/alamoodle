package com.example.alarmmaster.alarm.ui

import com.example.alarmmaster.alarm.domain.ChallengePolicy
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ChallengeCoordinatorTest {
    private val coordinator = ChallengeCoordinator()

    @Test
    fun normalize_prefersExplicitPolicy() {
        val policy = coordinator.normalize(challengePolicy = "Qr", legacyChallenge = "Math Puzzle")

        assertEquals("qr", policy.mode)
    }

    @Test
    fun normalize_mapsLegacyNames() {
        assertEquals("math", coordinator.normalize(null, "Math Puzzle").mode)
        assertEquals("memory", coordinator.normalize(null, "Memory Tiles").mode)
        assertEquals("qr", coordinator.normalize(null, "QR Scanner").mode)
        assertEquals("none", coordinator.normalize(null, "None").mode)
    }

    @Test
    fun isSupported_rejectsDeferredModes() {
        assertTrue(coordinator.isSupported(ChallengePolicy("math")))
        assertTrue(coordinator.isSupported(ChallengePolicy("memory")))
        assertTrue(coordinator.isSupported(ChallengePolicy("qr")))
        assertFalse(coordinator.isSupported(ChallengePolicy("steps")))
    }
}
