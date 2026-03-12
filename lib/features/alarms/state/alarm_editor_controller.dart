import '../../../alarm/shared/alarm_record.dart';
import '../domain/alarm_repository.dart';

class AlarmEditorController {
  AlarmEditorController(this._repository);

  final AlarmRepository _repository;

  Future<AlarmRecord> createAlarm(AlarmRecord alarm) {
    return _repository.createAlarm(alarm);
  }

  Future<AlarmRecord> updateAlarm(AlarmRecord alarm) {
    return _repository.updateAlarm(alarm);
  }

  Future<void> syncAlarms(List<AlarmRecord> alarms) {
    return _repository.syncAlarms(alarms);
  }
}
