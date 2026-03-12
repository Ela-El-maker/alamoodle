import 'package:flutter/material.dart';

class AlarmRecord {
  const AlarmRecord({
    required this.id,
    required this.hour24,
    required this.minute,
    required this.name,
    required this.enabled,
    required this.repeatDays,
    required this.sound,
    required this.challenge,
    required this.snoozeCount,
    required this.snoozeDuration,
    required this.vibration,
    this.anchorUtcMillis,
    this.vibrationProfileId,
    this.escalationPolicy,
    this.nagPolicy,
    this.primaryAction,
    this.challengePolicy,
    this.recurrenceType,
    this.recurrenceInterval,
    this.recurrenceWeekdays = const <int>[],
    this.recurrenceDayOfMonth,
    this.recurrenceOrdinal,
    this.recurrenceOrdinalWeekday,
    this.recurrenceExclusionDates = const <String>[],
    this.reminderOffsetsMinutes = const <int>[],
    this.reminderBeforeOnly = false,
  });

  final int id;
  final int hour24;
  final int minute;
  final String name;
  final bool enabled;
  final List<String> repeatDays;
  final String sound;
  final String challenge;
  final int snoozeCount;
  final int snoozeDuration;
  final bool vibration;
  final int? anchorUtcMillis;
  final String? vibrationProfileId;
  final String? escalationPolicy;
  final String? nagPolicy;
  final String? primaryAction;
  final String? challengePolicy;
  final String? recurrenceType;
  final int? recurrenceInterval;
  final List<int> recurrenceWeekdays;
  final int? recurrenceDayOfMonth;
  final int? recurrenceOrdinal;
  final int? recurrenceOrdinalWeekday;
  final List<String> recurrenceExclusionDates;
  final List<int> reminderOffsetsMinutes;
  final bool reminderBeforeOnly;

  String get period => hour24 >= 12 ? 'PM' : 'AM';

  String get time12 {
    final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  AlarmRecord copyWith({
    int? id,
    int? hour24,
    int? minute,
    String? name,
    bool? enabled,
    List<String>? repeatDays,
    String? sound,
    String? challenge,
    int? snoozeCount,
    int? snoozeDuration,
    bool? vibration,
    int? anchorUtcMillis,
    String? vibrationProfileId,
    String? escalationPolicy,
    String? nagPolicy,
    String? primaryAction,
    String? challengePolicy,
    String? recurrenceType,
    int? recurrenceInterval,
    List<int>? recurrenceWeekdays,
    int? recurrenceDayOfMonth,
    int? recurrenceOrdinal,
    int? recurrenceOrdinalWeekday,
    List<String>? recurrenceExclusionDates,
    List<int>? reminderOffsetsMinutes,
    bool? reminderBeforeOnly,
  }) {
    return AlarmRecord(
      id: id ?? this.id,
      hour24: hour24 ?? this.hour24,
      minute: minute ?? this.minute,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
      challenge: challenge ?? this.challenge,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      vibration: vibration ?? this.vibration,
      anchorUtcMillis: anchorUtcMillis ?? this.anchorUtcMillis,
      vibrationProfileId: vibrationProfileId ?? this.vibrationProfileId,
      escalationPolicy: escalationPolicy ?? this.escalationPolicy,
      nagPolicy: nagPolicy ?? this.nagPolicy,
      primaryAction: primaryAction ?? this.primaryAction,
      challengePolicy: challengePolicy ?? this.challengePolicy,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      recurrenceDayOfMonth: recurrenceDayOfMonth ?? this.recurrenceDayOfMonth,
      recurrenceOrdinal: recurrenceOrdinal ?? this.recurrenceOrdinal,
      recurrenceOrdinalWeekday:
          recurrenceOrdinalWeekday ?? this.recurrenceOrdinalWeekday,
      recurrenceExclusionDates:
          recurrenceExclusionDates ?? this.recurrenceExclusionDates,
      reminderOffsetsMinutes:
          reminderOffsetsMinutes ?? this.reminderOffsetsMinutes,
      reminderBeforeOnly: reminderBeforeOnly ?? this.reminderBeforeOnly,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time12,
      'period': period,
      'name': name,
      'enabled': enabled,
      'repeatDays': repeatDays,
      'sound': sound,
      'challenge': challenge,
      'snoozeCount': snoozeCount,
      'snoozeDuration': snoozeDuration,
      'vibration': vibration,
      'anchorUtcMillis': anchorUtcMillis,
      'vibrationProfileId': vibrationProfileId,
      'escalationPolicy': escalationPolicy,
      'nagPolicy': nagPolicy,
      'primaryAction': primaryAction,
      'challengePolicy': challengePolicy,
      'recurrenceType': recurrenceType,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceWeekdays': recurrenceWeekdays,
      'recurrenceDayOfMonth': recurrenceDayOfMonth,
      'recurrenceOrdinal': recurrenceOrdinal,
      'recurrenceOrdinalWeekday': recurrenceOrdinalWeekday,
      'recurrenceExclusionDates': recurrenceExclusionDates,
      'reminderOffsetsMinutes': reminderOffsetsMinutes,
      'reminderBeforeOnly': reminderBeforeOnly,
    };
  }

  factory AlarmRecord.fromMap(Map<String, dynamic> source) {
    final (hour24, minute) = _parseHourMinute(source);
    final repeatDays =
        (source['repeatDays'] as List?)?.map((d) => d.toString()).toList() ??
        <String>[];

    return AlarmRecord(
      id: source['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      hour24: hour24,
      minute: minute,
      name: (source['name'] as String?) ?? 'Alarm',
      enabled: source['enabled'] != false,
      repeatDays: repeatDays,
      sound: (source['sound'] as String?) ?? 'Default Alarm',
      challenge: normalizeChallenge((source['challenge'] as String?) ?? 'None'),
      snoozeCount: (source['snoozeCount'] as int?) ?? 3,
      snoozeDuration: (source['snoozeDuration'] as int?) ?? 5,
      vibration: source['vibration'] != false,
      anchorUtcMillis: _parseAnchorUtcMillis(source['anchorUtcMillis']),
      vibrationProfileId: source['vibrationProfileId'] as String?,
      escalationPolicy: source['escalationPolicy'] as String?,
      nagPolicy: source['nagPolicy'] as String?,
      primaryAction: source['primaryAction'] as String?,
      challengePolicy: source['challengePolicy'] as String?,
      recurrenceType: source['recurrenceType'] as String?,
      recurrenceInterval: source['recurrenceInterval'] as int?,
      recurrenceWeekdays:
          (source['recurrenceWeekdays'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          const <int>[],
      recurrenceDayOfMonth: source['recurrenceDayOfMonth'] as int?,
      recurrenceOrdinal: source['recurrenceOrdinal'] as int?,
      recurrenceOrdinalWeekday: source['recurrenceOrdinalWeekday'] as int?,
      recurrenceExclusionDates:
          (source['recurrenceExclusionDates'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      reminderOffsetsMinutes:
          (source['reminderOffsetsMinutes'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          const <int>[],
      reminderBeforeOnly: source['reminderBeforeOnly'] == true,
    );
  }

  static AlarmRecord? fromCreationResult(
    Map<String, dynamic> result, {
    required int nextId,
  }) {
    final time = result['time'];
    if (time is! TimeOfDay) return null;

    final List<bool> selectedDays =
        (result['days'] as List?)
            ?.map((e) => e == true)
            .toList()
            .cast<bool>() ??
        List<bool>.filled(7, false);
    final List<String> repeatDays = selectedDaysToNames(
      selectedDays,
      repeatMode: result['repeatMode'] as String?,
    );

    final hour24 = time.hour;
    final minute = time.minute;

    return AlarmRecord(
      id: nextId,
      hour24: hour24,
      minute: minute,
      name: (result['label'] as String?)?.trim().isNotEmpty == true
          ? (result['label'] as String).trim()
          : 'Alarm',
      enabled: result['enabled'] != false,
      repeatDays: repeatDays,
      sound: (result['sound'] as String?) ?? 'Default Alarm',
      challenge: normalizeChallenge((result['challenge'] as String?) ?? 'None'),
      snoozeCount: (result['snoozeCount'] as int?) ?? 3,
      snoozeDuration: (result['snoozeDuration'] as int?) ?? 5,
      vibration: true,
      anchorUtcMillis: _parseAnchorUtcMillis(result['anchorUtcMillis']),
      vibrationProfileId: result['vibrationProfileId'] as String?,
      escalationPolicy: result['escalationPolicy'] as String?,
      nagPolicy: result['nagPolicy'] as String?,
      primaryAction: result['primaryAction'] as String?,
      challengePolicy: result['challengePolicy'] as String?,
      recurrenceType: result['recurrenceType'] as String?,
      recurrenceInterval: result['recurrenceInterval'] as int?,
      recurrenceWeekdays:
          (result['recurrenceWeekdays'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          const <int>[],
      recurrenceDayOfMonth: result['recurrenceDayOfMonth'] as int?,
      recurrenceOrdinal: result['recurrenceOrdinal'] as int?,
      recurrenceOrdinalWeekday: result['recurrenceOrdinalWeekday'] as int?,
      recurrenceExclusionDates:
          (result['recurrenceExclusionDates'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      reminderOffsetsMinutes:
          (result['reminderOffsetsMinutes'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          const <int>[],
      reminderBeforeOnly: result['reminderBeforeOnly'] == true,
    );
  }

  static String normalizeChallenge(String challenge) {
    switch (challenge) {
      case 'Math':
        return 'Math Puzzle';
      case 'Memory':
        return 'Memory Tiles';
      case 'Walking':
      case 'Walk':
        return 'Walking Counter';
      case 'Shake':
        return 'Shake Phone';
      case 'QR Code':
        return 'QR Scanner';
      default:
        return challenge;
    }
  }

  static List<String> selectedDaysToNames(
    List<bool> selected, {
    String? repeatMode,
  }) {
    if (repeatMode == 'weekdays') {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    }
    if (repeatMode == 'everyday') return ['Daily'];
    if (repeatMode == 'custom') {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final custom = <String>[];
      for (int i = 0; i < names.length && i < selected.length; i++) {
        if (selected[i]) custom.add(names[i]);
      }
      return custom.isEmpty ? ['Daily'] : custom;
    }
    return <String>[];
  }

  static (int, int) _parseHourMinute(Map<String, dynamic> source) {
    final time = (source['time'] as String?) ?? '06:30';
    final parts = time.split(':');
    int hour = int.tryParse(parts.first) ?? 6;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30;
    final period = (source['period'] as String?) ?? 'AM';

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return (hour, minute);
  }

  static int? _parseAnchorUtcMillis(dynamic source) {
    if (source == null) return null;
    if (source is int) return source;
    if (source is String) return int.tryParse(source);
    return null;
  }
}
