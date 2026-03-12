import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../alarm/config/alarm_engine_mode.dart';
import '../alarm/shared/alarm_record.dart';
import 'gen/guardian_api.g.dart';
import 'guardian_platform_models.dart';

abstract class GuardianAlarmGateway {
  Future<AlarmPlanDto> createAlarm(CreateAlarmCommandDto command);
  Future<AlarmPlanDto> updateAlarm(UpdateAlarmCommandDto command);
  Future<void> deleteAlarm(int alarmId);
  Future<AlarmPlanDto> enableAlarm(int alarmId);
  Future<AlarmPlanDto> disableAlarm(int alarmId);
  Future<List<AlarmPlanDto>> getUpcomingAlarms();
  Future<AlarmPlanDto?> getAlarmDetail(int alarmId);
  Future<ReliabilitySnapshotDto> getReliabilitySnapshot();
  Future<List<AlarmHistoryDto>> getAlarmHistory(int alarmId);
  Future<List<AlarmHistoryDto>> getRecentHistory(int limit, int? alarmId);
  Future<String> exportDiagnostics();
  Future<TestAlarmResultDto> runTestAlarm();
  Future<bool> openSystemSettings(String target);
  Future<List<SoundProfileDto>> getSoundCatalog();
  Future<bool> previewSound(String soundId);
  Future<bool> stopSoundPreview();
  Future<List<TemplateDto>> getTemplates();
  Future<TemplateDto> saveTemplate(TemplateDto template);
  Future<void> deleteTemplate(int templateId);
  Future<TemplateDto?> applyTemplate(int templateId);
  Future<String> exportBackup();
  Future<BackupImportResultDto> importBackup(String payload);
  Future<OemGuidanceDto> getOemGuidance();
  Future<List<TriggerDto>> previewPlannedTriggers(
    CreateAlarmCommandDto command,
  );
  Future<StatsSummaryDto> getStatsSummary(String range);
  Future<List<StatsTrendPointDto>> getStatsTrends(String range);
  Future<OnboardingReadinessDto> getOnboardingReadiness();
}

class PigeonGuardianAlarmGateway implements GuardianAlarmGateway {
  PigeonGuardianAlarmGateway({GuardianAlarmHostApi? hostApi})
    : _hostApi = hostApi ?? GuardianAlarmHostApi();

  final GuardianAlarmHostApi _hostApi;

  @override
  Future<AlarmPlanDto> createAlarm(CreateAlarmCommandDto command) {
    return _hostApi.createAlarm(command);
  }

  @override
  Future<void> deleteAlarm(int alarmId) {
    return _hostApi.deleteAlarm(alarmId);
  }

  @override
  Future<AlarmPlanDto> disableAlarm(int alarmId) {
    return _hostApi.disableAlarm(alarmId);
  }

  @override
  Future<AlarmPlanDto> enableAlarm(int alarmId) {
    return _hostApi.enableAlarm(alarmId);
  }

  @override
  Future<AlarmPlanDto?> getAlarmDetail(int alarmId) {
    return _hostApi.getAlarmDetail(alarmId);
  }

  @override
  Future<List<AlarmPlanDto>> getUpcomingAlarms() {
    return _hostApi.getUpcomingAlarms();
  }

  @override
  Future<ReliabilitySnapshotDto> getReliabilitySnapshot() {
    return _hostApi.getReliabilitySnapshot();
  }

  @override
  Future<List<AlarmHistoryDto>> getAlarmHistory(int alarmId) {
    return _hostApi.getAlarmHistory(alarmId);
  }

  @override
  Future<List<AlarmHistoryDto>> getRecentHistory(int limit, int? alarmId) {
    return _hostApi.getRecentHistory(limit, alarmId);
  }

  @override
  Future<String> exportDiagnostics() {
    return _hostApi.exportDiagnostics();
  }

  @override
  Future<TestAlarmResultDto> runTestAlarm() {
    return _hostApi.runTestAlarm();
  }

  @override
  Future<bool> openSystemSettings(String target) {
    return _hostApi.openSystemSettings(target);
  }

  @override
  Future<List<SoundProfileDto>> getSoundCatalog() {
    return _hostApi.getSoundCatalog();
  }

  @override
  Future<bool> previewSound(String soundId) {
    return _hostApi.previewSound(soundId);
  }

  @override
  Future<bool> stopSoundPreview() {
    return _hostApi.stopSoundPreview();
  }

  @override
  Future<List<TemplateDto>> getTemplates() {
    return _hostApi.getTemplates();
  }

  @override
  Future<TemplateDto> saveTemplate(TemplateDto template) {
    return _hostApi.saveTemplate(template);
  }

  @override
  Future<void> deleteTemplate(int templateId) {
    return _hostApi.deleteTemplate(templateId);
  }

  @override
  Future<TemplateDto?> applyTemplate(int templateId) {
    return _hostApi.applyTemplate(templateId);
  }

  @override
  Future<String> exportBackup() {
    return _hostApi.exportBackup();
  }

  @override
  Future<BackupImportResultDto> importBackup(String payload) {
    return _hostApi.importBackup(payload);
  }

  @override
  Future<OemGuidanceDto> getOemGuidance() {
    return _hostApi.getOemGuidance();
  }

  @override
  Future<List<TriggerDto>> previewPlannedTriggers(
    CreateAlarmCommandDto command,
  ) {
    return _hostApi.previewPlannedTriggers(command);
  }

  @override
  Future<StatsSummaryDto> getStatsSummary(String range) {
    return _hostApi.getStatsSummary(range);
  }

  @override
  Future<List<StatsTrendPointDto>> getStatsTrends(String range) {
    return _hostApi.getStatsTrends(range);
  }

  @override
  Future<OnboardingReadinessDto> getOnboardingReadiness() {
    return _hostApi.getOnboardingReadiness();
  }

  @override
  Future<AlarmPlanDto> updateAlarm(UpdateAlarmCommandDto command) {
    return _hostApi.updateAlarm(command);
  }
}

class GuardianPlatformApi {
  GuardianPlatformApi({
    GuardianAlarmGateway? gateway,
    Future<String> Function()? timezoneProvider,
    bool Function()? isAndroidResolver,
  }) : _gateway = gateway ?? PigeonGuardianAlarmGateway(),
       _timezoneProvider = timezoneProvider ?? _defaultTimezoneProvider,
       _isAndroidResolver =
           isAndroidResolver ??
           (() => !kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static final GuardianPlatformApi instance = GuardianPlatformApi();

  final GuardianAlarmGateway _gateway;
  final Future<String> Function() _timezoneProvider;
  final bool Function() _isAndroidResolver;

  Future<List<AlarmRecord>> getUpcomingAlarms() {
    return _guarded(() async {
      if (!_isAndroid()) return <AlarmRecord>[];
      final dtos = await _gateway.getUpcomingAlarms();
      return dtos.map((dto) => AlarmPlanModel.fromDto(dto).toRecord()).toList();
    });
  }

  Future<AlarmRecord?> getAlarmDetail(int alarmId) {
    return _guarded(() async {
      if (!_isAndroid()) return null;
      final dto = await _gateway.getAlarmDetail(alarmId);
      if (dto == null) return null;
      return AlarmPlanModel.fromDto(dto).toRecord();
    });
  }

  Future<AlarmRecord> createAlarm(AlarmRecord record) {
    return _guarded(() async {
      if (!_isAndroid()) return record;
      final timezoneId = await _safeTimezone();

      final dto = await _gateway.createAlarm(
        CreateAlarmCommandDto(
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
          timezoneId: timezoneId,
          timezonePolicy: 'FIXED_LOCAL_TIME',
          preReminderMinutes: _derivePreReminderMinutes(record),
          recurrenceType: record.recurrenceType,
          recurrenceInterval: record.recurrenceInterval,
          recurrenceWeekdays: record.recurrenceWeekdays,
          recurrenceDayOfMonth: record.recurrenceDayOfMonth,
          recurrenceOrdinal: record.recurrenceOrdinal,
          recurrenceOrdinalWeekday: record.recurrenceOrdinalWeekday,
          recurrenceExclusionDates: record.recurrenceExclusionDates,
          reminderOffsetsMinutes: _deriveReminderOffsets(record),
          reminderBeforeOnly: record.reminderBeforeOnly,
        ),
      );
      return AlarmPlanModel.fromDto(dto).toRecord();
    });
  }

  Future<AlarmRecord> updateAlarm(AlarmRecord record) {
    return _guarded(() async {
      if (!_isAndroid()) return record;
      final timezoneId = await _safeTimezone();
      final dto = await _gateway.updateAlarm(
        UpdateAlarmCommandDto(
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
          timezoneId: timezoneId,
          timezonePolicy: 'FIXED_LOCAL_TIME',
          preReminderMinutes: _derivePreReminderMinutes(record),
          recurrenceType: record.recurrenceType,
          recurrenceInterval: record.recurrenceInterval,
          recurrenceWeekdays: record.recurrenceWeekdays,
          recurrenceDayOfMonth: record.recurrenceDayOfMonth,
          recurrenceOrdinal: record.recurrenceOrdinal,
          recurrenceOrdinalWeekday: record.recurrenceOrdinalWeekday,
          recurrenceExclusionDates: record.recurrenceExclusionDates,
          reminderOffsetsMinutes: _deriveReminderOffsets(record),
          reminderBeforeOnly: record.reminderBeforeOnly,
        ),
      );
      return AlarmPlanModel.fromDto(dto).toRecord();
    });
  }

  Future<void> deleteAlarm(int alarmId) {
    return _guarded(() async {
      if (!_isAndroid()) return;
      await _gateway.deleteAlarm(alarmId);
    });
  }

  Future<AlarmRecord?> enableAlarm(int alarmId) {
    return _guarded(() async {
      if (!_isAndroid()) return null;
      final dto = await _gateway.enableAlarm(alarmId);
      return AlarmPlanModel.fromDto(dto).toRecord();
    });
  }

  Future<AlarmRecord?> disableAlarm(int alarmId) {
    return _guarded(() async {
      if (!_isAndroid()) return null;
      final dto = await _gateway.disableAlarm(alarmId);
      return AlarmPlanModel.fromDto(dto).toRecord();
    });
  }

  Future<ReliabilitySnapshotModel> getReliabilitySnapshot() {
    return _guarded(() async {
      if (!_isAndroid()) {
        return const ReliabilitySnapshotModel(
          exactAlarmPermissionGranted: true,
          notificationsPermissionGranted: true,
          canScheduleExactAlarms: true,
          engineMode: 'legacy',
          schedulerHealth: 'n/a',
          nativeRingPipelineEnabled: kNativeRingPipelineEnabled,
          legacyEmergencyRingFallbackEnabled:
              kLegacyEmergencyRingFallbackEnabled,
          legacyDeliveryFallbackEnabled: kLegacyDeliveryFallbackEnabled,
          directBootReady: false,
          channelHealth: 'unknown',
          fullScreenReady: false,
          batteryOptimizationRisk: 'unknown',
          scheduleRegistryHealth: 'unknown',
          lastRecoveryReason: 'NONE',
          lastRecoveryAtUtcMillis: null,
          lastRecoveryStatus: 'UNKNOWN',
          legacyFallbackDefaultEnabled: kLegacyEmergencyRingFallbackEnabled,
        );
      }
      final dto = await _gateway.getReliabilitySnapshot();
      return ReliabilitySnapshotModel.fromDto(dto);
    });
  }

  Future<List<AlarmHistoryDto>> getRecentHistory({
    int limit = 25,
    int? alarmId,
  }) {
    return _guarded(() async {
      if (!_isAndroid()) return <AlarmHistoryDto>[];
      return _gateway.getRecentHistory(limit, alarmId);
    });
  }

  Future<List<AlarmHistoryDto>> getAlarmHistory(int alarmId) {
    return _guarded(() async {
      if (!_isAndroid()) return <AlarmHistoryDto>[];
      return _gateway.getAlarmHistory(alarmId);
    });
  }

  Future<TestAlarmResultModel> runTestAlarm() {
    return _guarded(() async {
      if (!_isAndroid()) {
        return const TestAlarmResultModel(
          success: false,
          message: 'Android only',
          scheduledAtUtcMillis: null,
        );
      }
      final dto = await _gateway.runTestAlarm();
      return TestAlarmResultModel.fromDto(dto);
    });
  }

  Future<bool> openSystemSettings(String target) {
    return _guarded(() async {
      if (!_isAndroid()) return false;
      return _gateway.openSystemSettings(target);
    });
  }

  Future<String> exportDiagnostics() {
    return _guarded(() async {
      if (!_isAndroid()) return '{}';
      return _gateway.exportDiagnostics();
    });
  }

  Future<String> exportBackup() {
    return _guarded(() async {
      if (!_isAndroid()) return '{}';
      return _gateway.exportBackup();
    });
  }

  Future<BackupImportResultModel> importBackup(String payload) {
    return _guarded(() async {
      if (!_isAndroid()) {
        return const BackupImportResultModel(
          success: false,
          message: 'Android only',
          restoredAlarms: 0,
          restoredTemplates: 0,
        );
      }
      final dto = await _gateway.importBackup(payload);
      return BackupImportResultModel.fromDto(dto);
    });
  }

  Future<OemGuidanceModel> getOemGuidance() {
    return _guarded(() async {
      if (!_isAndroid()) {
        return const OemGuidanceModel(
          manufacturer: 'unknown',
          title: 'Device Guidance Unavailable',
          summary:
              'OEM-specific guidance is available on Android devices only.',
          steps: <String>[],
          settingsTargets: <String>[],
        );
      }
      final dto = await _gateway.getOemGuidance();
      return OemGuidanceModel.fromDto(dto);
    });
  }

  Future<List<TemplateModel>> getTemplates() {
    return _guarded(() async {
      if (!_isAndroid()) return const <TemplateModel>[];
      final dtos = await _gateway.getTemplates();
      return dtos.map(TemplateModel.fromDto).toList();
    });
  }

  Future<TemplateModel> saveTemplate(TemplateModel template) {
    return _guarded(() async {
      if (!_isAndroid()) return template;
      final dto = await _gateway.saveTemplate(template.toDto());
      return TemplateModel.fromDto(dto);
    });
  }

  Future<void> deleteTemplate(int templateId) {
    return _guarded(() async {
      if (!_isAndroid()) return;
      await _gateway.deleteTemplate(templateId);
    });
  }

  Future<TemplateModel?> applyTemplate(int templateId) {
    return _guarded(() async {
      if (!_isAndroid()) return null;
      final dto = await _gateway.applyTemplate(templateId);
      return dto == null ? null : TemplateModel.fromDto(dto);
    });
  }

  Future<List<TriggerDto>> previewPlannedTriggers(AlarmRecord record) {
    return _guarded(() async {
      if (!_isAndroid()) return const <TriggerDto>[];
      final timezoneId = await _safeTimezone();
      final command = CreateAlarmCommandDto(
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
        timezoneId: timezoneId,
        timezonePolicy: 'FIXED_LOCAL_TIME',
        preReminderMinutes: _derivePreReminderMinutes(record),
        recurrenceType: record.recurrenceType,
        recurrenceInterval: record.recurrenceInterval,
        recurrenceWeekdays: record.recurrenceWeekdays,
        recurrenceDayOfMonth: record.recurrenceDayOfMonth,
        recurrenceOrdinal: record.recurrenceOrdinal,
        recurrenceOrdinalWeekday: record.recurrenceOrdinalWeekday,
        recurrenceExclusionDates: record.recurrenceExclusionDates,
        reminderOffsetsMinutes: _deriveReminderOffsets(record),
        reminderBeforeOnly: record.reminderBeforeOnly,
      );
      return _gateway.previewPlannedTriggers(command);
    });
  }

  Future<List<SoundProfileModel>> getSoundCatalog() {
    return _guarded(() async {
      if (!_isAndroid()) return const <SoundProfileModel>[];
      final dtos = await _gateway.getSoundCatalog();
      return dtos.map(SoundProfileModel.fromDto).toList();
    });
  }

  Future<bool> previewSound(String soundId) {
    return _guarded(() async {
      if (!_isAndroid()) return false;
      return _gateway.previewSound(soundId);
    });
  }

  Future<bool> stopSoundPreview() {
    return _guarded(() async {
      if (!_isAndroid()) return false;
      return _gateway.stopSoundPreview();
    });
  }

  Future<StatsSummaryModel> getStatsSummary({String range = '30d'}) {
    return _guarded(() async {
      if (!_isAndroid()) {
        return const StatsSummaryModel(
          totalFired: 0,
          totalDismissed: 0,
          totalSnoozed: 0,
          totalMissed: 0,
          repairedCount: 0,
          dismissRate: 0,
          snoozeRate: 0,
          streakDays: 0,
        );
      }
      final dto = await _gateway.getStatsSummary(range);
      return StatsSummaryModel.fromDto(dto);
    });
  }

  Future<List<StatsTrendPointModel>> getStatsTrends({String range = '30d'}) {
    return _guarded(() async {
      if (!_isAndroid()) return const <StatsTrendPointModel>[];
      final dtos = await _gateway.getStatsTrends(range);
      return dtos.map(StatsTrendPointModel.fromDto).toList();
    });
  }

  Future<OnboardingReadinessModel> getOnboardingReadiness() {
    return _guarded(() async {
      if (!_isAndroid()) {
        return const OnboardingReadinessModel(
          exactAlarmReady: false,
          notificationsReady: false,
          channelsReady: false,
          batteryOptimizationRisk: 'unknown',
          directBootReady: false,
          nativeRingPipelineEnabled: kNativeRingPipelineEnabled,
          legacyFallbackDefaultEnabled: kLegacyEmergencyRingFallbackEnabled,
        );
      }
      final dto = await _gateway.getOnboardingReadiness();
      return OnboardingReadinessModel.fromDto(dto);
    });
  }

  Future<void> syncAlarms(List<AlarmRecord> alarms) {
    return _guarded(() async {
      if (!_isAndroid()) return;

      final existing = await getUpcomingAlarms();
      final existingById = {for (final a in existing) a.id: a};
      final nextById = {for (final a in alarms) a.id: a};

      for (final alarm in alarms) {
        if (existingById.containsKey(alarm.id)) {
          await updateAlarm(alarm);
        } else {
          await createAlarm(alarm);
        }
      }

      for (final id in existingById.keys) {
        if (!nextById.containsKey(id)) {
          await deleteAlarm(id);
        }
      }
    });
  }

  Future<String> _safeTimezone() async {
    try {
      return await _timezoneProvider();
    } catch (_) {
      return 'UTC';
    }
  }

  List<int> _derivePreReminderMinutes(AlarmRecord record) {
    if (record.reminderOffsetsMinutes.isNotEmpty) {
      return record.reminderOffsetsMinutes;
    }
    if (record.anchorUtcMillis != null) {
      return const <int>[10080, 1440, 60];
    }
    if (record.repeatDays.contains('Daily')) {
      return const <int>[60];
    }
    if (record.repeatDays.length >= 5) {
      return const <int>[60, 1440];
    }
    if (record.repeatDays.isEmpty) {
      return const <int>[60];
    }
    return const <int>[];
  }

  List<int> _deriveReminderOffsets(AlarmRecord record) {
    if (record.reminderOffsetsMinutes.isNotEmpty) {
      return record.reminderOffsetsMinutes;
    }
    return _derivePreReminderMinutes(record);
  }

  bool _isAndroid() => _isAndroidResolver();

  Future<T> _guarded<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PlatformException {
      rethrow;
    } catch (error) {
      throw PlatformException(
        code: 'guardian_platform_unexpected',
        message: error.toString(),
      );
    }
  }

  static Future<String> _defaultTimezoneProvider() async {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    return tzInfo.identifier;
  }
}
