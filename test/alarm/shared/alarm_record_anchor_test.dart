import 'package:alarmmaster/alarm/shared/alarm_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmRecord anchor mapping', () {
    test('fromCreationResult keeps anchorUtcMillis when provided', () {
      final created = AlarmRecord.fromCreationResult({
        'time': const TimeOfDay(hour: 15, minute: 0),
        'label': 'Doctor',
        'enabled': true,
        'days': List<bool>.filled(7, false),
        'repeatMode': null,
        'anchorUtcMillis': 1_776_700_800_000,
      }, nextId: 42);

      expect(created, isNotNull);
      expect(created!.anchorUtcMillis, 1_776_700_800_000);
      expect(created.id, 42);
    });

    test('fromMap parses string anchorUtcMillis', () {
      final record = AlarmRecord.fromMap({
        'id': 7,
        'time': '10:30',
        'period': 'AM',
        'name': 'Meeting',
        'enabled': true,
        'repeatDays': const <String>[],
        'anchorUtcMillis': '1776700800000',
      });

      expect(record.anchorUtcMillis, 1_776_700_800_000);
    });

    test('fromCreationResult keeps policy payload fields', () {
      final created = AlarmRecord.fromCreationResult({
        'time': const TimeOfDay(hour: 8, minute: 10),
        'label': 'Office',
        'enabled': true,
        'days': List<bool>.filled(7, false),
        'repeatMode': null,
        'vibrationProfileId': 'strong',
        'escalationPolicy':
            '{"enabled":true,"startVolume":0.3,"endVolume":1.0,"stepSeconds":15,"maxSteps":4}',
        'nagPolicy':
            '{"enabled":true,"retryWindowMinutes":60,"maxRetries":3,"retryIntervalMinutes":15}',
        'primaryAction': '{"type":"maps","value":"HQ Nairobi"}',
        'challengePolicy': 'qr',
      }, nextId: 55);

      expect(created, isNotNull);
      expect(created!.vibrationProfileId, 'strong');
      expect(created.escalationPolicy, isNotNull);
      expect(created.nagPolicy, isNotNull);
      expect(created.primaryAction, '{"type":"maps","value":"HQ Nairobi"}');
      expect(created.challengePolicy, 'qr');
    });
  });
}
