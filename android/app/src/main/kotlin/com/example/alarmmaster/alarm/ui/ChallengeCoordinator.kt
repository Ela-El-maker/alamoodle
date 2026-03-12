package com.example.alarmmaster.alarm.ui

import com.example.alarmmaster.alarm.domain.ChallengePolicy

class ChallengeCoordinator {
    fun normalize(challengePolicy: String?, legacyChallenge: String): ChallengePolicy {
        if (!challengePolicy.isNullOrBlank()) {
            return ChallengePolicy(challengePolicy.trim().lowercase())
        }
        return when {
            legacyChallenge.contains("QR", ignoreCase = true) -> ChallengePolicy("qr")
            legacyChallenge.contains("Math", ignoreCase = true) -> ChallengePolicy("math")
            legacyChallenge.contains("Memory", ignoreCase = true) -> ChallengePolicy("memory")
            else -> ChallengePolicy.NONE
        }
    }

    fun isSupported(policy: ChallengePolicy): Boolean {
        return policy.mode in setOf("none", "math", "memory", "qr")
    }
}
