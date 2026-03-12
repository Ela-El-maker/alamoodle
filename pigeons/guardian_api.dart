import 'package:pigeon/pigeon.dart';

class TriggerDto {
  TriggerDto({
    required this.triggerId,
    required this.alarmId,
    required this.kind,
    required this.scheduledLocalIso,
    required this.scheduledUtcMillis,
    required this.requestCode,
    required this.status,
    required this.generation,
  });

  final String triggerId;
  final int alarmId;
  final String kind;
  final String scheduledLocalIso;
  final int scheduledUtcMillis;
  final int requestCode;
  final String status;
  final int generation;
}

class AlarmPlanDto {
  AlarmPlanDto({
    required this.alarmId,
    required this.title,
    required this.hour24,
    required this.minute,
    required this.repeatDays,
    required this.enabled,
    required this.sound,
    required this.challenge,
    required this.snoozeCount,
    required this.snoozeDuration,
    required this.vibration,
    required this.vibrationProfileId,
    required this.escalationPolicy,
    required this.nagPolicy,
    required this.primaryAction,
    required this.challengePolicy,
    required this.anchorUtcMillis,
    required this.timezoneId,
    required this.timezonePolicy,
    required this.preReminderMinutes,
    required this.recurrenceType,
    required this.recurrenceInterval,
    required this.recurrenceWeekdays,
    required this.recurrenceDayOfMonth,
    required this.recurrenceOrdinal,
    required this.recurrenceOrdinalWeekday,
    required this.recurrenceExclusionDates,
    required this.reminderOffsetsMinutes,
    required this.reminderBeforeOnly,
    required this.createdAtUtcMillis,
    required this.updatedAtUtcMillis,
    required this.triggers,
  });

  final int alarmId;
  final String title;
  final int hour24;
  final int minute;
  final List<String> repeatDays;
  final bool enabled;
  final String sound;
  final String challenge;
  final int snoozeCount;
  final int snoozeDuration;
  final bool vibration;
  final String? vibrationProfileId;
  final String? escalationPolicy;
  final String? nagPolicy;
  final String? primaryAction;
  final String? challengePolicy;
  final int? anchorUtcMillis;
  final String timezoneId;
  final String timezonePolicy;
  final List<int> preReminderMinutes;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final List<int> recurrenceWeekdays;
  final int? recurrenceDayOfMonth;
  final int? recurrenceOrdinal;
  final int? recurrenceOrdinalWeekday;
  final List<String> recurrenceExclusionDates;
  final List<int> reminderOffsetsMinutes;
  final bool reminderBeforeOnly;
  final int createdAtUtcMillis;
  final int updatedAtUtcMillis;
  final List<TriggerDto> triggers;
}

class CreateAlarmCommandDto {
  CreateAlarmCommandDto({
    required this.alarmId,
    required this.title,
    required this.hour24,
    required this.minute,
    required this.repeatDays,
    required this.enabled,
    required this.sound,
    required this.challenge,
    required this.snoozeCount,
    required this.snoozeDuration,
    required this.vibration,
    required this.vibrationProfileId,
    required this.escalationPolicy,
    required this.nagPolicy,
    required this.primaryAction,
    required this.challengePolicy,
    required this.anchorUtcMillis,
    required this.timezoneId,
    required this.timezonePolicy,
    required this.preReminderMinutes,
    required this.recurrenceType,
    required this.recurrenceInterval,
    required this.recurrenceWeekdays,
    required this.recurrenceDayOfMonth,
    required this.recurrenceOrdinal,
    required this.recurrenceOrdinalWeekday,
    required this.recurrenceExclusionDates,
    required this.reminderOffsetsMinutes,
    required this.reminderBeforeOnly,
  });

  final int? alarmId;
  final String title;
  final int hour24;
  final int minute;
  final List<String> repeatDays;
  final bool enabled;
  final String sound;
  final String challenge;
  final int snoozeCount;
  final int snoozeDuration;
  final bool vibration;
  final String? vibrationProfileId;
  final String? escalationPolicy;
  final String? nagPolicy;
  final String? primaryAction;
  final String? challengePolicy;
  final int? anchorUtcMillis;
  final String timezoneId;
  final String timezonePolicy;
  final List<int> preReminderMinutes;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final List<int> recurrenceWeekdays;
  final int? recurrenceDayOfMonth;
  final int? recurrenceOrdinal;
  final int? recurrenceOrdinalWeekday;
  final List<String> recurrenceExclusionDates;
  final List<int> reminderOffsetsMinutes;
  final bool reminderBeforeOnly;
}

class UpdateAlarmCommandDto {
  UpdateAlarmCommandDto({
    required this.alarmId,
    required this.title,
    required this.hour24,
    required this.minute,
    required this.repeatDays,
    required this.enabled,
    required this.sound,
    required this.challenge,
    required this.snoozeCount,
    required this.snoozeDuration,
    required this.vibration,
    required this.vibrationProfileId,
    required this.escalationPolicy,
    required this.nagPolicy,
    required this.primaryAction,
    required this.challengePolicy,
    required this.anchorUtcMillis,
    required this.timezoneId,
    required this.timezonePolicy,
    required this.preReminderMinutes,
    required this.recurrenceType,
    required this.recurrenceInterval,
    required this.recurrenceWeekdays,
    required this.recurrenceDayOfMonth,
    required this.recurrenceOrdinal,
    required this.recurrenceOrdinalWeekday,
    required this.recurrenceExclusionDates,
    required this.reminderOffsetsMinutes,
    required this.reminderBeforeOnly,
  });

  final int alarmId;
  final String title;
  final int hour24;
  final int minute;
  final List<String> repeatDays;
  final bool enabled;
  final String sound;
  final String challenge;
  final int snoozeCount;
  final int snoozeDuration;
  final bool vibration;
  final String? vibrationProfileId;
  final String? escalationPolicy;
  final String? nagPolicy;
  final String? primaryAction;
  final String? challengePolicy;
  final int? anchorUtcMillis;
  final String timezoneId;
  final String timezonePolicy;
  final List<int> preReminderMinutes;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final List<int> recurrenceWeekdays;
  final int? recurrenceDayOfMonth;
  final int? recurrenceOrdinal;
  final int? recurrenceOrdinalWeekday;
  final List<String> recurrenceExclusionDates;
  final List<int> reminderOffsetsMinutes;
  final bool reminderBeforeOnly;
}

class AlarmHistoryDto {
  AlarmHistoryDto({
    required this.historyId,
    required this.alarmId,
    required this.triggerId,
    required this.eventType,
    required this.occurredAtUtcMillis,
    required this.meta,
  });

  final int historyId;
  final int alarmId;
  final String triggerId;
  final String eventType;
  final int occurredAtUtcMillis;
  final String meta;
}

class ReliabilitySnapshotDto {
  ReliabilitySnapshotDto({
    required this.exactAlarmPermissionGranted,
    required this.notificationsPermissionGranted,
    required this.canScheduleExactAlarms,
    required this.engineMode,
    required this.schedulerHealth,
    required this.nativeRingPipelineEnabled,
    required this.legacyEmergencyRingFallbackEnabled,
    required this.directBootReady,
    required this.channelHealth,
    required this.fullScreenReady,
    required this.batteryOptimizationRisk,
    required this.scheduleRegistryHealth,
    required this.lastRecoveryReason,
    required this.lastRecoveryAtUtcMillis,
    required this.lastRecoveryStatus,
    required this.legacyFallbackDefaultEnabled,
  });

  final bool exactAlarmPermissionGranted;
  final bool notificationsPermissionGranted;
  final bool canScheduleExactAlarms;
  final String engineMode;
  final String schedulerHealth;
  final bool nativeRingPipelineEnabled;
  final bool legacyEmergencyRingFallbackEnabled;
  final bool directBootReady;
  final String channelHealth;
  final bool fullScreenReady;
  final String batteryOptimizationRisk;
  final String scheduleRegistryHealth;
  final String lastRecoveryReason;
  final int? lastRecoveryAtUtcMillis;
  final String lastRecoveryStatus;
  final bool legacyFallbackDefaultEnabled;
}

class TestAlarmResultDto {
  TestAlarmResultDto({
    required this.success,
    required this.message,
    required this.scheduledAtUtcMillis,
  });

  final bool success;
  final String message;
  final int? scheduledAtUtcMillis;
}

class SoundProfileDto {
  SoundProfileDto({
    required this.id,
    required this.name,
    required this.tag,
    required this.category,
    required this.vibrationProfileIds,
  });

  final String id;
  final String name;
  final String tag;
  final String category;
  final List<String> vibrationProfileIds;
}

class TemplateDto {
  TemplateDto({
    required this.templateId,
    required this.name,
    required this.title,
    required this.hour24,
    required this.minute,
    required this.repeatDays,
    required this.sound,
    required this.vibration,
    required this.vibrationProfileId,
    required this.escalationPolicy,
    required this.nagPolicy,
    required this.primaryAction,
    required this.challenge,
    required this.challengePolicy,
    required this.snoozeCount,
    required this.snoozeDuration,
    required this.recurrenceType,
    required this.recurrenceInterval,
    required this.recurrenceWeekdays,
    required this.recurrenceDayOfMonth,
    required this.recurrenceOrdinal,
    required this.recurrenceOrdinalWeekday,
    required this.recurrenceExclusionDates,
    required this.reminderOffsetsMinutes,
    required this.reminderBeforeOnly,
    required this.timezonePolicy,
  });

  final int templateId;
  final String name;
  final String title;
  final int hour24;
  final int minute;
  final List<String> repeatDays;
  final String sound;
  final bool vibration;
  final String? vibrationProfileId;
  final String? escalationPolicy;
  final String? nagPolicy;
  final String? primaryAction;
  final String challenge;
  final String? challengePolicy;
  final int snoozeCount;
  final int snoozeDuration;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final List<int> recurrenceWeekdays;
  final int? recurrenceDayOfMonth;
  final int? recurrenceOrdinal;
  final int? recurrenceOrdinalWeekday;
  final List<String> recurrenceExclusionDates;
  final List<int> reminderOffsetsMinutes;
  final bool reminderBeforeOnly;
  final String timezonePolicy;
}

class BackupImportResultDto {
  BackupImportResultDto({
    required this.success,
    required this.message,
    required this.restoredAlarms,
    required this.restoredTemplates,
  });

  final bool success;
  final String message;
  final int restoredAlarms;
  final int restoredTemplates;
}

class OemGuidanceDto {
  OemGuidanceDto({
    required this.manufacturer,
    required this.title,
    required this.summary,
    required this.steps,
    required this.settingsTargets,
  });

  final String manufacturer;
  final String title;
  final String summary;
  final List<String> steps;
  final List<String> settingsTargets;
}

class StatsSummaryDto {
  StatsSummaryDto({
    required this.totalFired,
    required this.totalDismissed,
    required this.totalSnoozed,
    required this.totalMissed,
    required this.repairedCount,
    required this.dismissRate,
    required this.snoozeRate,
    required this.streakDays,
  });

  final int totalFired;
  final int totalDismissed;
  final int totalSnoozed;
  final int totalMissed;
  final int repairedCount;
  final double dismissRate;
  final double snoozeRate;
  final int streakDays;
}

class StatsTrendPointDto {
  StatsTrendPointDto({
    required this.dayUtcStartMillis,
    required this.fired,
    required this.dismissed,
    required this.snoozed,
    required this.missed,
    required this.repaired,
  });

  final int dayUtcStartMillis;
  final int fired;
  final int dismissed;
  final int snoozed;
  final int missed;
  final int repaired;
}

class OnboardingReadinessDto {
  OnboardingReadinessDto({
    required this.exactAlarmReady,
    required this.notificationsReady,
    required this.channelsReady,
    required this.batteryOptimizationRisk,
    required this.directBootReady,
    required this.nativeRingPipelineEnabled,
    required this.legacyFallbackDefaultEnabled,
  });

  final bool exactAlarmReady;
  final bool notificationsReady;
  final bool channelsReady;
  final String batteryOptimizationRisk;
  final bool directBootReady;
  final bool nativeRingPipelineEnabled;
  final bool legacyFallbackDefaultEnabled;
}

@HostApi()
abstract class GuardianAlarmHostApi {
  AlarmPlanDto createAlarm(CreateAlarmCommandDto command);

  AlarmPlanDto updateAlarm(UpdateAlarmCommandDto command);

  void deleteAlarm(int alarmId);

  AlarmPlanDto enableAlarm(int alarmId);

  AlarmPlanDto disableAlarm(int alarmId);

  List<AlarmPlanDto> getUpcomingAlarms();

  AlarmPlanDto? getAlarmDetail(int alarmId);

  List<AlarmHistoryDto> getAlarmHistory(int alarmId);

  ReliabilitySnapshotDto getReliabilitySnapshot();

  List<AlarmHistoryDto> getRecentHistory(int limit, int? alarmId);

  String exportDiagnostics();

  TestAlarmResultDto runTestAlarm();

  bool openSystemSettings(String target);

  List<SoundProfileDto> getSoundCatalog();

  bool previewSound(String soundId);

  bool stopSoundPreview();

  List<TemplateDto> getTemplates();

  TemplateDto saveTemplate(TemplateDto template);

  void deleteTemplate(int templateId);

  TemplateDto? applyTemplate(int templateId);

  String exportBackup();

  BackupImportResultDto importBackup(String payload);

  OemGuidanceDto getOemGuidance();

  List<TriggerDto> previewPlannedTriggers(CreateAlarmCommandDto command);

  StatsSummaryDto getStatsSummary(String range);

  List<StatsTrendPointDto> getStatsTrends(String range);

  OnboardingReadinessDto getOnboardingReadiness();
}
