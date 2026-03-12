import '../shared/alarm_record.dart';

abstract class AlarmSchedulerPort {
  Future<bool> requestPermissions();
  Future<bool> hasExactAlarmPermission();
  Future<bool> scheduleAlarm(AlarmRecord alarm);
  Future<void> cancelAlarm(AlarmRecord alarm);
  Future<void> cancelAllAlarms();
  Future<void> rescheduleAll(List<AlarmRecord> alarms);
}
