import 'package:alarmmaster/features/history/domain/history_record.dart';
import 'package:alarmmaster/features/history/domain/history_repository.dart';
import 'package:alarmmaster/features/history/state/history_controller.dart';
import 'package:alarmmaster/features/reliability/domain/reliability_repository.dart';
import 'package:alarmmaster/features/reliability/state/reliability_controller.dart';
import 'package:alarmmaster/platform/guardian_platform_models.dart';
import 'package:alarmmaster/presentation/reliability_settings_screen/reliability_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders reliability screen shell', (tester) async {
    final reliabilityController = ReliabilityController(
      _FakeReliabilityRepository(),
    );
    final historyController = HistoryController(_FakeHistoryRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: ReliabilitySettingsScreen(
          reliabilityController: reliabilityController,
          historyController: historyController,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alarm Reliability'), findsOneWidget);
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

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryRecord>> getRecent({int limit = 25, int? alarmId}) async {
    return const [
      HistoryRecord(
        historyId: 1,
        alarmId: 22,
        triggerId: 't',
        eventType: 'RESTORED_AFTER_BOOT',
        occurredAtUtcMillis: 1,
        meta: 'restored=1',
      ),
    ];
  }
}
