import '../../services/alarm_notification_service.dart';
import '../shared/alarm_record.dart';
import 'alarm_scheduler_port.dart';

class FlutterAlarmSchedulerAdapter implements AlarmSchedulerPort {
  const FlutterAlarmSchedulerAdapter();

  @override
  Future<bool> requestPermissions() {
    return AlarmNotificationService.instance.requestPermissions();
  }

  @override
  Future<bool> hasExactAlarmPermission() {
    return AlarmNotificationService.instance.hasExactAlarmPermission();
  }

  @override
  Future<bool> scheduleAlarm(AlarmRecord alarm) {
    return AlarmNotificationService.instance.scheduleAlarm(
      alarmId: alarm.id,
      hour: alarm.hour24,
      minute: alarm.minute,
      label: alarm.name,
      soundName: alarm.sound,
      challenge: alarm.challenge,
      repeatDays: AlarmNotificationService.instance.daysToWeekdays(
        alarm.repeatDays,
      ),
    );
  }

  @override
  Future<void> cancelAlarm(AlarmRecord alarm) {
    return AlarmNotificationService.instance.cancelAlarm(
      alarm.id,
      repeatDays: AlarmNotificationService.instance.daysToWeekdays(
        alarm.repeatDays,
      ),
    );
  }

  @override
  Future<void> cancelAllAlarms() {
    return AlarmNotificationService.instance.cancelAllAlarms();
  }

  @override
  Future<void> rescheduleAll(List<AlarmRecord> alarms) {
    return AlarmNotificationService.instance.rescheduleAll(
      alarms.where((a) => a.enabled).map((a) => a.toMap()).toList(),
    );
  }
}
