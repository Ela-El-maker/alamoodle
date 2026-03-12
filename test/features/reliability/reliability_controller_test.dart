import 'package:alarmmaster/features/reliability/domain/reliability_repository.dart';
import 'package:alarmmaster/features/reliability/state/reliability_controller.dart';
import 'package:alarmmaster/platform/guardian_platform_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reliability controller returns native snapshot', () async {
    final repo = _FakeReliabilityRepository();
    final controller = ReliabilityController(repo);

    final snapshot = await controller.getSnapshot();

    expect(snapshot.engineMode, 'shadow_native');
    expect(snapshot.directBootReady, isTrue);
    expect(snapshot.channelHealth, 'healthy');
  });

  test('run test alarm delegates to repository', () async {
    final repo = _FakeReliabilityRepository();
    final controller = ReliabilityController(repo);

    final result = await controller.runTestAlarm();

    expect(result.success, isTrue);
    expect(result.message, contains('scheduled'));
  });

  test('backup and OEM guidance methods delegate to repository', () async {
    final repo = _FakeReliabilityRepository();
    final controller = ReliabilityController(repo);

    final backup = await controller.exportBackup();
    final importResult = await controller.importBackup('{}');
    final guidance = await controller.getOemGuidance();

    expect(backup, '{}');
    expect(importResult.success, isTrue);
    expect(importResult.restoredAlarms, 1);
    expect(guidance.manufacturer, 'google');
  });
}

class _FakeReliabilityRepository implements ReliabilityRepository {
  @override
  Future<String> exportBackup() async => '{}';

  @override
  Future<String> exportDiagnostics() async => '{}';

  @override
  Future<ReliabilitySnapshotModel> getSnapshot() async {
    return const ReliabilitySnapshotModel(
      exactAlarmPermissionGranted: true,
      notificationsPermissionGranted: true,
      canScheduleExactAlarms: true,
      engineMode: 'shadow_native',
      schedulerHealth: 'healthy',
      nativeRingPipelineEnabled: true,
      legacyEmergencyRingFallbackEnabled: true,
      legacyDeliveryFallbackEnabled: false,
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
  Future<OemGuidanceModel> getOemGuidance() async {
    return const OemGuidanceModel(
      manufacturer: 'google',
      title: 'No OEM issues detected',
      summary: 'Device defaults look healthy.',
      steps: <String>[],
      settingsTargets: <String>[],
    );
  }

  @override
  Future<bool> openSystemSettings(String target) async => true;

  @override
  Future<BackupImportResultModel> importBackup(String payload) async {
    return const BackupImportResultModel(
      success: true,
      message: 'Imported',
      restoredAlarms: 1,
      restoredTemplates: 0,
    );
  }

  @override
  Future<TestAlarmResultModel> runTestAlarm() async {
    return const TestAlarmResultModel(
      success: true,
      message: 'scheduled',
      scheduledAtUtcMillis: 1,
    );
  }
}
