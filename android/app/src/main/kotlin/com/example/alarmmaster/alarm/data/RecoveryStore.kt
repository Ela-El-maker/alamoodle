package com.example.alarmmaster.alarm.data

import android.content.Context
import android.net.Uri
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.recoveryDataStore by preferencesDataStore(name = "guardian_recovery")

data class RecoveryIndexEntry(
    val alarmId: Long,
    val triggerId: String,
    val kind: String,
    val scheduledUtcMillis: Long,
    val requestCode: Int,
    val generation: Int,
)

data class LastRecoveryState(
    val reason: String,
    val status: String,
    val atUtcMillis: Long?,
)

class RecoveryStore(private val context: Context) {
    private val enabledAlarmIdsKey = stringPreferencesKey("enabled_alarm_ids_csv")
    private val recoveryIndexKey = stringPreferencesKey("recovery_index_v2")
    private val lastRecoveryReasonKey = stringPreferencesKey("last_recovery_reason")
    private val lastRecoveryStatusKey = stringPreferencesKey("last_recovery_status")
    private val lastRecoveryAtKey = stringPreferencesKey("last_recovery_at")

    suspend fun setEnabledAlarmIds(ids: List<Long>) {
        context.recoveryDataStore.edit { prefs ->
            prefs[enabledAlarmIdsKey] = ids.joinToString(",")
        }
    }

    suspend fun getEnabledAlarmIds(): List<Long> {
        val raw = context.recoveryDataStore.data
            .map { prefs -> prefs[enabledAlarmIdsKey] ?: "" }
            .first()
        return raw.split(',').mapNotNull { it.toLongOrNull() }
    }

    suspend fun setRecoveryIndex(entries: List<RecoveryIndexEntry>) {
        val serialized = entries.joinToString("\n") { entry ->
            listOf(
                entry.alarmId.toString(),
                Uri.encode(entry.triggerId),
                entry.kind,
                entry.scheduledUtcMillis.toString(),
                entry.requestCode.toString(),
                entry.generation.toString(),
            ).joinToString("|")
        }
        context.recoveryDataStore.edit { prefs ->
            prefs[recoveryIndexKey] = serialized
        }
    }

    suspend fun getRecoveryIndex(): List<RecoveryIndexEntry> {
        val raw = context.recoveryDataStore.data
            .map { prefs -> prefs[recoveryIndexKey] ?: "" }
            .first()
        if (raw.isBlank()) return emptyList()
        return raw.split('\n')
            .mapNotNull { row ->
                val parts = row.split('|')
                if (parts.size != 6) return@mapNotNull null
                val alarmId = parts[0].toLongOrNull() ?: return@mapNotNull null
                val scheduledUtcMillis = parts[3].toLongOrNull() ?: return@mapNotNull null
                val requestCode = parts[4].toIntOrNull() ?: return@mapNotNull null
                val generation = parts[5].toIntOrNull() ?: return@mapNotNull null
                RecoveryIndexEntry(
                    alarmId = alarmId,
                    triggerId = Uri.decode(parts[1]),
                    kind = parts[2],
                    scheduledUtcMillis = scheduledUtcMillis,
                    requestCode = requestCode,
                    generation = generation,
                )
            }
    }

    suspend fun setLastRecoveryState(state: LastRecoveryState) {
        context.recoveryDataStore.edit { prefs ->
            prefs[lastRecoveryReasonKey] = state.reason
            prefs[lastRecoveryStatusKey] = state.status
            prefs[lastRecoveryAtKey] = state.atUtcMillis?.toString().orEmpty()
        }
    }

    suspend fun getLastRecoveryState(): LastRecoveryState {
        val tuple = context.recoveryDataStore.data.map { prefs ->
            Triple(
                prefs[lastRecoveryReasonKey] ?: "NONE",
                prefs[lastRecoveryStatusKey] ?: "UNKNOWN",
                prefs[lastRecoveryAtKey] ?: "",
            )
        }.first()
        return LastRecoveryState(
            reason = tuple.first,
            status = tuple.second,
            atUtcMillis = tuple.third.toLongOrNull(),
        )
    }
}
