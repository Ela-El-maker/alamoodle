import '../../../platform/guardian_platform_api.dart';
import '../../../platform/guardian_platform_models.dart';
import '../domain/reliability_repository.dart';

class ReliabilityRepositoryPlatformImpl implements ReliabilityRepository {
  ReliabilityRepositoryPlatformImpl({GuardianPlatformApi? api})
    : _api = api ?? GuardianPlatformApi.instance;

  final GuardianPlatformApi _api;

  @override
  Future<ReliabilitySnapshotModel> getSnapshot() =>
      _api.getReliabilitySnapshot();

  @override
  Future<bool> openSystemSettings(String target) =>
      _api.openSystemSettings(target);

  @override
  Future<TestAlarmResultModel> runTestAlarm() => _api.runTestAlarm();

  @override
  Future<String> exportDiagnostics() => _api.exportDiagnostics();

  @override
  Future<String> exportBackup() => _api.exportBackup();

  @override
  Future<BackupImportResultModel> importBackup(String payload) =>
      _api.importBackup(payload);

  @override
  Future<OemGuidanceModel> getOemGuidance() => _api.getOemGuidance();
}
