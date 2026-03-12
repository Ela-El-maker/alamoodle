package com.example.alarmmaster.alarm.service

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator

class AlarmAudioController(private val context: Context) {
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val vibrator = context.getSystemService(Vibrator::class.java)
    private val soundCatalogRepository = SoundCatalogRepository(context)

    private var ringtone: Ringtone? = null
    private var focusRequest: AudioFocusRequest? = null
    private var mode: Mode = Mode.IDLE
    var isPlaying: Boolean = false
        private set

    fun start() {
        startRinging(soundId = "default_alarm", vibrationProfileId = "default")
    }

    fun startPreview(soundId: String): Boolean {
        synchronized(lock) {
            if (activeOwner != null && activeOwner !== this) {
                activeOwner?.stop()
            }
            activeOwner = this
        }
        stopInternal()
        requestFocus()
        mode = Mode.PREVIEW
        val uri = soundCatalogRepository.resolveSoundUri(soundId)
        ringtone = RingtoneManager.getRingtone(context, uri)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = false
                volume = 0.8f
            }
            play()
        }
        isPlaying = ringtone != null
        return isPlaying
    }

    fun startRinging(
        soundId: String,
        vibrationProfileId: String?,
        initialVolume: Float = 1.0f,
    ): Boolean {
        synchronized(lock) {
            if (activeOwner != null && activeOwner !== this) {
                activeOwner?.stop()
            }
            activeOwner = this
        }
        stopInternal()
        requestFocus()
        mode = Mode.RINGING
        val uri = soundCatalogRepository.resolveSoundUri(soundId)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        ringtone = RingtoneManager.getRingtone(context, uri)?.apply {
            audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                isLooping = true
                volume = initialVolume.coerceIn(0f, 1f)
            }
            play()
        }

        val pattern = soundCatalogRepository.resolveVibrationPattern(vibrationProfileId)
        vibrate(pattern)
        // Treat active vibration as an active ring session even if ringtone
        // object could not be created on this device/runtime.
        isPlaying = ringtone != null || pattern.isNotEmpty()
        return isPlaying
    }

    fun setVolume(volume: Float) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            runCatching {
                ringtone?.volume = volume.coerceIn(0f, 1f)
            }
        }
    }

    fun stop() {
        synchronized(lock) {
            if (activeOwner === this) {
                activeOwner = null
            }
        }
        stopInternal()
    }

    private fun stopInternal() {
        ringtone?.stop()
        ringtone = null
        vibrator?.cancel()
        abandonFocus()
        isPlaying = false
        mode = Mode.IDLE
    }

    private fun vibrate(pattern: LongArray) {
        if (pattern.isEmpty()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun requestFocus() {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener { }
                .build()
            audioManager.requestAudioFocus(request)
            focusRequest = request
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    private enum class Mode {
        IDLE,
        PREVIEW,
        RINGING,
    }

    companion object {
        private val lock = Any()
        private var activeOwner: AlarmAudioController? = null
    }
}
