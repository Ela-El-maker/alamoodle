import 'package:alarmmaster/alarm/config/alarm_engine_mode.dart';
import 'package:alarmmaster/alarm/platform/alarm_scheduler_port.dart';
import 'package:alarmmaster/alarm/shared/alarm_record.dart';
import 'package:alarmmaster/alarm/shared/alarm_shared_logic_service.dart';
import 'package:alarmmaster/features/alarms/domain/alarm_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleAlarm = AlarmRecord(
    id: 9,
    hour24: 10,
    minute: 0,
    name: 'Meeting',
    enabled: true,
    repeatDays: [],
    sound: 'Default Alarm',
    challenge: 'None',
    snoozeCount: 3,
    snoozeDuration: 5,
    vibration: true,
  );

  group('AlarmSharedLogicService shadow-native guardrails', () {
    test(
      'loadAlarms and setAlarmEnabled use native repository authority when fallback is disabled',
      () async {
        final repository = _FakeAlarmRepository(alarms: const [sampleAlarm]);
        final scheduler = _FakeScheduler();
        final service = AlarmSharedLogicService(
          repository: repository,
          scheduler: scheduler,
          engineMode: AlarmEngineMode.shadowNative,
          legacyDeliveryFallbackEnabled: false,
        );

        final loaded = await service.loadAlarms(
          fallback: const [sampleAlarm],
          resyncSchedules: true,
        );
        final enabled = await service.setAlarmEnabled(sampleAlarm, true);

        expect(loaded, hasLength(1));
        expect(enabled, isTrue);
        expect(repository.getUpcomingCalls, 1);
        expect(repository.enableCalls, [sampleAlarm.id]);
        expect(scheduler.cancelAllCalls, 0);
        expect(scheduler.rescheduleAllCalls, 0);
        expect(scheduler.scheduleCalls, 0);
      },
    );

    test(
      'shadow-native schedule/cancel avoid legacy scheduler when fallback is disabled',
      () async {
        final repository = _FakeAlarmRepository(alarms: const [sampleAlarm]);
        final scheduler = _FakeScheduler();
        final service = AlarmSharedLogicService(
          repository: repository,
          scheduler: scheduler,
          engineMode: AlarmEngineMode.shadowNative,
          legacyDeliveryFallbackEnabled: false,
        );

        await service.scheduleAlarm(sampleAlarm);
        await service.cancelAlarm(sampleAlarm);

        expect(repository.updateCalls, 1);
        expect(repository.disableCalls, [sampleAlarm.id]);
        expect(scheduler.scheduleCalls, 0);
        expect(scheduler.cancelCalls, 0);
      },
    );
  });
}

class _FakeAlarmRepository implements AlarmRepository {
  _FakeAlarmRepository({required this.alarms});

  final List<AlarmRecord> alarms;
  int createCalls = 0;
  int updateCalls = 0;
  int getUpcomingCalls = 0;
  final List<int> enableCalls = <int>[];
  final List<int> disableCalls = <int>[];

  @override
  Future<AlarmRecord> createAlarm(AlarmRecord alarm) async {
    createCalls += 1;
    return alarm;
  }

  @override
  Future<void> deleteAlarm(int alarmId) async {}

  @override
  Future<AlarmRecord?> disableAlarm(int alarmId) async {
    disableCalls.add(alarmId);
    return alarms.firstWhere((a) => a.id == alarmId);
  }

  @override
  Future<AlarmRecord?> enableAlarm(int alarmId) async {
    enableCalls.add(alarmId);
    return alarms.firstWhere((a) => a.id == alarmId);
  }

  @override
  Future<AlarmRecord?> getAlarmDetail(int alarmId) async {
    return alarms.firstWhere((a) => a.id == alarmId);
  }

  @override
  Future<List<AlarmRecord>> getUpcomingAlarms() async {
    getUpcomingCalls += 1;
    return alarms;
  }

  @override
  Future<bool> hasExactAlarmPermission() async => true;

  @override
  Future<void> syncAlarms(List<AlarmRecord> alarms) async {}

  @override
  Future<AlarmRecord> updateAlarm(AlarmRecord alarm) async {
    updateCalls += 1;
    return alarm;
  }
}

class _FakeScheduler implements AlarmSchedulerPort {
  int requestPermissionCalls = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;
  int cancelAllCalls = 0;
  int rescheduleAllCalls = 0;

  @override
  Future<void> cancelAlarm(AlarmRecord alarm) async {
    cancelCalls += 1;
  }

  @override
  Future<void> cancelAllAlarms() async {
    cancelAllCalls += 1;
  }

  @override
  Future<bool> hasExactAlarmPermission() async => true;

  @override
  Future<bool> requestPermissions() async {
    requestPermissionCalls += 1;
    return true;
  }

  @override
  Future<void> rescheduleAll(List<AlarmRecord> alarms) async {
    rescheduleAllCalls += 1;
  }

  @override
  Future<bool> scheduleAlarm(AlarmRecord alarm) async {
    scheduleCalls += 1;
    return true;
  }
}
