import '../../../platform/guardian_platform_models.dart';
import '../domain/reliability_repository.dart';

class ReliabilityController {
  ReliabilityController(this._repository);

  final ReliabilityRepository _repository;

  Future<ReliabilitySnapshotModel> getSnapshot() => _repository.getSnapshot();

  Future<TestAlarmResultModel> runTestAlarm() => _repository.runTestAlarm();

  Future<bool> openSystemSettings(String target) =>
      _repository.openSystemSettings(target);

  Future<String> exportDiagnostics() => _repository.exportDiagnostics();

  Future<String> exportBackup() => _repository.exportBackup();

  Future<BackupImportResultModel> importBackup(String payload) =>
      _repository.importBackup(payload);

  Future<OemGuidanceModel> getOemGuidance() => _repository.getOemGuidance();
}
