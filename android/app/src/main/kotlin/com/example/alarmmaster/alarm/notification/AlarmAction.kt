package com.example.alarmmaster.alarm.notification

enum class AlarmAction(
    val actionId: String,
    val snoozeMinutes: Int? = null,
) {
    DISMISS("com.example.alarmmaster.action.DISMISS"),
    PRE_DISMISS("com.example.alarmmaster.action.PRE_DISMISS"),
    SNOOZE_5("com.example.alarmmaster.action.SNOOZE_5", 5),
    SNOOZE_10("com.example.alarmmaster.action.SNOOZE_10", 10),
    SNOOZE_15("com.example.alarmmaster.action.SNOOZE_15", 15),
    PRIMARY_ACTION("com.example.alarmmaster.action.PRIMARY_ACTION"),
    ;

    companion object {
        fun fromActionId(actionId: String?): AlarmAction? {
            if (actionId.isNullOrBlank()) return null
            return entries.firstOrNull { it.actionId == actionId }
        }
    }
}
