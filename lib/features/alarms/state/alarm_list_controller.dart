import '../../../alarm/shared/alarm_record.dart';
import '../domain/alarm_repository.dart';

class AlarmListController {
  AlarmListController(this._repository);

  final AlarmRepository _repository;

  Future<List<AlarmRecord>> getUpcomingAlarms() {
    return _repository.getUpcomingAlarms();
  }

  Future<void> deleteAlarm(int alarmId) {
    return _repository.deleteAlarm(alarmId);
  }

  Future<AlarmRecord?> enableAlarm(int alarmId) {
    return _repository.enableAlarm(alarmId);
  }

  Future<AlarmRecord?> disableAlarm(int alarmId) {
    return _repository.disableAlarm(alarmId);
  }

  Future<bool> hasExactAlarmPermission() {
    return _repository.hasExactAlarmPermission();
  }
}
