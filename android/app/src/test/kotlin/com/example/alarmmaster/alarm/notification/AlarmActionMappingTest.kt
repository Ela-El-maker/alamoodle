package com.example.alarmmaster.alarm.notification

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AlarmActionMappingTest {
    @Test
    fun mapsActionIdToEnum() {
        assertEquals(AlarmAction.DISMISS, AlarmAction.fromActionId(AlarmAction.DISMISS.actionId))
        assertEquals(AlarmAction.SNOOZE_10, AlarmAction.fromActionId(AlarmAction.SNOOZE_10.actionId))
    }

    @Test
    fun unknownActionReturnsNull() {
        assertNull(AlarmAction.fromActionId("unknown"))
        assertNull(AlarmAction.fromActionId(null))
    }
}
