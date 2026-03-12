import 'package:flutter/foundation.dart';

import '../../features/alarms/domain/alarm_repository.dart';
import '../platform/alarm_scheduler_port.dart';
import '../config/alarm_engine_mode.dart';
import 'alarm_record.dart';

class AlarmSharedLogicService {
  AlarmSharedLogicService({
    required AlarmRepository repository,
    required AlarmSchedulerPort scheduler,
    required AlarmEngineMode engineMode,
    bool legacyDeliveryFallbackEnabled = kLegacyDeliveryFallbackEnabled,
  }) : _repository = repository,
       _scheduler = scheduler,
       _engineMode = engineMode,
       _legacyDeliveryFallbackEnabled = legacyDeliveryFallbackEnabled;

  final AlarmRepository _repository;
  final AlarmSchedulerPort _scheduler;
  final AlarmEngineMode _engineMode;
  final bool _legacyDeliveryFallbackEnabled;

  Future<List<AlarmRecord>> loadAlarms({
    required List<AlarmRecord> fallback,
    bool resyncSchedules = false,
  }) async {
    if (_engineMode == AlarmEngineMode.legacy) {
      return fallback;
    }

    final alarms = await _repository.getUpcomingAlarms();

    if (resyncSchedules && _legacyDeliveryFallbackEnabled) {
      debugPrint(
        '[AlarmEngine] op=resync_schedules source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled count=${alarms.length}',
      );
      await _scheduler.cancelAllAlarms();
      await _scheduler.rescheduleAll(alarms);
    }

    return alarms;
  }

  Future<void> persist(List<AlarmRecord> alarms) async {
    if (_engineMode == AlarmEngineMode.legacy) return;
    await _repository.syncAlarms(alarms);
  }

  Future<bool> setAlarmEnabled(AlarmRecord alarm, bool enabled) async {
    if (_engineMode != AlarmEngineMode.legacy) {
      if (enabled) {
        debugPrint(
          '[AlarmEngine] op=enable_alarm source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled alarmId=${alarm.id}',
        );
        await _repository.enableAlarm(alarm.id);
      } else {
        debugPrint(
          '[AlarmEngine] op=disable_alarm source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled alarmId=${alarm.id}',
        );
        await _repository.disableAlarm(alarm.id);
      }
    }

    if (!_legacyDeliveryFallbackEnabled &&
        _engineMode != AlarmEngineMode.legacy) {
      return true;
    }

    if (enabled) {
      debugPrint(
        '[AlarmEngine] op=schedule_fallback_delivery source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled alarmId=${alarm.id}',
      );
      return _scheduler.scheduleAlarm(alarm.copyWith(enabled: true));
    }
    debugPrint(
      '[AlarmEngine] op=cancel_fallback_delivery source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled alarmId=${alarm.id}',
    );
    await _scheduler.cancelAlarm(alarm.copyWith(enabled: false));
    return true;
  }

  Future<void> scheduleAlarm(AlarmRecord alarm) async {
    if (_engineMode != AlarmEngineMode.legacy) {
      await _repository.updateAlarm(alarm.copyWith(enabled: true));
    }
    if (_legacyDeliveryFallbackEnabled ||
        _engineMode == AlarmEngineMode.legacy) {
      debugPrint(
        '[AlarmEngine] op=schedule_alarm source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled alarmId=${alarm.id}',
      );
      await _scheduler.scheduleAlarm(alarm);
    }
  }

  Future<void> cancelAlarm(AlarmRecord alarm) async {
    if (_engineMode != AlarmEngineMode.legacy) {
      await _repository.disableAlarm(alarm.id);
    }
    if (_legacyDeliveryFallbackEnabled ||
        _engineMode == AlarmEngineMode.legacy) {
      debugPrint(
        '[AlarmEngine] op=cancel_alarm source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled alarmId=${alarm.id}',
      );
      await _scheduler.cancelAlarm(alarm);
    }
  }

  Future<void> cancelAllAlarms() async {
    if (_engineMode != AlarmEngineMode.legacy) {
      final alarms = await _repository.getUpcomingAlarms();
      for (final alarm in alarms) {
        await _repository.disableAlarm(alarm.id);
      }
    }
    if (_legacyDeliveryFallbackEnabled ||
        _engineMode == AlarmEngineMode.legacy) {
      debugPrint(
        '[AlarmEngine] op=cancel_all source=native pipeline=native_ring fallback_delivery=$_legacyDeliveryFallbackEnabled',
      );
      await _scheduler.cancelAllAlarms();
    }
  }

  Future<bool> hasExactAlarmPermission() async {
    if (_engineMode == AlarmEngineMode.legacy) {
      return _scheduler.hasExactAlarmPermission();
    }
    return _repository.hasExactAlarmPermission();
  }
}
