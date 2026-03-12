import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../platform/guardian_platform_api.dart';
import '../../widgets/custom_icon_widget.dart';
import '../alarm_creation_screen/widgets/time_picker_widget.dart';
import '../sound_picker_screen/sound_picker_screen.dart';
import './widgets/challenge_sheet_widget.dart';
import './widgets/detail_row_widget.dart';
import './widgets/repeat_sheet_widget.dart';
import './widgets/snooze_sheet_widget.dart';

class AlarmDetailScreen extends StatefulWidget {
  const AlarmDetailScreen({super.key});

  @override
  State<AlarmDetailScreen> createState() => _AlarmDetailScreenState();
}

class _AlarmDetailScreenState extends State<AlarmDetailScreen> {
  final GuardianPlatformApi _platformApi = GuardianPlatformApi.instance;

  bool _loadedArgs = false;
  int _alarmId = 0;
  bool _isEnabled = true;
  String _repeat = 'Weekdays';
  List<bool> _selectedDays = [true, true, true, true, true, false, false];
  String _label = 'Morning Alarm';
  String _sound = 'Morning Bell';
  String _soundId = 'default_alarm';
  int _snoozeDuration = 10;
  int _snoozeCount = 3;
  String _challenge = 'Off';
  bool _vibration = true;
  String _vibrationProfileId = 'default';
  String? _escalationPolicy;
  String? _nagPolicy;
  String? _primaryAction;
  String? _challengePolicy;
  int? _anchorUtcMillis;
  bool _nagEnabled = false;
  int _nagRetryWindowMinutes = 30;
  int _nagMaxRetries = 2;
  int _nagRetryIntervalMinutes = 10;
  bool _use24HourFormat = false;
  bool _snoozeStatsLoading = false;
  int _snoozeTotalCount = 0;
  int _snoozeTodayCount = 0;
  List<DateTime> _recentSnoozeEvents = <DateTime>[];

  TimeOfDay _alarmTime = const TimeOfDay(hour: 6, minute: 30);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    _use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      setState(() {
        _alarmId = args['id'] as int? ?? 0;
        _isEnabled = args['enabled'] as bool? ?? true;
        _label =
            args['name'] as String? ??
            args['label'] as String? ??
            'Morning Alarm';
        _soundId = args['sound'] as String? ?? 'default_alarm';
        _sound = (args['soundName'] as String?) ?? _soundId;
        _snoozeDuration = args['snoozeDuration'] as int? ?? 10;
        _snoozeCount = args['snoozeCount'] as int? ?? 3;
        _challenge = args['challenge'] as String? ?? 'Off';
        _vibration = args['vibration'] as bool? ?? true;
        _vibrationProfileId =
            args['vibrationProfileId'] as String? ?? _vibrationProfileId;
        _escalationPolicy = args['escalationPolicy'] as String?;
        _nagPolicy = args['nagPolicy'] as String?;
        _primaryAction = args['primaryAction'] as String?;
        _challengePolicy = args['challengePolicy'] as String?;
        _anchorUtcMillis = _parseAnchorUtcMillis(args['anchorUtcMillis']);
        _hydrateNagPolicy();
        _alarmTime = _parseTime(
          args['time'] as String? ?? '6:30',
          args['period'] as String? ?? 'AM',
        );
        _selectedDays = _toSelectedDays((args['repeatDays'] as List?) ?? []);
        _repeat = _repeatFromDays(_selectedDays);
      });
      _loadSnoozeStats();
    }
  }

  Future<void> _loadSnoozeStats() async {
    if (_alarmId <= 0) return;
    setState(() => _snoozeStatsLoading = true);

    try {
      final history = await _platformApi.getAlarmHistory(_alarmId);

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      var total = 0;
      var today = 0;
      final recent = <DateTime>[];

      for (final item in history) {
        if (item.eventType != 'SNOOZED') continue;
        total += 1;
        final at = DateTime.fromMillisecondsSinceEpoch(
          item.occurredAtUtcMillis,
          isUtc: true,
        ).toLocal();
        if (!at.isBefore(startOfToday)) {
          today += 1;
        }
        if (recent.length < 5) {
          recent.add(at);
        }
      }

      if (!mounted) return;
      setState(() {
        _snoozeTotalCount = total;
        _snoozeTodayCount = today;
        _recentSnoozeEvents = recent;
        _snoozeStatsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _snoozeStatsLoading = false);
    }
  }

  String get _snoozeHistorySummary {
    if (_snoozeStatsLoading) return 'Loading...';
    if (_snoozeTotalCount == 0) return 'Never snoozed';
    if (_snoozeTodayCount > 0) {
      return '$_snoozeTotalCount total • $_snoozeTodayCount today';
    }
    return '$_snoozeTotalCount total';
  }

  String _formatSnoozeEvent(DateTime dateTime) {
    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[dateTime.weekday - 1];
    return '$weekday • ${_formatTime(TimeOfDay.fromDateTime(dateTime))}';
  }

  void _showSnoozeHistorySheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 10.w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Snooze History',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 1.2.h),
              Text(
                'Total snoozes: $_snoozeTotalCount',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFB8B8B8),
                ),
              ),
              Text(
                'Today: $_snoozeTodayCount',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFB8B8B8),
                ),
              ),
              SizedBox(height: 1.8.h),
              if (_recentSnoozeEvents.isEmpty)
                Text(
                  'No snooze events yet.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF8A8A8A),
                  ),
                )
              else ...[
                Text(
                  'Recent snoozes',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFA24A),
                  ),
                ),
                SizedBox(height: 1.h),
                ..._recentSnoozeEvents.map(
                  (event) => Padding(
                    padding: EdgeInsets.only(bottom: 0.8.h),
                    child: Text(
                      _formatSnoozeEvent(event),
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFFB8B8B8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _repeatDisplay {
    if (_repeat == 'Custom') {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final active = <String>[];
      for (int i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) active.add(days[i]);
      }
      return active.isEmpty ? 'Never' : active.join(', ');
    }
    return _repeat;
  }

  void _showRepeatSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RepeatSheetWidget(
        currentRepeat: _repeat,
        selectedDays: _selectedDays,
        onChanged: (repeat, days) {
          setState(() {
            _repeat = repeat;
            _selectedDays = days;
          });
        },
      ),
    );
  }

  DateTime? get _anchorLocalDateTime {
    if (_anchorUtcMillis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      _anchorUtcMillis!,
      isUtc: true,
    ).toLocal();
  }

  String get _anchorDisplay {
    final date = _anchorLocalDateTime;
    if (date == null) return 'None';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  DateTime? _computeNextRingDateTime() {
    final now = DateTime.now();

    DateTime candidateForDate(DateTime date) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        _alarmTime.hour,
        _alarmTime.minute,
      );
    }

    final anchor = _anchorLocalDateTime;
    if (anchor != null) {
      return candidateForDate(anchor);
    }

    if (_repeat == 'Every day') {
      final today = candidateForDate(now);
      if (!today.isBefore(now)) return today;
      return today.add(const Duration(days: 1));
    }

    if (_repeat == 'Weekdays' || _repeat == 'Custom') {
      for (int dayOffset = 0; dayOffset <= 14; dayOffset++) {
        final day = now.add(Duration(days: dayOffset));
        final weekdayIndex = day.weekday - 1; // Mon=0 ... Sun=6
        final isAllowed = _repeat == 'Weekdays'
            ? weekdayIndex >= 0 && weekdayIndex <= 4
            : (weekdayIndex >= 0 &&
                  weekdayIndex < _selectedDays.length &&
                  _selectedDays[weekdayIndex]);
        if (!isAllowed) continue;
        final candidate = candidateForDate(day);
        if (!candidate.isBefore(now)) return candidate;
      }
      return null;
    }

    // Once / fallback
    final today = candidateForDate(now);
    if (!today.isBefore(now)) return today;
    return today.add(const Duration(days: 1));
  }

  String _timeUntilNextRingLabel() {
    if (!_isEnabled) return 'Alarm is currently disabled';
    final target = _computeNextRingDateTime();
    if (target == null) return 'No upcoming ring scheduled';

    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.inSeconds <= 30) return 'Ringing soon';

    final totalMinutes = diff.inMinutes;
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final minutes = totalMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');

    return '${parts.join(' ')} from now';
  }

  String _nextRingAbsoluteLabel() {
    final target = _computeNextRingDateTime();
    if (target == null) return 'No upcoming schedule';

    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[target.weekday - 1];
    final month = months[target.month - 1];
    return '$weekday, $month ${target.day} • ${_formatTime(TimeOfDay.fromDateTime(target))}';
  }

  Future<void> _showAnchorDateSheet() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final initial = _anchorLocalDateTime ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    final local = DateTime(
      picked.year,
      picked.month,
      picked.day,
      _alarmTime.hour,
      _alarmTime.minute,
    );
    setState(() {
      _anchorUtcMillis = local.toUtc().millisecondsSinceEpoch;
    });
  }

  void _clearAnchorDate() {
    HapticFeedback.selectionClick();
    setState(() => _anchorUtcMillis = null);
  }

  Future<void> _showTimeSheet() async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var tempTime = _alarmTime;
        var tempUse24HourFormat = _use24HourFormat;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                color: Color(0xFF151515),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 10.w,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFFB8B8B8),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Select time',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, {
                            'time': tempTime,
                            'use24HourFormat': tempUse24HourFormat,
                          }),
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF7A1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2D2D2D)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FormatToggleButton(
                              label: '12-hour',
                              selected: !tempUse24HourFormat,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(
                                  () => tempUse24HourFormat = false,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _FormatToggleButton(
                              label: '24-hour',
                              selected: tempUse24HourFormat,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() => tempUse24HourFormat = true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.4.h),
                    TimePickerWidget(
                      key: ValueKey<bool>(tempUse24HourFormat),
                      selectedTime: tempTime,
                      use24HourFormat: tempUse24HourFormat,
                      onTimeChanged: (time) {
                        setSheetState(() => tempTime = time);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    final picked = result['time'] as TimeOfDay?;
    final use24HourFormat = result['use24HourFormat'] as bool?;
    if (picked == null) return;

    setState(() {
      _alarmTime = picked;
      _use24HourFormat = use24HourFormat ?? _use24HourFormat;
      if (_anchorUtcMillis != null) {
        final anchor = _anchorLocalDateTime!;
        final local = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          picked.hour,
          picked.minute,
        );
        _anchorUtcMillis = local.toUtc().millisecondsSinceEpoch;
      }
    });
  }

  void _showLabelSheet() {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: _label);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: const BoxDecoration(
            color: Color(0xFF151515),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 10.w,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Alarm Label',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(fontSize: 13.sp, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Morning workout',
                    hintStyle: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 13.sp,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Color(0xFF2D2D2D)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(color: Color(0xFF2D2D2D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF7A1A),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(
                        () => _label = controller.text.trim().isEmpty
                            ? 'Alarm'
                            : controller.text.trim(),
                      );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A1A),
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSoundSheet() {
    HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true)
        .push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => SoundPickerScreen(selectedSoundId: _soundId),
          ),
        )
        .then((result) {
          if (!mounted || result == null) return;
          setState(() {
            _soundId = (result['soundId'] as String?) ?? _soundId;
            _sound = (result['soundName'] as String?) ?? _sound;
            _vibrationProfileId =
                (result['vibrationProfileId'] as String?) ??
                _vibrationProfileId;
            _escalationPolicy = result['escalationPolicy'] as String?;
          });
        });
  }

  void _showSnoozeSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SnoozeSheetWidget(
        duration: _snoozeDuration,
        count: _snoozeCount,
        onChanged: (duration, count) {
          setState(() {
            _snoozeDuration = duration;
            _snoozeCount = count;
          });
        },
      ),
    );
  }

  void _showChallengeSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChallengeSheetWidget(
        currentChallenge: _challenge,
        onChanged: (challenge) {
          setState(() => _challenge = challenge);
        },
      ),
    );
  }

  void _showVibrationSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 10.w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Vibration',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2.h),
              _buildVibrationOption(
                ctx,
                true,
                'On',
                'Vibrate when alarm rings',
              ),
              SizedBox(height: 1.h),
              _buildVibrationOption(ctx, false, 'Off', 'No vibration'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibrationOption(
    BuildContext ctx,
    bool value,
    String title,
    String subtitle,
  ) {
    final isSelected = _vibration == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _vibration = value);
        Navigator.pop(ctx);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A1A).withValues(alpha: 0.15)
              : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A1A)
                : const Color(0xFF2D2D2D),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFFF7A1A)
                          : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFFB8B8B8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                color: const Color(0xFFFF7A1A),
                size: 5.w,
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          'Delete Alarm',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this alarm? This cannot be undone.',
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB8B8B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB8B8B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop({'deleted': true, 'id': _alarmId});
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF453A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final minute = time.minute.toString().padLeft(2, '0');
    if (_use24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:$minute';
    }
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _parseTime(String time, String period) {
    final parts = time.split(':');
    int hour = int.tryParse(parts.first) ?? 6;
    final int minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30;

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  List<bool> _toSelectedDays(List repeatDays) {
    final source = repeatDays.map((d) => d.toString()).toSet();
    if (source.contains('Daily')) return List<bool>.filled(7, true);
    const keys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return keys.map((d) => source.contains(d)).toList();
  }

  String _repeatFromDays(List<bool> selected) {
    if (selected.every((d) => d)) return 'Every day';
    if (selected.take(5).every((d) => d) && !selected[5] && !selected[6]) {
      return 'Weekdays';
    }
    if (selected.every((d) => !d)) return 'Once';
    return 'Custom';
  }

  List<String> _repeatDaysFromSelection() {
    if (_repeat == 'Every day') return ['Daily'];
    if (_repeat == 'Weekdays') return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    if (_repeat == 'Once') return <String>[];
    const keys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = <String>[];
    for (int i = 0; i < _selectedDays.length && i < keys.length; i++) {
      if (_selectedDays[i]) days.add(keys[i]);
    }
    return days;
  }

  void _saveChanges() {
    final normalizedChallenge = switch (_challenge) {
      'Math' => 'Math Puzzle',
      'Memory' => 'Memory Tiles',
      'Walk' => 'Walking Counter',
      'QR Code' => 'QR Scanner',
      _ => _challenge,
    };
    Navigator.of(context).pop({
      'id': _alarmId,
      'time':
          '${_alarmTime.hourOfPeriod == 0 ? 12 : _alarmTime.hourOfPeriod}:${_alarmTime.minute.toString().padLeft(2, '0')}',
      'period': _alarmTime.period == DayPeriod.am ? 'AM' : 'PM',
      'name': _label.trim().isEmpty ? 'Alarm' : _label.trim(),
      'enabled': _isEnabled,
      'repeatDays': _repeatDaysFromSelection(),
      'sound': _soundId,
      'soundName': _sound,
      'challenge': normalizedChallenge,
      'snoozeDuration': _snoozeDuration,
      'snoozeCount': _snoozeCount,
      'vibration': _vibration,
      'vibrationProfileId': _vibration ? _vibrationProfileId : 'off',
      'escalationPolicy': _escalationPolicy,
      'nagPolicy': _nagPolicy,
      'primaryAction': _primaryAction,
      'challengePolicy': _challengePolicy ?? _deriveChallengePolicy(),
      'anchorUtcMillis': _anchorUtcMillis,
    });
  }

  String? _deriveChallengePolicy() {
    switch (_challenge) {
      case 'Math':
      case 'Math Puzzle':
        return 'math';
      case 'Memory':
      case 'Memory Tiles':
        return 'memory';
      case 'QR Code':
      case 'QR Scanner':
        return 'qr';
      default:
        return null;
    }
  }

  void _hydrateNagPolicy() {
    final raw = _nagPolicy;
    if (raw == null || raw.isEmpty) {
      _nagEnabled = false;
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _nagEnabled = false;
        return;
      }
      _nagEnabled = decoded['enabled'] == true;
      _nagRetryWindowMinutes =
          (decoded['retryWindowMinutes'] as int?) ?? _nagRetryWindowMinutes;
      _nagMaxRetries = (decoded['maxRetries'] as int?) ?? _nagMaxRetries;
      _nagRetryIntervalMinutes =
          (decoded['retryIntervalMinutes'] as int?) ?? _nagRetryIntervalMinutes;
    } catch (_) {
      _nagEnabled = false;
    }
  }

  String _nagPolicySummary() {
    if (!_nagEnabled) return 'Off';
    return 'Every $_nagRetryIntervalMinutes min • $_nagMaxRetries retries';
  }

  String _primaryActionSummary() {
    if (_primaryAction == null || _primaryAction!.isEmpty) return 'None';
    try {
      final decoded = jsonDecode(_primaryAction!);
      if (decoded is! Map<String, dynamic>) return 'Configured';
      final type = (decoded['type'] as String? ?? '').toLowerCase();
      final value = (decoded['value'] as String? ?? '').trim();
      if (type == 'maps') return value.isEmpty ? 'Open maps' : 'Maps: $value';
      if (type == 'url' || type == 'deep_link') {
        return value.isEmpty ? 'Open URL' : value;
      }
      return 'Configured';
    } catch (_) {
      return 'Configured';
    }
  }

  Future<void> _showPrimaryActionSheet() async {
    HapticFeedback.lightImpact();
    String actionType = 'none';
    final controller = TextEditingController();

    try {
      if (_primaryAction != null && _primaryAction!.isNotEmpty) {
        final decoded = jsonDecode(_primaryAction!);
        if (decoded is Map<String, dynamic>) {
          actionType = ((decoded['type'] as String?) ?? 'none').toLowerCase();
          controller.text = (decoded['value'] as String?) ?? '';
        }
      }
    } catch (_) {
      actionType = 'none';
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: const BoxDecoration(
                  color: Color(0xFF151515),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Action',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChoiceChipButton(
                            label: 'None',
                            selected: actionType == 'none',
                            onTap: () =>
                                setSheetState(() => actionType = 'none'),
                          ),
                          _ChoiceChipButton(
                            label: 'Open URL',
                            selected:
                                actionType == 'url' ||
                                actionType == 'deep_link',
                            onTap: () =>
                                setSheetState(() => actionType = 'url'),
                          ),
                          _ChoiceChipButton(
                            label: 'Open Maps',
                            selected: actionType == 'maps',
                            onTap: () =>
                                setSheetState(() => actionType = 'maps'),
                          ),
                        ],
                      ),
                      if (actionType != 'none') ...[
                        SizedBox(height: 1.5.h),
                        TextField(
                          controller: controller,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: actionType == 'maps'
                                ? 'Destination query'
                                : 'URL or deep link',
                            hintStyle: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 11.sp,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0A0A0A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 2.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx, {
                              'type': actionType,
                              'value': controller.text.trim(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    final type = (result['type'] as String? ?? 'none').toLowerCase();
    final value = (result['value'] as String? ?? '').trim();
    setState(() {
      if (type == 'none' || value.isEmpty) {
        _primaryAction = null;
      } else {
        _primaryAction = jsonEncode({'type': type, 'value': value});
      }
    });
  }

  Future<void> _showNagPolicySheet() async {
    HapticFeedback.lightImpact();
    bool nagEnabled = _nagEnabled;
    int interval = _nagRetryIntervalMinutes;
    int maxRetries = _nagMaxRetries;
    int retryWindow = _nagRetryWindowMinutes;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                color: Color(0xFF151515),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nag Mode',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SwitchListTile(
                      value: nagEnabled,
                      onChanged: (value) =>
                          setSheetState(() => nagEnabled = value),
                      title: Text(
                        'Enable nag retries',
                        style: TextStyle(fontSize: 12.sp, color: Colors.white),
                      ),
                    ),
                    if (nagEnabled) ...[
                      _ValueSelectorRow(
                        title: 'Retry interval',
                        values: const [10, 15, 30],
                        selected: interval,
                        suffix: ' min',
                        onChanged: (value) =>
                            setSheetState(() => interval = value),
                      ),
                      _ValueSelectorRow(
                        title: 'Max retries',
                        values: const [1, 2, 3, 4],
                        selected: maxRetries,
                        onChanged: (value) =>
                            setSheetState(() => maxRetries = value),
                      ),
                      _ValueSelectorRow(
                        title: 'Retry window',
                        values: const [30, 60, 120],
                        selected: retryWindow,
                        suffix: ' min',
                        onChanged: (value) =>
                            setSheetState(() => retryWindow = value),
                      ),
                    ],
                    SizedBox(height: 1.8.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx, {
                            'enabled': nagEnabled,
                            'interval': interval,
                            'maxRetries': maxRetries,
                            'retryWindow': retryWindow,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _nagEnabled = result['enabled'] == true;
      _nagRetryIntervalMinutes =
          (result['interval'] as int?) ?? _nagRetryIntervalMinutes;
      _nagMaxRetries = (result['maxRetries'] as int?) ?? _nagMaxRetries;
      _nagRetryWindowMinutes =
          (result['retryWindow'] as int?) ?? _nagRetryWindowMinutes;
      _nagPolicy = _nagEnabled
          ? jsonEncode({
              'enabled': true,
              'retryWindowMinutes': _nagRetryWindowMinutes,
              'maxRetries': _nagMaxRetries,
              'retryIntervalMinutes': _nagRetryIntervalMinutes,
            })
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFF2D2D2D)),
                      ),
                      child: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: const Color(0xFFB8B8B8),
                        size: 5.w,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Alarm Details',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveChanges,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF7A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Time + toggle card
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFF2D2D2D)),
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _showTimeSheet,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTime(_alarmTime),
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    _label,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: const Color(0xFFB8B8B8),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 0.3.h),
                                  Text(
                                    _timeUntilNextRingLabel(),
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFFA24A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 0.2.h),
                                  Text(
                                    _nextRingAbsoluteLabel(),
                                    style: TextStyle(
                                      fontSize: 9.5.sp,
                                      color: const Color(0xFF8A8A8A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit_rounded,
                              color: const Color(0xFFB8B8B8),
                              size: 18,
                            ),
                            SizedBox(width: 2.w),
                            Switch(
                              value: _isEnabled,
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                setState(() => _isEnabled = val);
                              },
                              activeThumbColor: const Color(0xFFFF7A1A),
                              activeTrackColor: const Color(
                                0xFFFF7A1A,
                              ).withValues(alpha: 0.3),
                              inactiveThumbColor: const Color(0xFF666666),
                              inactiveTrackColor: const Color(0xFF2D2D2D),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    // Settings rows
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFF2D2D2D)),
                      ),
                      child: Column(
                        children: [
                          DetailRowWidget(
                            label: 'Time',
                            value: _formatTime(_alarmTime),
                            iconName: 'schedule',
                            onTap: _showTimeSheet,
                            valueColor: const Color(0xFFFFA24A),
                          ),
                          DetailRowWidget(
                            label: 'Repeat',
                            value: _repeatDisplay,
                            iconName: 'repeat',
                            onTap: _showRepeatSheet,
                          ),
                          DetailRowWidget(
                            label: 'Label',
                            value: _label,
                            iconName: 'label',
                            onTap: _showLabelSheet,
                          ),
                          DetailRowWidget(
                            label: 'Sound',
                            value: _sound,
                            iconName: 'music_note',
                            onTap: _showSoundSheet,
                          ),
                          DetailRowWidget(
                            label: 'Snooze',
                            value: '$_snoozeDuration min • $_snoozeCount times',
                            iconName: 'snooze',
                            onTap: _showSnoozeSheet,
                          ),
                          DetailRowWidget(
                            label: 'Snooze History',
                            value: _snoozeHistorySummary,
                            iconName: 'history',
                            onTap: _showSnoozeHistorySheet,
                            valueColor: _snoozeTotalCount > 0
                                ? const Color(0xFFFFA24A)
                                : null,
                          ),
                          DetailRowWidget(
                            label: 'Nag Mode',
                            value: _nagPolicySummary(),
                            iconName: 'notifications_active',
                            onTap: _showNagPolicySheet,
                            valueColor: _nagEnabled
                                ? const Color(0xFFFF7A1A)
                                : null,
                          ),
                          DetailRowWidget(
                            label: 'Primary Action',
                            value: _primaryActionSummary(),
                            iconName: 'open_in_new',
                            onTap: _showPrimaryActionSheet,
                            valueColor: _primaryAction == null
                                ? null
                                : const Color(0xFFFF7A1A),
                          ),
                          DetailRowWidget(
                            label: 'Challenge',
                            value: _challenge,
                            iconName: 'psychology',
                            onTap: _showChallengeSheet,
                            valueColor: _challenge == 'Off'
                                ? null
                                : const Color(0xFFFF7A1A),
                          ),
                          DetailRowWidget(
                            label: 'Event Date',
                            value: _anchorDisplay,
                            iconName: 'event',
                            onTap: _showAnchorDateSheet,
                            valueColor: _anchorUtcMillis == null
                                ? null
                                : const Color(0xFFFF7A1A),
                          ),
                          DetailRowWidget(
                            label: 'Vibration',
                            value: _vibration ? 'On' : 'Off',
                            iconName: 'vibration',
                            onTap: _showVibrationSheet,
                          ),
                          if (_anchorUtcMillis != null)
                            Padding(
                              padding: EdgeInsets.only(
                                left: 4.w,
                                right: 4.w,
                                bottom: 1.2.h,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _clearAnchorDate,
                                  child: Text(
                                    'Remove Event Date',
                                    style: TextStyle(
                                      color: const Color(0xFFB8B8B8),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    // Delete button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: GestureDetector(
                        onTap: _confirmDelete,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A0000),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: const Color(
                                0xFFFF453A,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'delete_outline',
                                color: const Color(0xFFFF453A),
                                size: 5.w,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Delete Alarm',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF453A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _parseAnchorUtcMillis(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFF7A1A),
      backgroundColor: const Color(0xFF0A0A0A),
      labelStyle: TextStyle(
        fontSize: 11.sp,
        color: selected ? Colors.white : const Color(0xFFB8B8B8),
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFFF7A1A) : const Color(0xFF2D2D2D),
      ),
    );
  }
}

class _ValueSelectorRow extends StatelessWidget {
  const _ValueSelectorRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.suffix = '',
  });

  final String title;
  final List<int> values;
  final int selected;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFFB8B8B8)),
          ),
          SizedBox(height: 0.8.h),
          Wrap(
            spacing: 8,
            children: values.map((value) {
              final active = value == selected;
              return ChoiceChip(
                label: Text('$value$suffix'),
                selected: active,
                onSelected: (_) => onChanged(value),
                selectedColor: const Color(0xFFFF7A1A),
                backgroundColor: const Color(0xFF0A0A0A),
                labelStyle: TextStyle(
                  fontSize: 11.sp,
                  color: active ? Colors.white : const Color(0xFFB8B8B8),
                ),
                side: BorderSide(
                  color: active
                      ? const Color(0xFFFF7A1A)
                      : const Color(0xFF2D2D2D),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FormatToggleButton extends StatelessWidget {
  const _FormatToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF7A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFFF7A1A) : const Color(0xFF2D2D2D),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: selected ? Colors.white : const Color(0xFFB8B8B8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
