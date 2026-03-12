import '../../../platform/guardian_platform_models.dart';

abstract class ReliabilityRepository {
  Future<ReliabilitySnapshotModel> getSnapshot();
  Future<TestAlarmResultModel> runTestAlarm();
  Future<bool> openSystemSettings(String target);
  Future<String> exportDiagnostics();
  Future<String> exportBackup();
  Future<BackupImportResultModel> importBackup(String payload);
  Future<OemGuidanceModel> getOemGuidance();
}
