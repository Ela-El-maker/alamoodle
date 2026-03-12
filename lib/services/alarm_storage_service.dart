import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmStorageService {
  // Sprint 1 note:
  // Legacy SharedPreferences storage kept only for compatibility while moving
  // to native Room-backed storage via platform APIs.
  AlarmStorageService._();

  static final AlarmStorageService instance = AlarmStorageService._();
  static const String _alarmsKey = 'saved_alarms_v1';

  Future<List<Map<String, dynamic>>> loadAlarms({
    List<Map<String, dynamic>> fallback = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alarmsKey);

    if (raw == null || raw.isEmpty) {
      if (fallback.isNotEmpty) {
        await saveAlarms(fallback);
        return fallback
            .map((alarm) => Map<String, dynamic>.from(alarm))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    } catch (e) {
      debugPrint('[AlarmStorage] Failed to decode alarms: $e');
      return fallback.map((alarm) => Map<String, dynamic>.from(alarm)).toList();
    }
  }

  Future<void> saveAlarms(List<Map<String, dynamic>> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alarms);
    await prefs.setString(_alarmsKey, encoded);
  }
}
