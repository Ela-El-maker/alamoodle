package com.example.alarmmaster.alarm.scheduler

import com.example.alarmmaster.alarm.domain.TriggerKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class TriggerIdFactoryTest {
    private val factory = TriggerIdFactory()

    @Test
    fun requestCode_isDeterministic() {
        val codeA = factory.buildRequestCode(42L, TriggerKind.MAIN, 0, 123)
        val codeB = factory.buildRequestCode(42L, TriggerKind.MAIN, 0, 123)
        assertEquals(codeA, codeB)
    }

    @Test
    fun requestCode_changesAcrossKinds() {
        val mainCode = factory.buildRequestCode(42L, TriggerKind.MAIN, 0, 1)
        val preCode = factory.buildRequestCode(42L, TriggerKind.PRE, 0, 1)
        assertNotEquals(mainCode, preCode)
    }
}
