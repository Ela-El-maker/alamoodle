import '../../../alarm/shared/alarm_record.dart';
import '../../../platform/guardian_platform_api.dart';
import '../domain/alarm_repository.dart';

class AlarmRepositoryPlatformImpl implements AlarmRepository {
  AlarmRepositoryPlatformImpl({GuardianPlatformApi? api})
    : _api = api ?? GuardianPlatformApi.instance;

  final GuardianPlatformApi _api;

  @override
  Future<AlarmRecord> createAlarm(AlarmRecord alarm) => _api.createAlarm(alarm);

  @override
  Future<void> deleteAlarm(int alarmId) => _api.deleteAlarm(alarmId);

  @override
  Future<AlarmRecord?> disableAlarm(int alarmId) => _api.disableAlarm(alarmId);

  @override
  Future<AlarmRecord?> enableAlarm(int alarmId) => _api.enableAlarm(alarmId);

  @override
  Future<AlarmRecord?> getAlarmDetail(int alarmId) =>
      _api.getAlarmDetail(alarmId);

  @override
  Future<List<AlarmRecord>> getUpcomingAlarms() => _api.getUpcomingAlarms();

  @override
  Future<bool> hasExactAlarmPermission() async {
    final snapshot = await _api.getReliabilitySnapshot();
    return snapshot.canScheduleExactAlarms;
  }

  @override
  Future<void> syncAlarms(List<AlarmRecord> alarms) => _api.syncAlarms(alarms);

  @override
  Future<AlarmRecord> updateAlarm(AlarmRecord alarm) => _api.updateAlarm(alarm);
}
