import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../platform/guardian_platform_api.dart';
import '../../platform/guardian_platform_models.dart';
import '../../alarm/shared/alarm_record.dart';
import '../sound_picker_screen/sound_picker_screen.dart';
import '../../services/haptic_service.dart';
import './widgets/challenge_selector_widget.dart';
import './widgets/day_chips_widget.dart';
import './widgets/snooze_settings_widget.dart';
import './widgets/sound_picker_row_widget.dart';
import './widgets/time_picker_widget.dart';

class AlarmCreationScreen extends StatefulWidget {
  const AlarmCreationScreen({super.key});

  @override
  State<AlarmCreationScreen> createState() => _AlarmCreationScreenState();
}

class _AlarmCreationScreenState extends State<AlarmCreationScreen> {
  final GuardianPlatformApi _platformApi = GuardianPlatformApi.instance;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _selectedAnchorDate;
  final List<DateTime> _exclusionDates = <DateTime>[];
  final List<bool> _selectedDays = List.filled(7, false);
  String _selectedSound = 'Default Alarm';
  String _selectedSoundId = 'default_alarm';
  String _selectedChallenge = 'None';
  String _vibrationProfileId = 'default';
  String? _escalationPolicy;
  String? _primaryAction;
  String? _challengePolicy;
  bool _nagEnabled = false;
  int _nagRetryWindowMinutes = 30;
  int _nagMaxRetries = 2;
  int _nagRetryIntervalMinutes = 10;
  int _snoozeDuration = 5;
  int _snoozeCount = 3;
  final List<int> _reminderOffsetsMinutes = <int>[60];
  bool _reminderBeforeOnly = false;
  List<TemplateModel> _templates = const <TemplateModel>[];
  int? _selectedTemplateId;
  bool _use24HourFormat = false;
  bool _timeFormatInitialized = false;
  bool _isPreviewing = false;

  // Label
  final TextEditingController _labelController = TextEditingController();
  final FocusNode _labelFocusNode = FocusNode();
  String? _labelError;

  // Repeat mode
  String _repeatMode = 'once'; // once, weekdays, everyday, custom
  String? _repeatError;

  // Time bounds error
  String? _timeError;

  final List<String> _challengeOptions = ['None', 'Math', 'Memory', 'QR Code'];

  @override
  void initState() {
    super.initState();
    _labelFocusNode.addListener(() {
      if (!_labelFocusNode.hasFocus) {
        _validateLabel();
      }
    });
    _loadTemplates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_timeFormatInitialized) {
      _use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
      _timeFormatInitialized = true;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _labelFocusNode.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  void _validateLabel() {
    final text = _labelController.text.trim();
    setState(() {
      if (text.isNotEmpty && text.length < 2) {
        _labelError = 'Label must be at least 2 characters';
      } else if (text.length > 40) {
        _labelError = 'Label must be 40 characters or fewer';
      } else {
        _labelError = null;
      }
    });
  }

  void _validateRepeat() {
    setState(() {
      if (_repeatMode == 'custom') {
        final anySelected = _selectedDays.any((d) => d);
        if (!anySelected) {
          _repeatError = 'Select at least one day for custom repeat';
        } else {
          _repeatError = null;
        }
      } else {
        _repeatError = null;
      }
    });
  }

  void _validateTime() {
    if (_selectedAnchorDate != null) {
      setState(() => _timeError = null);
      return;
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final selectedMinutes = _selectedTime.hour * 60 + _selectedTime.minute;

    final hadError = _timeError != null;
    setState(() {
      if (_repeatMode == 'once' && selectedMinutes <= nowMinutes) {
        _timeError = 'Time is in the past — alarm will ring tomorrow';
      } else {
        _timeError = null;
      }
    });
    // Trigger warning haptic only when error first appears
    if (_timeError != null && !hadError) {
      HapticService.formValidationWarning();
    }
  }

  bool _validateAll() {
    _validateLabel();
    _validateRepeat();
    _validateTime();
    return _labelError == null && _repeatError == null;
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  void _onTimeChanged(TimeOfDay time) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTime = time);
    _validateTime();
  }

  void _onDayToggled(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDays[index] = !_selectedDays[index]);
    if (_repeatMode == 'custom') _validateRepeat();
  }

  void _onRepeatModeChanged(String mode) {
    HapticFeedback.selectionClick();
    setState(() {
      _repeatMode = mode;
      if (mode != 'custom') {
        // Clear custom day selections when switching away
        for (int i = 0; i < _selectedDays.length; i++) {
          _selectedDays[i] = false;
        }
      }
    });
    _validateRepeat();
    _validateTime();
  }

  void _onSoundTap() {
    HapticFeedback.lightImpact();
    _showSoundPickerModal();
  }

  void _onChallengeChanged(String challenge) {
    HapticFeedback.selectionClick();
    setState(() => _selectedChallenge = challenge);
  }

  void _onSnoozeDurationChanged(int value) {
    HapticFeedback.selectionClick();
    setState(() => _snoozeDuration = value);
  }

  void _onSnoozeCountChanged(int value) {
    HapticFeedback.selectionClick();
    setState(() => _snoozeCount = value);
  }

  void _saveAlarm() {
    HapticService.buttonMedium();
    if (!_validateAll()) {
      HapticService.formValidationError();
      return;
    }
    final draft = _buildDraftRecord();
    final nagPolicy = _nagEnabled
        ? jsonEncode({
            'enabled': true,
            'retryWindowMinutes': _nagRetryWindowMinutes,
            'maxRetries': _nagMaxRetries,
            'retryIntervalMinutes': _nagRetryIntervalMinutes,
          })
        : null;
    final alarmData = {
      'time': _selectedTime,
      'days': _selectedDays,
      'sound': draft.sound,
      'soundName': _selectedSound,
      'challenge': draft.challenge,
      'snoozeDuration': draft.snoozeDuration,
      'snoozeCount': draft.snoozeCount,
      'vibrationProfileId': draft.vibrationProfileId,
      'escalationPolicy': draft.escalationPolicy,
      'nagPolicy': nagPolicy,
      'primaryAction': draft.primaryAction,
      'challengePolicy': draft.challengePolicy,
      'label': _labelController.text.trim(),
      'repeatMode': _repeatMode,
      'enabled': true,
      'anchorUtcMillis': draft.anchorUtcMillis,
      'recurrenceType': draft.recurrenceType,
      'recurrenceInterval': draft.recurrenceInterval,
      'recurrenceWeekdays': draft.recurrenceWeekdays,
      'recurrenceDayOfMonth': draft.recurrenceDayOfMonth,
      'recurrenceOrdinal': draft.recurrenceOrdinal,
      'recurrenceOrdinalWeekday': draft.recurrenceOrdinalWeekday,
      'recurrenceExclusionDates': draft.recurrenceExclusionDates,
      'reminderOffsetsMinutes': draft.reminderOffsetsMinutes,
      'reminderBeforeOnly': draft.reminderBeforeOnly,
    };
    Navigator.of(context, rootNavigator: true).pop(alarmData);
  }

  Future<void> _pickAnchorDate() async {
    final now = DateTime.now();
    final initial = _selectedAnchorDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAnchorDate = DateTime(picked.year, picked.month, picked.day);
    });
    _validateTime();
  }

  void _clearAnchorDate() {
    if (_selectedAnchorDate == null) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedAnchorDate = null);
    _validateTime();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _platformApi.getTemplates();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        if (_selectedTemplateId != null &&
            !_templates.any((t) => t.templateId == _selectedTemplateId)) {
          _selectedTemplateId = null;
        }
      });
    } catch (_) {
      // Templates are optional enhancement; keep creation flow available.
    }
  }

  Future<void> _saveCurrentAsTemplate() async {
    final controller = TextEditingController(
      text: _labelController.text.trim().isEmpty
          ? 'Custom Template'
          : _labelController.text.trim(),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Template'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Template name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || name == null || name.isEmpty) return;

    final record = _buildDraftRecord();
    final template = TemplateModel(
      templateId: 0,
      name: name,
      title: record.name,
      hour24: record.hour24,
      minute: record.minute,
      repeatDays: record.repeatDays,
      sound: record.sound,
      vibration: record.vibration,
      vibrationProfileId: record.vibrationProfileId,
      escalationPolicy: record.escalationPolicy,
      nagPolicy: record.nagPolicy,
      primaryAction: record.primaryAction,
      challenge: record.challenge,
      challengePolicy: record.challengePolicy,
      snoozeCount: record.snoozeCount,
      snoozeDuration: record.snoozeDuration,
      recurrenceType: record.recurrenceType,
      recurrenceInterval: record.recurrenceInterval,
      recurrenceWeekdays: record.recurrenceWeekdays,
      recurrenceDayOfMonth: record.recurrenceDayOfMonth,
      recurrenceOrdinal: record.recurrenceOrdinal,
      recurrenceOrdinalWeekday: record.recurrenceOrdinalWeekday,
      recurrenceExclusionDates: record.recurrenceExclusionDates,
      reminderOffsetsMinutes: record.reminderOffsetsMinutes,
      reminderBeforeOnly: record.reminderBeforeOnly,
      timezonePolicy: 'FIXED_LOCAL_TIME',
    );
    try {
      await _platformApi.saveTemplate(template);
      if (!mounted) return;
      await _loadTemplates();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Template saved')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Template save failed: $error')));
    }
  }

  Future<void> _applyTemplate(TemplateModel template) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTemplateId = template.templateId;
      _selectedTime = TimeOfDay(hour: template.hour24, minute: template.minute);
      _labelController.text = template.title;
      _selectedSound = template.sound;
      _selectedSoundId = template.sound;
      _selectedChallenge = template.challenge;
      _snoozeCount = template.snoozeCount;
      _snoozeDuration = template.snoozeDuration;
      _vibrationProfileId = template.vibrationProfileId ?? _vibrationProfileId;
      _escalationPolicy = template.escalationPolicy;
      _nagEnabled = template.nagPolicy != null;
      _nagRetryIntervalMinutes = 10;
      _nagMaxRetries = 2;
      _nagRetryWindowMinutes = 30;
      _primaryAction = template.primaryAction;
      _challengePolicy = template.challengePolicy;
      _reminderOffsetsMinutes
        ..clear()
        ..addAll(template.reminderOffsetsMinutes);
      _reminderBeforeOnly = template.reminderBeforeOnly;
      _exclusionDates
        ..clear()
        ..addAll(
          template.recurrenceExclusionDates
              .map((e) => DateTime.tryParse(e))
              .whereType<DateTime>()
              .map((date) => DateTime(date.year, date.month, date.day)),
        );
    });
    _applyRepeatFromTemplate(template);
  }

  void _applyRepeatFromTemplate(TemplateModel template) {
    final recurrenceType = (template.recurrenceType ?? '').toUpperCase();
    final weekdays = template.recurrenceWeekdays.toSet();
    setState(() {
      for (int i = 0; i < _selectedDays.length; i++) {
        _selectedDays[i] = false;
      }

      if (recurrenceType == 'DAILY') {
        _repeatMode = 'everyday';
      } else if (recurrenceType == 'WEEKDAYS') {
        _repeatMode = 'weekdays';
      } else if (recurrenceType == 'CUSTOM_WEEKDAYS' && weekdays.isNotEmpty) {
        _repeatMode = 'custom';
        for (final day in weekdays) {
          if (day >= 1 && day <= 7) _selectedDays[day - 1] = true;
        }
      } else if (template.repeatDays.contains('Daily')) {
        _repeatMode = 'everyday';
      } else if (template.repeatDays.length >= 5) {
        _repeatMode = 'weekdays';
      } else if (template.repeatDays.isNotEmpty) {
        _repeatMode = 'custom';
        const map = <String, int>{
          'Mon': 0,
          'Tue': 1,
          'Wed': 2,
          'Thu': 3,
          'Fri': 4,
          'Sat': 5,
          'Sun': 6,
        };
        for (final value in template.repeatDays) {
          final idx = map[value];
          if (idx != null) _selectedDays[idx] = true;
        }
      } else {
        _repeatMode = 'once';
      }
    });
  }

  Future<void> _addExclusionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      if (!_exclusionDates.any(
        (d) =>
            d.year == normalized.year &&
            d.month == normalized.month &&
            d.day == normalized.day,
      )) {
        _exclusionDates.add(normalized);
      }
    });
  }

  void _removeExclusionDate(DateTime date) {
    setState(() {
      _exclusionDates.removeWhere(
        (d) =>
            d.year == date.year && d.month == date.month && d.day == date.day,
      );
    });
  }

  Future<void> _previewPlannedTriggers() async {
    setState(() => _isPreviewing = true);
    try {
      final triggers = await _platformApi.previewPlannedTriggers(
        _buildDraftRecord(),
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
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
                    'Planned Triggers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryText,
                    ),
                  ),
                  SizedBox(height: 1.2.h),
                  if (triggers.isEmpty)
                    Text(
                      'No future triggers generated.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.inactiveText,
                      ),
                    )
                  else
                    ...triggers
                        .take(8)
                        .map(
                          (trigger) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${trigger.kind} · ${trigger.scheduledLocalIso}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.primaryText),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preview failed: $error')));
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  AlarmRecord _buildDraftRecord() {
    return AlarmRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      hour24: _selectedTime.hour,
      minute: _selectedTime.minute,
      name: _labelController.text.trim().isEmpty
          ? 'Alarm'
          : _labelController.text.trim(),
      enabled: true,
      repeatDays: AlarmRecord.selectedDaysToNames(
        _selectedDays,
        repeatMode: _repeatMode,
      ),
      sound: _selectedSoundId,
      challenge: _selectedChallenge,
      snoozeCount: _snoozeCount,
      snoozeDuration: _snoozeDuration,
      vibration: true,
      anchorUtcMillis: _buildAnchorUtcMillis(),
      vibrationProfileId: _vibrationProfileId,
      escalationPolicy: _escalationPolicy,
      nagPolicy: _nagEnabled
          ? jsonEncode({
              'enabled': true,
              'retryWindowMinutes': _nagRetryWindowMinutes,
              'maxRetries': _nagMaxRetries,
              'retryIntervalMinutes': _nagRetryIntervalMinutes,
            })
          : null,
      primaryAction: _primaryAction,
      challengePolicy: _challengePolicy ?? _deriveChallengePolicy(),
      recurrenceType: _resolveRecurrenceType(),
      recurrenceInterval: _resolveRecurrenceType() == null ? null : 1,
      recurrenceWeekdays: _selectedWeekdaysForRecurrence(),
      recurrenceExclusionDates: _exclusionDates
          .map(
            (date) =>
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          )
          .toList(),
      reminderOffsetsMinutes: _reminderOffsetsMinutes.toList()
        ..sort((a, b) => b.compareTo(a)),
      reminderBeforeOnly: _reminderBeforeOnly,
    );
  }

  String? _resolveRecurrenceType() {
    switch (_repeatMode) {
      case 'everyday':
        return 'DAILY';
      case 'weekdays':
        return 'WEEKDAYS';
      case 'custom':
        return _selectedDays.any((d) => d) ? 'CUSTOM_WEEKDAYS' : null;
      default:
        return null;
    }
  }

  List<int> _selectedWeekdaysForRecurrence() {
    final values = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) values.add(i + 1);
    }
    return values;
  }

  int? _buildAnchorUtcMillis() {
    final anchorDate = _selectedAnchorDate;
    if (anchorDate == null) return null;
    final local = DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    return local.toUtc().millisecondsSinceEpoch;
  }

  String _formatAnchorDate(DateTime date) {
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

  void _cancel() {
    HapticService.buttonLight();
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showSoundPickerModal() {
    Navigator.of(context, rootNavigator: true)
        .push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) =>
                SoundPickerScreen(selectedSoundId: _selectedSoundId),
          ),
        )
        .then((result) {
          if (!mounted || result == null) return;
          HapticFeedback.selectionClick();
          setState(() {
            _selectedSoundId =
                (result['soundId'] as String?) ?? _selectedSoundId;
            _selectedSound = (result['soundName'] as String?) ?? _selectedSound;
            _vibrationProfileId =
                (result['vibrationProfileId'] as String?) ??
                _vibrationProfileId;
            _escalationPolicy = result['escalationPolicy'] as String?;
          });
        });
  }

  String? _deriveChallengePolicy() {
    switch (_selectedChallenge) {
      case 'Math':
        return 'math';
      case 'Memory':
        return 'memory';
      case 'QR Code':
        return 'qr';
      default:
        return null;
    }
  }

  String _primaryActionSummary() {
    if (_primaryAction == null || _primaryAction!.trim().isEmpty) {
      return 'None';
    }
    try {
      final decoded = jsonDecode(_primaryAction!);
      if (decoded is! Map<String, dynamic>) return 'Configured';
      final type = (decoded['type'] as String? ?? '').toLowerCase();
      final value = (decoded['value'] as String? ?? '').trim();
      if (type == 'maps') {
        return value.isEmpty ? 'Open maps' : 'Maps: $value';
      }
      if (type == 'url' || type == 'deep_link') {
        return value.isEmpty ? 'Open URL' : value;
      }
      return 'Configured';
    } catch (_) {
      return 'Configured';
    }
  }

  String _nagPolicySummary() {
    if (!_nagEnabled) return 'Off';
    return 'Every ${_nagRetryIntervalMinutes}m • max $_nagMaxRetries retries';
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primary Action',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.primaryText),
                          ),
                          SizedBox(height: 1.5.h),
                          Wrap(
                            spacing: 8,
                            children: [
                              _ActionChip(
                                label: 'None',
                                selected: actionType == 'none',
                                onTap: () =>
                                    setSheetState(() => actionType = 'none'),
                              ),
                              _ActionChip(
                                label: 'Open URL',
                                selected:
                                    actionType == 'url' ||
                                    actionType == 'deep_link',
                                onTap: () =>
                                    setSheetState(() => actionType = 'url'),
                              ),
                              _ActionChip(
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.primaryText),
                              decoration: InputDecoration(
                                hintText: actionType == 'maps'
                                    ? 'Destination (e.g. Office Nairobi)'
                                    : 'URL or deep link',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.inactiveText),
                                filled: true,
                                fillColor: AppTheme.primaryBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.subtleBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.subtleBorder,
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
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    final selectedType = (result['type'] as String? ?? 'none').toLowerCase();
    final value = (result['value'] as String? ?? '').trim();
    setState(() {
      if (selectedType == 'none' || value.isEmpty) {
        _primaryAction = null;
      } else {
        _primaryAction = jsonEncode({'type': selectedType, 'value': value});
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nag Mode',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.primaryText),
                          ),
                          SwitchListTile(
                            value: nagEnabled,
                            onChanged: (value) =>
                                setSheetState(() => nagEnabled = value),
                            title: Text(
                              'Enable nag retries',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.primaryText),
                            ),
                          ),
                          if (nagEnabled) ...[
                            SizedBox(height: 1.h),
                            _NumberChoiceRow(
                              title: 'Retry interval',
                              values: const [10, 15, 30],
                              selected: interval,
                              suffix: 'min',
                              onChanged: (value) =>
                                  setSheetState(() => interval = value),
                            ),
                            SizedBox(height: 1.h),
                            _NumberChoiceRow(
                              title: 'Max retries',
                              values: const [1, 2, 3, 4],
                              selected: maxRetries,
                              onChanged: (value) =>
                                  setSheetState(() => maxRetries = value),
                            ),
                            SizedBox(height: 1.h),
                            _NumberChoiceRow(
                              title: 'Retry window',
                              values: const [30, 60, 120],
                              selected: retryWindow,
                              suffix: 'min',
                              onChanged: (value) =>
                                  setSheetState(() => retryWindow = value),
                            ),
                          ],
                          SizedBox(height: 2.h),
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
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    });
  }

  // ── UI Helpers ───────────────────────────────────────────────────────────────

  Widget _buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF453A),
            size: 14,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFF453A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFFFB020),
            size: 14,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFFB020),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelField(ThemeData theme) {
    final hasError = _labelError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LABEL',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.inactiveText,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 1.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFFF453A)
                  : _labelFocusNode.hasFocus
                  ? AppTheme.accentOrange
                  : AppTheme.subtleBorder,
              width: hasError || _labelFocusNode.hasFocus ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _labelController,
            focusNode: _labelFocusNode,
            maxLength: 40,
            cursorColor: AppTheme.accentOrange,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.secondaryBackground,
              hintText: 'e.g. Morning workout',
              hintStyle: const TextStyle(
                color: AppTheme.inactiveText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.label_outline_rounded,
                color: hasError
                    ? const Color(0xFFFF453A)
                    : AppTheme.inactiveText,
                size: 20,
              ),
              prefixIconColor: hasError
                  ? const Color(0xFFFF453A)
                  : AppTheme.inactiveText,
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.8.h,
              ),
            ),
            onChanged: (v) {
              if (_labelError != null) _validateLabel();
            },
          ),
        ),
        if (hasError) _buildErrorMessage(_labelError!),
      ],
    );
  }

  Widget _buildRepeatSection(ThemeData theme) {
    final presets = [
      ('once', 'Once'),
      ('weekdays', 'Weekdays'),
      ('everyday', 'Every day'),
      ('custom', 'Custom'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPEAT',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.inactiveText,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 1.h),
        // Preset chips
        Row(
          children: presets.map((p) {
            final isActive = _repeatMode == p.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onRepeatModeChanged(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.accentOrange
                        : AppTheme.secondaryBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.accentOrange
                          : AppTheme.subtleBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      p.$2,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppTheme.inactiveText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Custom day chips
        if (_repeatMode == 'custom') ...[
          SizedBox(height: 1.2.h),
          DayChipsWidget(
            selectedDays: _selectedDays,
            onDayToggled: _onDayToggled,
          ),
          if (_repeatError != null) _buildErrorMessage(_repeatError!),
        ],
      ],
    );
  }

  Widget _buildTimeFormatToggle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIME FORMAT',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.inactiveText,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.subtleBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _FormatToggleButton(
                  label: '12-hour',
                  selected: !_use24HourFormat,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _use24HourFormat = false);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _FormatToggleButton(
                  label: '24-hour',
                  selected: _use24HourFormat,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _use24HourFormat = true);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  _headerActionButton(
                    label: 'Cancel',
                    color: AppTheme.inactiveText,
                    onPressed: _cancel,
                  ),
                  Expanded(
                    child: Text(
                      'New Alarm',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _headerActionButton(
                      label: 'Save',
                      color: AppTheme.accentOrange,
                      onPressed: _saveAlarm,
                      emphasize: true,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 1.h),
                      _buildTimeFormatToggle(theme),
                      SizedBox(height: 1.2.h),
                      // Time Picker
                      TimePickerWidget(
                        key: ValueKey<bool>(_use24HourFormat),
                        selectedTime: _selectedTime,
                        use24HourFormat: _use24HourFormat,
                        onTimeChanged: _onTimeChanged,
                      ),
                      // Time warning (past time)
                      if (_timeError != null) ...[
                        SizedBox(height: 0.5.h),
                        _buildWarningMessage(_timeError!),
                      ],
                      SizedBox(height: 2.h),
                      Text(
                        'EVENT DATE (OPTIONAL)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.subtleBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              color: AppTheme.inactiveText,
                              size: 20,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                _selectedAnchorDate == null
                                    ? 'No specific date'
                                    : _formatAnchorDate(_selectedAnchorDate!),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: _selectedAnchorDate == null
                                      ? AppTheme.inactiveText
                                      : AppTheme.primaryText,
                                ),
                              ),
                            ),
                            if (_selectedAnchorDate != null)
                              IconButton(
                                onPressed: _clearAnchorDate,
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: AppTheme.inactiveText,
                                  size: 18,
                                ),
                              ),
                            TextButton(
                              onPressed: _pickAnchorDate,
                              child: Text(
                                _selectedAnchorDate == null ? 'Set' : 'Change',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.5.h),
                      Text(
                        'TEMPLATES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.subtleBorder),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 390;
                            final dropdown = DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value:
                                    _templates.any(
                                      (t) =>
                                          t.templateId == _selectedTemplateId,
                                    )
                                    ? _selectedTemplateId
                                    : null,
                                isExpanded: true,
                                dropdownColor: AppTheme.secondaryBackground,
                                iconEnabledColor: AppTheme.inactiveText,
                                iconDisabledColor: AppTheme.subtleBorder,
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.primaryText,
                                    ) ??
                                    const TextStyle(
                                      color: AppTheme.primaryText,
                                    ),
                                hint: Text(
                                  _templates.isEmpty
                                      ? 'No templates available'
                                      : 'Apply template',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.inactiveText,
                                  ),
                                ),
                                selectedItemBuilder: (context) {
                                  return _templates
                                      .map(
                                        (template) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            template.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: AppTheme.primaryText,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                items: _templates
                                    .map(
                                      (template) => DropdownMenuItem<int>(
                                        value: template.templateId,
                                        child: Text(
                                          template.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.primaryText,
                                              ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _templates.isEmpty
                                    ? null
                                    : (templateId) {
                                        if (templateId == null) return;
                                        final template = _templates.firstWhere(
                                          (item) =>
                                              item.templateId == templateId,
                                        );
                                        _applyTemplate(template);
                                      },
                              ),
                            );

                            final saveButton = TextButton(
                              onPressed: _saveCurrentAsTemplate,
                              child: Text(
                                'Save current',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accentOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  dropdown,
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: saveButton,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: dropdown),
                                saveButton,
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 2.5.h),
                      Text(
                        'REMINDER BUNDLE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OffsetChip(
                            label: '1 week',
                            selected: _reminderOffsetsMinutes.contains(10080),
                            onTap: () {
                              setState(() {
                                if (_reminderOffsetsMinutes.contains(10080)) {
                                  _reminderOffsetsMinutes.remove(10080);
                                } else {
                                  _reminderOffsetsMinutes.add(10080);
                                }
                              });
                            },
                          ),
                          _OffsetChip(
                            label: '1 day',
                            selected: _reminderOffsetsMinutes.contains(1440),
                            onTap: () {
                              setState(() {
                                if (_reminderOffsetsMinutes.contains(1440)) {
                                  _reminderOffsetsMinutes.remove(1440);
                                } else {
                                  _reminderOffsetsMinutes.add(1440);
                                }
                              });
                            },
                          ),
                          _OffsetChip(
                            label: '1 hour',
                            selected: _reminderOffsetsMinutes.contains(60),
                            onTap: () {
                              setState(() {
                                if (_reminderOffsetsMinutes.contains(60)) {
                                  _reminderOffsetsMinutes.remove(60);
                                } else {
                                  _reminderOffsetsMinutes.add(60);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _reminderBeforeOnly,
                        onChanged: (value) =>
                            setState(() => _reminderBeforeOnly = value),
                        title: Text(
                          'Before-only mode',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryText,
                          ),
                        ),
                        subtitle: Text(
                          'Skip event-time ring, keep pre-reminders only.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.inactiveText,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'RECURRENCE EXCLUSIONS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _exclusionDates.isEmpty
                                  ? 'No exclusion dates'
                                  : '${_exclusionDates.length} date(s) excluded',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _exclusionDates.isEmpty
                                    ? AppTheme.inactiveText
                                    : AppTheme.primaryText,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _addExclusionDate,
                            child: const Text('Add date'),
                          ),
                        ],
                      ),
                      if (_exclusionDates.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _exclusionDates
                              .map(
                                (date) => InputChip(
                                  label: Text(_formatAnchorDate(date)),
                                  onDeleted: () => _removeExclusionDate(date),
                                ),
                              )
                              .toList(),
                        ),
                      SizedBox(height: 1.8.h),
                      OutlinedButton.icon(
                        onPressed: _isPreviewing
                            ? null
                            : _previewPlannedTriggers,
                        icon: _isPreviewing
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.preview_rounded),
                        label: const Text('Preview planned triggers'),
                      ),
                      SizedBox(height: 3.h),
                      // Label
                      _buildLabelField(theme),
                      SizedBox(height: 3.h),
                      // Repeat with presets + custom day chips
                      _buildRepeatSection(theme),
                      SizedBox(height: 3.h),
                      // Sound Picker
                      Text(
                        'SOUND',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SoundPickerRowWidget(
                        selectedSound: _selectedSound,
                        onTap: _onSoundTap,
                      ),
                      SizedBox(height: 3.h),
                      // Challenge
                      Text(
                        'WAKE-UP CHALLENGE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ChallengeSelectorWidget(
                        selectedChallenge: _selectedChallenge,
                        challengeOptions: _challengeOptions,
                        onChallengeChanged: _onChallengeChanged,
                      ),
                      SizedBox(height: 3.h),
                      // Snooze Settings
                      Text(
                        'SNOOZE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SnoozeSettingsWidget(
                        snoozeDuration: _snoozeDuration,
                        snoozeCount: _snoozeCount,
                        onDurationChanged: _onSnoozeDurationChanged,
                        onCountChanged: _onSnoozeCountChanged,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'NAG MODE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      GestureDetector(
                        onTap: _showNagPolicySheet,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.subtleBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                color: AppTheme.inactiveText,
                                size: 20,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  _nagPolicySummary(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _nagEnabled
                                        ? AppTheme.primaryText
                                        : AppTheme.inactiveText,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.inactiveText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'PRIMARY ACTION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.inactiveText,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      GestureDetector(
                        onTap: _showPrimaryActionSheet,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.subtleBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                color: AppTheme.inactiveText,
                                size: 20,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  _primaryActionSummary(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _primaryAction == null
                                        ? AppTheme.inactiveText
                                        : AppTheme.primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.inactiveText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 7.h,
                child: ElevatedButton(
                  onPressed: _saveAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Alarm',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool emphasize = false,
  }) {
    return SizedBox(
      width: 88,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: emphasize ? FontWeight.w700 : null,
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
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
      selectedColor: AppTheme.accentOrange,
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: selected ? Colors.white : AppTheme.inactiveText,
      ),
      backgroundColor: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
        color: selected ? AppTheme.accentOrange : AppTheme.subtleBorder,
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
          color: selected ? AppTheme.accentOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.accentOrange : AppTheme.subtleBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? Colors.white : AppTheme.inactiveText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _OffsetChip extends StatelessWidget {
  const _OffsetChip({
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
      selectedColor: AppTheme.accentOrange,
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: selected ? Colors.white : AppTheme.inactiveText,
      ),
      backgroundColor: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
        color: selected ? AppTheme.accentOrange : AppTheme.subtleBorder,
      ),
    );
  }
}

class _NumberChoiceRow extends StatelessWidget {
  const _NumberChoiceRow({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.inactiveText),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values.map((value) {
            final active = value == selected;
            return ChoiceChip(
              label: Text('$value$suffix'),
              selected: active,
              onSelected: (_) => onChanged(value),
              selectedColor: AppTheme.accentOrange,
              backgroundColor: AppTheme.secondaryBackground,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: active ? Colors.white : AppTheme.inactiveText,
              ),
              side: BorderSide(
                color: active ? AppTheme.accentOrange : AppTheme.subtleBorder,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
