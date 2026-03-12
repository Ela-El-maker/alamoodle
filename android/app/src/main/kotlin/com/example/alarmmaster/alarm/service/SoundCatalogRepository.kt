package com.example.alarmmaster.alarm.service

import android.content.Context
import android.media.RingtoneManager
import android.net.Uri
import com.example.alarmmaster.alarm.domain.SoundProfile
import com.example.alarmmaster.alarm.domain.VibrationProfile

class SoundCatalogRepository(
    private val context: Context,
) {
    fun getSoundProfiles(): List<SoundProfile> = listOf(
        SoundProfile(
            id = "default_alarm",
            name = "Default Alarm",
            tag = "Classic",
            category = "recommended",
            vibrationProfileIds = listOf("default", "gentle", "strong"),
        ),
        SoundProfile(
            id = "gentle_chime",
            name = "Gentle Chime",
            tag = "Gentle",
            category = "gentle",
            vibrationProfileIds = listOf("gentle", "default"),
        ),
        SoundProfile(
            id = "digital_beep",
            name = "Digital Beep",
            tag = "Strong",
            category = "classic",
            vibrationProfileIds = listOf("default", "strong"),
        ),
        SoundProfile(
            id = "bell_tower",
            name = "Bell Tower",
            tag = "Strong",
            category = "loud",
            vibrationProfileIds = listOf("strong"),
        ),
    )

    fun getVibrationProfiles(): List<VibrationProfile> = listOf(
        VibrationProfile(id = "off", name = "Off", pattern = longArrayOf()),
        VibrationProfile(id = "gentle", name = "Gentle", pattern = longArrayOf(0, 220, 260, 220)),
        VibrationProfile(id = "default", name = "Default", pattern = longArrayOf(0, 400, 250, 400)),
        VibrationProfile(id = "strong", name = "Strong", pattern = longArrayOf(0, 650, 220, 650)),
    )

    fun resolveSoundUri(soundId: String): Uri? {
        return when (soundId) {
            "default_alarm" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            "gentle_chime" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            "digital_beep" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            "bell_tower" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        }
    }

    fun resolveVibrationPattern(vibrationProfileId: String?): LongArray {
        val id = vibrationProfileId ?: "default"
        return getVibrationProfiles().firstOrNull { it.id == id }?.pattern
            ?: longArrayOf(0, 400, 250, 400)
    }
}
