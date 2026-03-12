package com.example.alarmmaster.alarm.reliability

class StartupSanityChecker(
    private val recoveryCoordinator: RecoveryCoordinator,
) {
    suspend fun run(): RecoveryResult {
        return recoveryCoordinator.recover(RecoveryReason.STARTUP_SANITY)
    }
}
