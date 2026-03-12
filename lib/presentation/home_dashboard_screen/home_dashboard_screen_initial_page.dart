import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../alarm/platform/flutter_alarm_scheduler_adapter.dart';
import '../../alarm/config/alarm_engine_mode.dart';
import '../../alarm/shared/alarm_record.dart';
import '../../alarm/shared/alarm_shared_logic_service.dart';
import '../../core/app_export.dart';
import '../../features/alarms/data/alarm_repository_platform_impl.dart';
import '../../services/haptic_service.dart';
import '../../widgets/app_error_widget.dart';
import './widgets/alarm_card_widget.dart';
import './widgets/empty_alarm_widget.dart';
import './widgets/next_alarm_widget.dart';
import './widgets/permission_banner_widget.dart';
import './widgets/skeleton_widgets.dart';

class HomeDashboardScreenInitialPage extends StatefulWidget {
  const HomeDashboardScreenInitialPage({super.key});

  @override
  State<HomeDashboardScreenInitialPage> createState() =>
      _HomeDashboardScreenInitialPageState();
}

class _HomeDashboardScreenInitialPageState
    extends State<HomeDashboardScreenInitialPage> {
  _HomeDashboardScreenInitialPageState()
    : _alarmLogic = AlarmSharedLogicService(
        repository: AlarmRepositoryPlatformImpl(),
        scheduler: const FlutterAlarmSchedulerAdapter(),
        engineMode: kAlarmEngineMode,
      );

  final AlarmSharedLogicService _alarmLogic;

  bool _showPermissionBanner = false;
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _handledRouteArgs = false;

  // Per-alarm scheduling error flags: alarmId -> bool
  final Map<int, bool> _scheduleErrors = {};

  static final List<AlarmRecord> _defaultAlarms = [
    const AlarmRecord(
      id: 1,
      hour24: 6,
      minute: 30,
      name: 'Morning Workout',
      enabled: true,
      repeatDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      sound: 'Sunrise',
      challenge: 'Math Puzzle',
      snoozeCount: 2,
      snoozeDuration: 5,
      vibration: true,
    ),
    const AlarmRecord(
      id: 2,
      hour24: 7,
      minute: 45,
      name: 'Work Commute',
      enabled: true,
      repeatDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      sound: 'Beep Classic',
      challenge: 'Shake Phone',
      snoozeCount: 1,
      snoozeDuration: 5,
      vibration: true,
    ),
    const AlarmRecord(
      id: 3,
      hour24: 9,
      minute: 0,
      name: 'Weekend Brunch',
      enabled: false,
      repeatDays: ['Sat', 'Sun'],
      sound: 'Gentle Bell',
      challenge: 'Memory Tiles',
      snoozeCount: 3,
      snoozeDuration: 5,
      vibration: true,
    ),
    const AlarmRecord(
      id: 4,
      hour24: 23,
      minute: 30,
      name: 'Night Reminder',
      enabled: true,
      repeatDays: ['Daily'],
      sound: 'Digital Buzz',
      challenge: 'Walking Counter',
      snoozeCount: 0,
      snoozeDuration: 5,
      vibration: true,
    ),
  ];

  final List<AlarmRecord> _alarms = <AlarmRecord>[];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kNativeRingPipelineEnabled) return;
    if (_handledRouteArgs) return;
    _handledRouteArgs = true;

    // Handle snooze result returned from AlarmRingingScreen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['snoozed'] == true) {
      final int alarmId = args['alarmId'] as int? ?? -1;
      final int snoozeCount = args['snoozeCount'] as int? ?? 1;
      final int snoozeDuration = args['snoozeDuration'] as int? ?? 5;
      if (alarmId != -1) {
        _handleSnoozeReturn(alarmId, snoozeCount, snoozeDuration);
      }
    }
  }

  /// Called when returning from ringing screen after snooze.
  void _handleSnoozeReturn(int alarmId, int snoozeCount, int snoozeDuration) {
    final idx = _alarms.indexWhere((a) => a.id == alarmId);
    if (idx != -1) {
      setState(() {
        _alarms[idx] = _alarms[idx].copyWith(snoozeCount: snoozeCount);
      });
      _persistAlarms();
    }

    HapticService.snoozeSuccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppErrorWidget.showSuccess(
          context,
          'Alarm snoozed · rings in $snoozeDuration min',
        );
      }
    });
  }

  Future<void> _loadAlarms() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final loaded = await _alarmLogic.loadAlarms(fallback: _defaultAlarms);
      final bool hasPermission = await _alarmLogic.hasExactAlarmPermission();

      if (!mounted) return;
      setState(() {
        _alarms
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
        _showPermissionBanner = !hasPermission;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
      });
    }
  }

  Future<void> _persistAlarms() async {
    await _alarmLogic.persist(_alarms);
  }

  Map<String, dynamic>? get _nextAlarm {
    final enabled = _alarms.where((a) => a.enabled);
    if (enabled.isEmpty) return null;

    final now = DateTime.now();
    AlarmRecord? nearestAlarm;
    DateTime? nearestAt;

    for (final alarm in enabled) {
      final candidate = _nextOccurrenceForAlarm(alarm, now);
      if (candidate == null) continue;
      if (nearestAt == null || candidate.isBefore(nearestAt)) {
        nearestAt = candidate;
        nearestAlarm = alarm;
      }
    }

    return nearestAlarm?.toMap();
  }

  DateTime? _nextOccurrenceForAlarm(AlarmRecord alarm, DateTime now) {
    DateTime candidateFor(DateTime date) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        alarm.hour24,
        alarm.minute,
      );
    }

    final anchorUtcMillis = alarm.anchorUtcMillis;
    if (anchorUtcMillis != null) {
      final anchor = DateTime.fromMillisecondsSinceEpoch(
        anchorUtcMillis,
        isUtc: true,
      ).toLocal();
      final anchored = candidateFor(anchor);
      if (!anchored.isBefore(now)) return anchored;
      return null;
    }

    final repeatDays = alarm.repeatDays.map((e) => e.trim()).toSet();
    if (repeatDays.contains('Daily')) {
      final today = candidateFor(now);
      if (!today.isBefore(now)) return today;
      return today.add(const Duration(days: 1));
    }

    const weekdayOrder = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final allowedWeekdays = repeatDays
        .map((name) => weekdayOrder.indexOf(name))
        .where((index) => index >= 0)
        .toSet();

    if (allowedWeekdays.isNotEmpty) {
      for (int dayOffset = 0; dayOffset <= 14; dayOffset++) {
        final day = now.add(Duration(days: dayOffset));
        final weekdayIndex = day.weekday - 1; // Monday=0..Sunday=6
        if (!allowedWeekdays.contains(weekdayIndex)) continue;
        final candidate = candidateFor(day);
        if (!candidate.isBefore(now)) return candidate;
      }
      return null;
    }

    // One-time alarm without anchor date: assume next immediate occurrence.
    final today = candidateFor(now);
    if (!today.isBefore(now)) return today;
    return today.add(const Duration(days: 1));
  }

  int get _nextAlarmId {
    final maxId = _alarms.fold<int>(
      0,
      (currentMax, alarm) => alarm.id > currentMax ? alarm.id : currentMax,
    );
    return maxId + 1;
  }

  Future<void> _toggleAlarm(int id, bool value) async {
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;

    final previous = _alarms[idx];
    final updated = previous.copyWith(enabled: value);

    setState(() {
      _alarms[idx] = updated;
    });

    bool ok = false;
    try {
      ok = await _alarmLogic.setAlarmEnabled(previous, value);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      setState(() {
        _alarms[idx] = previous;
        _scheduleErrors[id] = true;
      });
      AppErrorWidget.showError(context, 'Could not schedule notification');
    } else {
      setState(() => _scheduleErrors.remove(id));
    }

    await _persistAlarms();
  }

  Future<void> _deleteAlarm(int id) async {
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;

    final AlarmRecord removed = _alarms[idx];

    setState(() {
      _alarms.removeAt(idx);
      _scheduleErrors.remove(id);
    });

    await _alarmLogic.cancelAlarm(removed);

    if (mounted) {
      AppErrorWidget.showError(
        context,
        'Alarm deleted',
        actionLabel: 'Undo',
        onAction: () async {
          setState(() {
            _alarms.insert(idx, removed);
          });

          if (removed.enabled) {
            await _alarmLogic.scheduleAlarm(removed);
          }
          await _persistAlarms();
        },
      );
    }

    await _persistAlarms();
  }

  Future<void> _onRefresh() async {
    await _loadAlarms();
  }

  Future<void> _openAlarmCreation() async {
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.alarmCreation);

    if (!mounted || result is! Map<String, dynamic>) return;

    final created = AlarmRecord.fromCreationResult(
      result,
      nextId: _nextAlarmId,
    );
    if (created == null) return;

    // Insert newly created alarms as disabled first, then perform explicit
    // scheduling toggle so failure can cleanly roll back to disabled state.
    final createdSeed = created.enabled
        ? created.copyWith(enabled: false)
        : created;
    setState(() {
      _alarms.add(createdSeed);
    });
    await _persistAlarms();

    if (created.enabled) {
      await _toggleAlarm(createdSeed.id, true);
    }
  }

  Future<void> _openAlarmDetail(AlarmRecord alarm) async {
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.alarmDetail, arguments: alarm.toMap());

    if (!mounted || result == null) return;

    if (result is Map<String, dynamic> && result['deleted'] == true) {
      final int id = result['id'] as int? ?? alarm.id;
      await _deleteAlarm(id);
      return;
    }

    if (result is! Map<String, dynamic>) return;

    final updated = AlarmRecord.fromMap(result);
    final int id = updated.id;
    final int idx = _alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;

    final previous = _alarms[idx];

    setState(() {
      _alarms[idx] = updated;
      _scheduleErrors.remove(id);
    });
    await _persistAlarms();

    if (previous.enabled) {
      await _alarmLogic.cancelAlarm(previous);
    }
    if (updated.enabled) {
      final ok = await _alarmLogic.setAlarmEnabled(updated, true);
      if (!ok && mounted) {
        bool restored = false;
        if (previous.enabled) {
          try {
            restored = await _alarmLogic.setAlarmEnabled(previous, true);
          } catch (_) {
            restored = false;
          }
        }
        if (!mounted) return;
        setState(() {
          _scheduleErrors[id] = true;
          _alarms[idx] = restored ? previous : updated.copyWith(enabled: false);
        });
        await _persistAlarms();
        if (!mounted) return;
        AppErrorWidget.showError(
          context,
          restored
              ? 'New alarm settings failed, previous schedule restored'
              : 'Could not schedule notification',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledAlarms = _alarms.where((a) => a.enabled).toList();
    final disabledAlarms = _alarms.where((a) => !a.enabled).toList();
    final allSorted = [...enabledAlarms, ...disabledAlarms];

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            children: [
              _buildHeader(theme),
              SizedBox(height: 1.h),
              _showPermissionBanner
                  ? PermissionBannerWidget(
                      onDismiss: () =>
                          setState(() => _showPermissionBanner = false),
                      onFix: () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.reliabilitySettings),
                    )
                  : const SizedBox.shrink(),
              SizedBox(height: 1.h),
              _isLoading
                  ? const NextAlarmCardSkeleton()
                  : NextAlarmWidget(alarm: _nextAlarm),
              SizedBox(height: 2.h),
              Expanded(child: _buildAlarmList(theme, allSorted)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAlarmCreation,
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: AppTheme.primaryText,
        icon: CustomIconWidget(
          iconName: 'add',
          color: AppTheme.primaryText,
          size: 22,
        ),
        label: Text(
          'Add Alarm',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.primaryText,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildAlarmList(ThemeData theme, List<AlarmRecord> allSorted) {
    if (_hasLoadError) {
      return AppErrorWidget(
        message: 'Something went wrong while loading your alarms.',
        onRetry: _loadAlarms,
      );
    }

    if (_isLoading) {
      return Column(
        children: [
          _buildListHeader(theme, loading: true),
          SizedBox(height: 1.5.h),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
              itemBuilder: (_, __) => const AlarmCardSkeleton(),
            ),
          ),
        ],
      );
    }

    if (allSorted.isEmpty) {
      return EmptyAlarmWidget(onAddAlarm: _openAlarmCreation);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader(theme, loading: false),
        SizedBox(height: 1.5.h),
        if (_alarms.every((a) => !a.enabled))
          Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Text(
              'No active alarms',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.inactiveText,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.accentOrange,
            backgroundColor: AppTheme.secondaryBackground,
            onRefresh: _onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: allSorted.length,
              separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
              itemBuilder: (context, index) {
                final alarm = allSorted[index];
                final bool hasScheduleError = _scheduleErrors[alarm.id] == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AlarmCardWidget(
                      alarm: alarm.toMap(),
                      onToggle: (val) => _toggleAlarm(alarm.id, val),
                      onDelete: () => _deleteAlarm(alarm.id),
                      onEdit: () => _openAlarmDetail(alarm),
                      onTap: () => _openAlarmDetail(alarm),
                    ),
                    if (hasScheduleError)
                      Padding(
                        padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
                        child: AppErrorWidget(
                          message:
                              'Alarm scheduling failed — check permissions',
                          compact: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader(ThemeData theme, {required bool loading}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Your Alarms',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!loading && _alarms.isNotEmpty)
          GestureDetector(
            onTap: () async {
              await _alarmLogic.cancelAllAlarms();
              setState(() {
                for (int i = 0; i < _alarms.length; i++) {
                  _alarms[i] = _alarms[i].copyWith(enabled: false);
                }
                _scheduleErrors.clear();
              });
              await _persistAlarms();
            },
            child: Text(
              'Turn Off All',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.inactiveText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Alarms',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
            ),
            Text(
              '${_alarms.where((a) => a.enabled).length} active',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.inactiveText,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.statsDashboard),
              child: Container(
                width: 11.w,
                height: 11.w,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.subtleBorder, width: 1),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'bar_chart',
                    color: AppTheme.inactiveText,
                    size: 20,
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.reliabilitySettings),
              child: Container(
                width: 11.w,
                height: 11.w,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.subtleBorder, width: 1),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'settings',
                    color: AppTheme.inactiveText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
