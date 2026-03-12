import '../alarm/config/alarm_engine_mode.dart';
import '../alarm/shared/alarm_record.dart';
import 'gen/guardian_api.g.dart';

class ReliabilitySnapshotModel {
  const ReliabilitySnapshotModel({
    required this.exactAlarmPermissionGranted,
    required this.notificationsPermissionGranted,
    required this.canScheduleExactAlarms,
    required this.engineMode,
    required this.schedulerHealth,
    required this.nativeRingPipelineEnabled,
    required this.legacyEmergencyRingFallbackEnabled,
    required this.legacyDeliveryFallbackEnabled,
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
  final bool legacyDeliveryFallbackEnabled;
  final bool directBootReady;
  final String channelHealth;
  final bool fullScreenReady;
  final String batteryOptimizationRisk;
  final String scheduleRegistryHealth;
  final String lastRecoveryReason;
  final int? lastRecoveryAtUtcMillis;
  final String lastRecoveryStatus;
  final bool legacyFallbackDefaultEnabled;

  factory ReliabilitySnapshotModel.fromDto(ReliabilitySnapshotDto dto) {
    return ReliabilitySnapshotModel(
      exactAlarmPermissionGranted: dto.exactAlarmPermissionGranted,
      notificationsPermissionGranted: dto.notificationsPermissionGranted,
      canScheduleExactAlarms: dto.canScheduleExactAlarms,
      engineMode: dto.engineMode,
      schedulerHealth: dto.schedulerHealth,
      nativeRingPipelineEnabled: dto.nativeRingPipelineEnabled,
      legacyEmergencyRingFallbackEnabled:
          dto.legacyEmergencyRingFallbackEnabled,
      legacyDeliveryFallbackEnabled: kLegacyDeliveryFallbackEnabled,
      directBootReady: dto.directBootReady,
      channelHealth: dto.channelHealth,
      fullScreenReady: dto.fullScreenReady,
      batteryOptimizationRisk: dto.batteryOptimizationRisk,
      scheduleRegistryHealth: dto.scheduleRegistryHealth,
      lastRecoveryReason: dto.lastRecoveryReason,
      lastRecoveryAtUtcMillis: dto.lastRecoveryAtUtcMillis,
      lastRecoveryStatus: dto.lastRecoveryStatus,
      legacyFallbackDefaultEnabled: dto.legacyFallbackDefaultEnabled,
    );
  }
}

class TestAlarmResultModel {
  const TestAlarmResultModel({
    required this.success,
    required this.message,
    required this.scheduledAtUtcMillis,
  });

  final bool success;
  final String message;
  final int? scheduledAtUtcMillis;

  factory TestAlarmResultModel.fromDto(TestAlarmResultDto dto) {
    return TestAlarmResultModel(
      success: dto.success,
      message: dto.message,
      scheduledAtUtcMillis: dto.scheduledAtUtcMillis,
    );
  }
}

class SoundProfileModel {
  const SoundProfileModel({
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

  factory SoundProfileModel.fromDto(SoundProfileDto dto) {
    return SoundProfileModel(
      id: dto.id,
      name: dto.name,
      tag: dto.tag,
      category: dto.category,
      vibrationProfileIds: dto.vibrationProfileIds,
    );
  }
}

class StatsSummaryModel {
  const StatsSummaryModel({
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

  factory StatsSummaryModel.fromDto(StatsSummaryDto dto) {
    return StatsSummaryModel(
      totalFired: dto.totalFired,
      totalDismissed: dto.totalDismissed,
      totalSnoozed: dto.totalSnoozed,
      totalMissed: dto.totalMissed,
      repairedCount: dto.repairedCount,
      dismissRate: dto.dismissRate,
      snoozeRate: dto.snoozeRate,
      streakDays: dto.streakDays,
    );
  }
}

class StatsTrendPointModel {
  const StatsTrendPointModel({
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

  factory StatsTrendPointModel.fromDto(StatsTrendPointDto dto) {
    return StatsTrendPointModel(
      dayUtcStartMillis: dto.dayUtcStartMillis,
      fired: dto.fired,
      dismissed: dto.dismissed,
      snoozed: dto.snoozed,
      missed: dto.missed,
      repaired: dto.repaired,
    );
  }
}

class OnboardingReadinessModel {
  const OnboardingReadinessModel({
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

  factory OnboardingReadinessModel.fromDto(OnboardingReadinessDto dto) {
    return OnboardingReadinessModel(
      exactAlarmReady: dto.exactAlarmReady,
      notificationsReady: dto.notificationsReady,
      channelsReady: dto.channelsReady,
      batteryOptimizationRisk: dto.batteryOptimizationRisk,
      directBootReady: dto.directBootReady,
      nativeRingPipelineEnabled: dto.nativeRingPipelineEnabled,
      legacyFallbackDefaultEnabled: dto.legacyFallbackDefaultEnabled,
    );
  }
}

class AlarmPlanModel {
  const AlarmPlanModel({
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

  factory AlarmPlanModel.fromDto(AlarmPlanDto dto) {
    return AlarmPlanModel(
      alarmId: dto.alarmId,
      title: dto.title,
      hour24: dto.hour24,
      minute: dto.minute,
      repeatDays: dto.repeatDays,
      enabled: dto.enabled,
      sound: dto.sound,
      challenge: dto.challenge,
      snoozeCount: dto.snoozeCount,
      snoozeDuration: dto.snoozeDuration,
      vibration: dto.vibration,
      vibrationProfileId: dto.vibrationProfileId,
      escalationPolicy: dto.escalationPolicy,
      nagPolicy: dto.nagPolicy,
      primaryAction: dto.primaryAction,
      challengePolicy: dto.challengePolicy,
      anchorUtcMillis: dto.anchorUtcMillis,
      preReminderMinutes: dto.preReminderMinutes,
      recurrenceType: dto.recurrenceType,
      recurrenceInterval: dto.recurrenceInterval,
      recurrenceWeekdays: dto.recurrenceWeekdays,
      recurrenceDayOfMonth: dto.recurrenceDayOfMonth,
      recurrenceOrdinal: dto.recurrenceOrdinal,
      recurrenceOrdinalWeekday: dto.recurrenceOrdinalWeekday,
      recurrenceExclusionDates: dto.recurrenceExclusionDates,
      reminderOffsetsMinutes: dto.reminderOffsetsMinutes,
      reminderBeforeOnly: dto.reminderBeforeOnly,
    );
  }

  AlarmRecord toRecord() {
    return AlarmRecord(
      id: alarmId,
      hour24: hour24,
      minute: minute,
      name: title,
      enabled: enabled,
      repeatDays: repeatDays,
      sound: sound,
      challenge: challenge,
      snoozeCount: snoozeCount,
      snoozeDuration: snoozeDuration,
      vibration: vibration,
      vibrationProfileId: vibrationProfileId,
      escalationPolicy: escalationPolicy,
      nagPolicy: nagPolicy,
      primaryAction: primaryAction,
      challengePolicy: challengePolicy,
      anchorUtcMillis: anchorUtcMillis,
      recurrenceType: recurrenceType,
      recurrenceInterval: recurrenceInterval,
      recurrenceWeekdays: recurrenceWeekdays,
      recurrenceDayOfMonth: recurrenceDayOfMonth,
      recurrenceOrdinal: recurrenceOrdinal,
      recurrenceOrdinalWeekday: recurrenceOrdinalWeekday,
      recurrenceExclusionDates: recurrenceExclusionDates,
      reminderOffsetsMinutes: reminderOffsetsMinutes,
      reminderBeforeOnly: reminderBeforeOnly,
    );
  }

  static AlarmPlanModel fromRecord(AlarmRecord record) {
    return AlarmPlanModel(
      alarmId: record.id,
      title: record.name,
      hour24: record.hour24,
      minute: record.minute,
      repeatDays: record.repeatDays,
      enabled: record.enabled,
      sound: record.sound,
      challenge: record.challenge,
      snoozeCount: record.snoozeCount,
      snoozeDuration: record.snoozeDuration,
      vibration: record.vibration,
      vibrationProfileId: record.vibrationProfileId,
      escalationPolicy: record.escalationPolicy,
      nagPolicy: record.nagPolicy,
      primaryAction: record.primaryAction,
      challengePolicy: record.challengePolicy,
      anchorUtcMillis: record.anchorUtcMillis,
      preReminderMinutes:
          record.reminderOffsetsMinutes.isNotEmpty
              ? record.reminderOffsetsMinutes
              : const <int>[],
      recurrenceType: record.recurrenceType,
      recurrenceInterval: record.recurrenceInterval,
      recurrenceWeekdays: record.recurrenceWeekdays,
      recurrenceDayOfMonth: record.recurrenceDayOfMonth,
      recurrenceOrdinal: record.recurrenceOrdinal,
      recurrenceOrdinalWeekday: record.recurrenceOrdinalWeekday,
      recurrenceExclusionDates: record.recurrenceExclusionDates,
      reminderOffsetsMinutes: record.reminderOffsetsMinutes,
      reminderBeforeOnly: record.reminderBeforeOnly,
    );
  }
}

class TemplateModel {
  const TemplateModel({
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

  factory TemplateModel.fromDto(TemplateDto dto) {
    return TemplateModel(
      templateId: dto.templateId,
      name: dto.name,
      title: dto.title,
      hour24: dto.hour24,
      minute: dto.minute,
      repeatDays: dto.repeatDays,
      sound: dto.sound,
      vibration: dto.vibration,
      vibrationProfileId: dto.vibrationProfileId,
      escalationPolicy: dto.escalationPolicy,
      nagPolicy: dto.nagPolicy,
      primaryAction: dto.primaryAction,
      challenge: dto.challenge,
      challengePolicy: dto.challengePolicy,
      snoozeCount: dto.snoozeCount,
      snoozeDuration: dto.snoozeDuration,
      recurrenceType: dto.recurrenceType,
      recurrenceInterval: dto.recurrenceInterval,
      recurrenceWeekdays: dto.recurrenceWeekdays,
      recurrenceDayOfMonth: dto.recurrenceDayOfMonth,
      recurrenceOrdinal: dto.recurrenceOrdinal,
      recurrenceOrdinalWeekday: dto.recurrenceOrdinalWeekday,
      recurrenceExclusionDates: dto.recurrenceExclusionDates,
      reminderOffsetsMinutes: dto.reminderOffsetsMinutes,
      reminderBeforeOnly: dto.reminderBeforeOnly,
      timezonePolicy: dto.timezonePolicy,
    );
  }

  TemplateDto toDto() {
    return TemplateDto(
      templateId: templateId,
      name: name,
      title: title,
      hour24: hour24,
      minute: minute,
      repeatDays: repeatDays,
      sound: sound,
      vibration: vibration,
      vibrationProfileId: vibrationProfileId,
      escalationPolicy: escalationPolicy,
      nagPolicy: nagPolicy,
      primaryAction: primaryAction,
      challenge: challenge,
      challengePolicy: challengePolicy,
      snoozeCount: snoozeCount,
      snoozeDuration: snoozeDuration,
      recurrenceType: recurrenceType,
      recurrenceInterval: recurrenceInterval,
      recurrenceWeekdays: recurrenceWeekdays,
      recurrenceDayOfMonth: recurrenceDayOfMonth,
      recurrenceOrdinal: recurrenceOrdinal,
      recurrenceOrdinalWeekday: recurrenceOrdinalWeekday,
      recurrenceExclusionDates: recurrenceExclusionDates,
      reminderOffsetsMinutes: reminderOffsetsMinutes,
      reminderBeforeOnly: reminderBeforeOnly,
      timezonePolicy: timezonePolicy,
    );
  }
}

class BackupImportResultModel {
  const BackupImportResultModel({
    required this.success,
    required this.message,
    required this.restoredAlarms,
    required this.restoredTemplates,
  });

  final bool success;
  final String message;
  final int restoredAlarms;
  final int restoredTemplates;

  factory BackupImportResultModel.fromDto(BackupImportResultDto dto) {
    return BackupImportResultModel(
      success: dto.success,
      message: dto.message,
      restoredAlarms: dto.restoredAlarms,
      restoredTemplates: dto.restoredTemplates,
    );
  }
}

class OemGuidanceModel {
  const OemGuidanceModel({
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

  factory OemGuidanceModel.fromDto(OemGuidanceDto dto) {
    return OemGuidanceModel(
      manufacturer: dto.manufacturer,
      title: dto.title,
      summary: dto.summary,
      steps: dto.steps,
      settingsTargets: dto.settingsTargets,
    );
  }
}
