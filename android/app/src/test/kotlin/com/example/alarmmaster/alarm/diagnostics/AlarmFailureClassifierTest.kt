package com.example.alarmmaster.alarm.diagnostics

import org.junit.Assert.assertEquals
import org.junit.Test

class AlarmFailureClassifierTest {
    @Test
    fun classifiesKnownEvents() {
        assertEquals("RESTORED_AFTER_BOOT", AlarmFailureClassifier.classify("RESTORED_AFTER_BOOT"))
        assertEquals("IGNORED_STALE", AlarmFailureClassifier.classify("TRIGGER_STALE"))
        assertEquals("FAILED_START", AlarmFailureClassifier.classify("TRIGGER_SERVICE_START_FAILED"))
        assertEquals("MISSED", AlarmFailureClassifier.classify("TRIGGER_LATE_DEGRADED"))
        assertEquals("UNKNOWN", AlarmFailureClassifier.classify("WHATEVER"))
    }
}
