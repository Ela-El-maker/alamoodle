import 'package:alarmmaster/alarm/shared/alarm_record.dart';
import 'package:alarmmaster/platform/gen/guardian_api.g.dart';
import 'package:alarmmaster/platform/guardian_platform_api.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuardianPlatformApi smoke', () {
    test('createAlarm success returns typed AlarmRecord', () async {
      final fakeGateway = _FakeGateway(
        createAlarmHandler: (command) async {
          return _planDto(
            alarmId: command.alarmId!,
            title: command.title,
            hour24: command.hour24,
            minute: command.minute,
            anchorUtcMillis: command.anchorUtcMillis,
          );
        },
      );
      final api = GuardianPlatformApi(
        gateway: fakeGateway,
        timezoneProvider: () async => 'UTC',
        isAndroidResolver: () => true,
      );

      final result = await api.createAlarm(
        const AlarmRecord(
          id: 101,
          hour24: 15,
          minute: 0,
          name: 'Doctor',
          enabled: true,
          repeatDays: [],
          sound: 'Default Alarm',
          challenge: 'None',
          snoozeCount: 3,
          snoozeDuration: 5,
          vibration: true,
          anchorUtcMillis: 1_776_700_800_000,
        ),
      );

      expect(result.id, 101);
      expect(result.name, 'Doctor');
      expect(result.hour24, 15);
      expect(result.anchorUtcMillis, 1_776_700_800_000);
    });

    test('getUpcomingAlarms success returns typed list', () async {
      final fakeGateway = _FakeGateway(
        getUpcomingAlarmsHandler: () async => [
          _planDto(alarmId: 1, title: 'A', hour24: 6, minute: 30),
          _planDto(alarmId: 2, title: 'B', hour24: 7, minute: 45),
        ],
      );
      final api = GuardianPlatformApi(
        gateway: fakeGateway,
        timezoneProvider: () async => 'UTC',
        isAndroidResolver: () => true,
      );

      final alarms = await api.getUpcomingAlarms();

      expect(alarms.length, 2);
      expect(alarms.first.id, 1);
      expect(alarms.first.name, 'A');
      expect(alarms.last.id, 2);
    });

    test('native PlatformException is propagated cleanly', () async {
      final fakeGateway = _FakeGateway(
        createAlarmHandler: (_) async =>
            throw PlatformException(code: 'native_error', message: 'boom'),
      );
      final api = GuardianPlatformApi(
        gateway: fakeGateway,
        timezoneProvider: () async => 'UTC',
        isAndroidResolver: () => true,
      );

      expect(
        () => api.createAlarm(
          const AlarmRecord(
            id: 7,
            hour24: 8,
            minute: 10,
            name: 'Err',
            enabled: true,
            repeatDays: [],
            sound: 'Default Alarm',
            challenge: 'None',
            snoozeCount: 3,
            snoozeDuration: 5,
            vibration: true,
          ),
        ),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'native_error',
          ),
        ),
      );
    });

    test('sound/stats/onboarding methods return typed native models', () async {
      final fakeGateway = _FakeGateway();
      final api = GuardianPlatformApi(
        gateway: fakeGateway,
        timezoneProvider: () async => 'UTC',
        isAndroidResolver: () => true,
      );

      final sounds = await api.getSoundCatalog();
      final summary = await api.getStatsSummary(range: '7d');
      final trends = await api.getStatsTrends(range: '7d');
      final readiness = await api.getOnboardingReadiness();

      expect(sounds, isNotEmpty);
      expect(sounds.first.id, 'default_alarm');
      expect(summary.totalFired, 10);
      expect(trends.length, 1);
      expect(readiness.nativeRingPipelineEnabled, isTrue);
    });

    test('template/backup/oem/preview methods return typed values', () async {
      final fakeGateway = _FakeGateway();
      final api = GuardianPlatformApi(
        gateway: fakeGateway,
        timezoneProvider: () async => 'UTC',
        isAndroidResolver: () => true,
      );

      final templates = await api.getTemplates();
      final imported = await api.importBackup('{}');
      final guidance = await api.getOemGuidance();
      final preview = await api.previewPlannedTriggers(
        const AlarmRecord(
          id: 1,
          hour24: 7,
          minute: 30,
          name: 'Preview',
          enabled: true,
          repeatDays: [],
          sound: 'Default Alarm',
          challenge: 'None',
          snoozeCount: 3,
          snoozeDuration: 5,
          vibration: true,
        ),
      );

      expect(templates, isEmpty);
      expect(imported.success, isTrue);
      expect(guidance.manufacturer, 'generic');
      expect(preview, isEmpty);
    });
  });
}

class _FakeGateway implements GuardianAlarmGateway {
  _FakeGateway({this.createAlarmHandler, this.getUpcomingAlarmsHandler});

  final Future<AlarmPlanDto> Function(CreateAlarmCommandDto command)?
  createAlarmHandler;
  final Future<List<AlarmPlanDto>> Function()? getUpcomingAlarmsHandler;

  @override
  Future<AlarmPlanDto> createAlarm(CreateAlarmCommandDto command) async {
    return createAlarmHandler?.call(command) ??
        _planDto(alarmId: command.alarmId ?? 1, title: command.title);
  }

  @override
  Future<void> deleteAlarm(int alarmId) async {
    return;
  }

  @override
  Future<AlarmPlanDto> disableAlarm(int alarmId) async {
    return _planDto(alarmId: alarmId, title: 'Disabled');
  }

  @override
  Future<AlarmPlanDto> enableAlarm(int alarmId) async {
    return _planDto(alarmId: alarmId, title: 'Enabled');
  }

  @override
  Future<AlarmPlanDto?> getAlarmDetail(int alarmId) async {
    return _planDto(alarmId: alarmId, title: 'Detail');
  }

  @override
  Future<List<AlarmPlanDto>> getUpcomingAlarms() async {
    return getUpcomingAlarmsHandler?.call() ?? <AlarmPlanDto>[];
  }

  @override
  Future<ReliabilitySnapshotDto> getReliabilitySnapshot() async {
    return ReliabilitySnapshotDto(
      exactAlarmPermissionGranted: true,
      notificationsPermissionGranted: true,
      canScheduleExactAlarms: true,
      engineMode: 'shadow_native',
      schedulerHealth: 'healthy',
      nativeRingPipelineEnabled: true,
      legacyEmergencyRingFallbackEnabled: true,
      directBootReady: true,
      channelHealth: 'healthy',
      fullScreenReady: true,
      batteryOptimizationRisk: 'low',
      scheduleRegistryHealth: 'healthy',
      lastRecoveryReason: 'STARTUP_SANITY',
      lastRecoveryAtUtcMillis: 1,
      lastRecoveryStatus: 'ok',
      legacyFallbackDefaultEnabled: false,
    );
  }

  @override
  Future<String> exportDiagnostics() async => '{}';

  @override
  Future<List<AlarmHistoryDto>> getAlarmHistory(int alarmId) async =>
      <AlarmHistoryDto>[];

  @override
  Future<List<AlarmHistoryDto>> getRecentHistory(
    int limit,
    int? alarmId,
  ) async => <AlarmHistoryDto>[];

  @override
  Future<bool> openSystemSettings(String target) async => true;

  @override
  Future<TestAlarmResultDto> runTestAlarm() async {
    return TestAlarmResultDto(
      success: true,
      message: 'ok',
      scheduledAtUtcMillis: 1,
    );
  }

  @override
  Future<AlarmPlanDto> updateAlarm(UpdateAlarmCommandDto command) async {
    return _planDto(alarmId: command.alarmId, title: command.title);
  }

  @override
  Future<List<SoundProfileDto>> getSoundCatalog() async => [
    SoundProfileDto(
      id: 'default_alarm',
      name: 'Default Alarm',
      tag: 'Classic',
      category: 'recommended',
      vibrationProfileIds: const ['default'],
    ),
  ];

  @override
  Future<StatsSummaryDto> getStatsSummary(String range) async {
    return StatsSummaryDto(
      totalFired: 10,
      totalDismissed: 8,
      totalSnoozed: 2,
      totalMissed: 1,
      repairedCount: 1,
      dismissRate: 0.8,
      snoozeRate: 0.2,
      streakDays: 4,
    );
  }

  @override
  Future<List<StatsTrendPointDto>> getStatsTrends(String range) async => [
    StatsTrendPointDto(
      dayUtcStartMillis: 1,
      fired: 2,
      dismissed: 1,
      snoozed: 1,
      missed: 0,
      repaired: 0,
    ),
  ];

  @override
  Future<OnboardingReadinessDto> getOnboardingReadiness() async {
    return OnboardingReadinessDto(
      exactAlarmReady: true,
      notificationsReady: true,
      channelsReady: true,
      batteryOptimizationRisk: 'low',
      directBootReady: true,
      nativeRingPipelineEnabled: true,
      legacyFallbackDefaultEnabled: false,
    );
  }

  @override
  Future<bool> previewSound(String soundId) async => true;

  @override
  Future<bool> stopSoundPreview() async => true;

  @override
  Future<List<TemplateDto>> getTemplates() async => const <TemplateDto>[];

  @override
  Future<TemplateDto> saveTemplate(TemplateDto template) async => template;

  @override
  Future<void> deleteTemplate(int templateId) async {}

  @override
  Future<TemplateDto?> applyTemplate(int templateId) async => null;

  @override
  Future<String> exportBackup() async => '{}';

  @override
  Future<BackupImportResultDto> importBackup(String payload) async {
    return BackupImportResultDto(
      success: true,
      message: 'ok',
      restoredAlarms: 1,
      restoredTemplates: 1,
    );
  }

  @override
  Future<OemGuidanceDto> getOemGuidance() async {
    return OemGuidanceDto(
      manufacturer: 'generic',
      title: 'guidance',
      summary: 'summary',
      steps: const <String>[],
      settingsTargets: const <String>[],
    );
  }

  @override
  Future<List<TriggerDto>> previewPlannedTriggers(
    CreateAlarmCommandDto command,
  ) async => const <TriggerDto>[];
}

AlarmPlanDto _planDto({
  required int alarmId,
  required String title,
  int hour24 = 6,
  int minute = 30,
  int? anchorUtcMillis,
}) {
  return AlarmPlanDto(
    alarmId: alarmId,
    title: title,
    hour24: hour24,
    minute: minute,
    repeatDays: const [],
    enabled: true,
    sound: 'Default Alarm',
    challenge: 'None',
    snoozeCount: 3,
    snoozeDuration: 5,
    vibration: true,
    vibrationProfileId: null,
    escalationPolicy: null,
    nagPolicy: null,
    primaryAction: null,
    challengePolicy: null,
    anchorUtcMillis: anchorUtcMillis,
    timezoneId: 'UTC',
    timezonePolicy: 'FIXED_LOCAL_TIME',
    preReminderMinutes: const <int>[60],
    recurrenceType: null,
    recurrenceInterval: null,
    recurrenceWeekdays: const <int>[],
    recurrenceDayOfMonth: null,
    recurrenceOrdinal: null,
    recurrenceOrdinalWeekday: null,
    recurrenceExclusionDates: const <String>[],
    reminderOffsetsMinutes: const <int>[60],
    reminderBeforeOnly: false,
    createdAtUtcMillis: 1,
    updatedAtUtcMillis: 1,
    triggers: const [],
  );
}
