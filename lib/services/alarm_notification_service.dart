import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Top-level background notification response handler (required by flutter_local_notifications)
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Background handler — navigation not possible here
  debugPrint('[AlarmNotification] Background tap: ${response.payload}');
}

class AlarmNotificationService {
  // Sprint 1 note:
  // This service remains as a temporary fallback ringing path while the
  // native Android core is introduced in shadow mode.
  // Do not add new source-of-truth alarm logic here.
  AlarmNotificationService._();
  static final AlarmNotificationService instance = AlarmNotificationService._();
  static const int _weekdayOffset = 1000000;
  static const int _snoozeOffset = 2000000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Navigation callback set from main.dart after MaterialApp is ready
  void Function(String payload)? onNotificationTap;

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Timezone setup
    tz.initializeTimeZones();
    if (!kIsWeb) {
      try {
        final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (_) {
        // Fall back to UTC if timezone detection fails
      }
    }

    // 2. Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload ?? '';
        onNotificationTap?.call(payload);
      },
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // 4. Create high-priority alarm channel on Android
    if (!kIsWeb && Platform.isAndroid) {
      await _createAlarmChannel();
    }

    _initialized = true;
    debugPrint('[AlarmNotification] Initialized successfully');
  }

  Future<void> _createAlarmChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarms',
      description: 'High-priority alarm notifications that wake the device',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // ─── Permission Request ─────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isIOS) {
      final bool? granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Request POST_NOTIFICATIONS (Android 13+)
      final bool? notifGranted = await androidPlugin
          ?.requestNotificationsPermission();

      // Request SCHEDULE_EXACT_ALARM (Android 12+)
      final bool? exactGranted = await androidPlugin
          ?.requestExactAlarmsPermission();

      return (notifGranted ?? true) && (exactGranted ?? true);
    }

    return true;
  }

  Future<bool> hasExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  // ─── Schedule Alarm ─────────────────────────────────────────────────────────

  /// Schedule a single or repeating alarm notification.
  ///
  /// [alarmId]     — unique integer ID
  /// [hour]        — 0-23
  /// [minute]      — 0-59
  /// [label]       — alarm label shown in notification
  /// [soundName]   — sound name for payload
  /// [challenge]   — challenge type for payload
  /// [repeatDays]  — list of weekday ints (1=Mon … 7=Sun). Empty = once.
  Future<bool> scheduleAlarm({
    required int alarmId,
    required int hour,
    required int minute,
    required String label,
    String soundName = 'Default Alarm',
    String challenge = 'None',
    List<int> repeatDays = const [],
  }) async {
    if (kIsWeb) return false;
    if (!_initialized) await initialize();

    try {
      final String payload = '$alarmId|$label|$soundName|$challenge';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'alarm_channel',
            'Alarms',
            channelDescription: 'Alarm notifications',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
            ongoing: false,
            autoCancel: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (repeatDays.isEmpty) {
        // One-time alarm
        final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
        await _plugin.zonedSchedule(
          alarmId,
          label.isEmpty ? 'Alarm' : label,
          _formatTime(hour, minute),
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else if (repeatDays.length == 7) {
        // Daily — use time component matching
        final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
        await _plugin.zonedSchedule(
          alarmId,
          label.isEmpty ? 'Alarm' : label,
          _formatTime(hour, minute),
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } else {
        // Specific weekdays — schedule one notification per day with offset IDs
        for (int i = 0; i < repeatDays.length; i++) {
          final int dayId = _weekdayNotificationId(alarmId, repeatDays[i]);
          final tz.TZDateTime scheduledDate = _nextInstanceOfWeekday(
            repeatDays[i],
            hour,
            minute,
          );
          await _plugin.zonedSchedule(
            dayId,
            label.isEmpty ? 'Alarm' : label,
            _formatTime(hour, minute),
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        }
      }

      debugPrint(
        '[AlarmNotification] Scheduled alarm $alarmId at $hour:$minute repeatDays=$repeatDays',
      );
      return true;
    } catch (e) {
      debugPrint('[AlarmNotification] Failed to schedule alarm: $e');
      return false;
    }
  }

  // ─── Cancel Alarm ───────────────────────────────────────────────────────────

  Future<void> cancelAlarm(
    int alarmId, {
    List<int> repeatDays = const [],
  }) async {
    if (kIsWeb) return;
    try {
      if (repeatDays.isEmpty || repeatDays.length == 7) {
        await _plugin.cancel(alarmId);
      } else {
        for (final day in repeatDays) {
          await _plugin.cancel(_weekdayNotificationId(alarmId, day));
        }
      }
      debugPrint('[AlarmNotification] Cancelled alarm $alarmId');
    } catch (e) {
      debugPrint('[AlarmNotification] Failed to cancel alarm: $e');
    }
  }

  // ─── Snooze Alarm ───────────────────────────────────────────────────────────

  /// Reschedule an alarm [snoozeMinutes] minutes from now as a one-time
  /// notification. Uses a derived snooze ID (alarmId + 9000) to avoid
  /// colliding with the original alarm IDs.
  ///
  /// Returns the snooze notification ID on success, or -1 on failure.
  Future<int> snoozeAlarm({
    required int alarmId,
    required String label,
    int snoozeMinutes = 5,
    String soundName = 'Default Alarm',
    String challenge = 'None',
  }) async {
    if (kIsWeb) return -1;
    if (!_initialized) await initialize();

    try {
      final int snoozeId = _snoozeNotificationId(alarmId);
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime snoozeTime = now.add(
        Duration(minutes: snoozeMinutes),
      );

      final String payload = '$alarmId|$label|$soundName|$challenge|snooze';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'alarm_channel',
            'Alarms',
            channelDescription: 'Alarm notifications',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
            ongoing: false,
            autoCancel: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Cancel any existing snooze for this alarm first
      await _plugin.cancel(snoozeId);

      await _plugin.zonedSchedule(
        snoozeId,
        label.isEmpty
            ? 'Alarm (Snoozed)'
            : '${label.isEmpty ? 'Alarm' : label} (Snoozed)',
        'Snoozed · rings in $snoozeMinutes min',
        snoozeTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint(
        '[AlarmNotification] Snoozed alarm $alarmId → snoozeId $snoozeId, rings at $snoozeTime',
      );
      return snoozeId;
    } catch (e) {
      debugPrint('[AlarmNotification] Failed to snooze alarm: $e');
      return -1;
    }
  }

  /// Cancel a previously scheduled snooze for [alarmId].
  Future<void> cancelSnooze(int alarmId) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(_snoozeNotificationId(alarmId));
      debugPrint('[AlarmNotification] Cancelled snooze for alarm $alarmId');
    } catch (e) {
      debugPrint('[AlarmNotification] Failed to cancel snooze: $e');
    }
  }

  Future<void> cancelAllAlarms() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
      debugPrint('[AlarmNotification] All alarms cancelled');
    } catch (e) {
      debugPrint('[AlarmNotification] Failed to cancel all alarms: $e');
    }
  }

  // ─── Re-schedule on Boot ────────────────────────────────────────────────────

  /// Re-schedule all active alarms (call on app startup after loading alarm list).
  Future<void> rescheduleAll(List<Map<String, dynamic>> activeAlarms) async {
    if (kIsWeb) return;
    for (final alarm in activeAlarms) {
      if (alarm['enabled'] != true) continue;
      try {
        final timeStr = alarm['time'] as String? ?? '00:00';
        final parts = timeStr.split(':');
        int hour = int.tryParse(parts[0]) ?? 0;
        final int minute = int.tryParse(parts[1]) ?? 0;
        final String period = alarm['period'] as String? ?? 'AM';
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        final List<int> repeatDays = daysToWeekdays(
          alarm['repeatDays'] as List? ?? [],
        );

        await scheduleAlarm(
          alarmId: alarm['id'] as int? ?? 0,
          hour: hour,
          minute: minute,
          label: alarm['name'] as String? ?? '',
          soundName: alarm['sound'] as String? ?? 'Default Alarm',
          challenge: alarm['challenge'] as String? ?? 'None',
          repeatDays: repeatDays,
        );
      } catch (e) {
        debugPrint('[AlarmNotification] Failed to reschedule alarm: $e');
      }
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  int _weekdayNotificationId(int alarmId, int weekday) {
    return _weekdayOffset + (alarmId * 10) + weekday;
  }

  int _snoozeNotificationId(int alarmId) {
    return _snoozeOffset + alarmId;
  }

  /// Convert day abbreviation list to Dart weekday ints (1=Mon … 7=Sun)
  List<int> daysToWeekdays(List days) {
    const Map<String, int> map = {
      'Mon': DateTime.monday,
      'Tue': DateTime.tuesday,
      'Wed': DateTime.wednesday,
      'Thu': DateTime.thursday,
      'Fri': DateTime.friday,
      'Sat': DateTime.saturday,
      'Sun': DateTime.sunday,
    };
    if (days.contains('Daily')) return List.generate(7, (i) => i + 1);
    return days.map((d) => map[d.toString()]).whereType<int>().toList();
  }
}
