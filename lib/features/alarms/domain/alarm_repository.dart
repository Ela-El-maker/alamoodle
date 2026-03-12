import '../../../alarm/shared/alarm_record.dart';

abstract class AlarmRepository {
  Future<List<AlarmRecord>> getUpcomingAlarms();
  Future<AlarmRecord?> getAlarmDetail(int alarmId);
  Future<AlarmRecord> createAlarm(AlarmRecord alarm);
  Future<AlarmRecord> updateAlarm(AlarmRecord alarm);
  Future<void> deleteAlarm(int alarmId);
  Future<AlarmRecord?> enableAlarm(int alarmId);
  Future<AlarmRecord?> disableAlarm(int alarmId);
  Future<bool> hasExactAlarmPermission();
  Future<void> syncAlarms(List<AlarmRecord> alarms);
}
