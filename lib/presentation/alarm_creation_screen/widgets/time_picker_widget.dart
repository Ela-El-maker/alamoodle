import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TimePickerWidget extends StatefulWidget {
  final TimeOfDay selectedTime;
  final bool use24HourFormat;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const TimePickerWidget({
    super.key,
    required this.selectedTime,
    required this.use24HourFormat,
    required this.onTimeChanged,
  });

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late int _hour;
  late int _minute;
  late bool _isAm;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _amPmController;

  @override
  void initState() {
    super.initState();
    _initializeFromSelectedTime();
  }

  @override
  void didUpdateWidget(covariant TimePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final formatChanged = oldWidget.use24HourFormat != widget.use24HourFormat;
    final selectedTimeChangedExternally =
        oldWidget.selectedTime != widget.selectedTime &&
        !_isInSyncWithSelectedTime();

    if (formatChanged || selectedTimeChangedExternally) {
      _hourController.dispose();
      _minuteController.dispose();
      _amPmController.dispose();
      _initializeFromSelectedTime();
      setState(() {});
    }
  }

  bool _isInSyncWithSelectedTime() {
    final expectedMinute = widget.selectedTime.minute;
    if (widget.use24HourFormat) {
      return _hour == widget.selectedTime.hour && _minute == expectedMinute;
    }
    final expectedHour = widget.selectedTime.hourOfPeriod == 0
        ? 12
        : widget.selectedTime.hourOfPeriod;
    final expectedIsAm = widget.selectedTime.period == DayPeriod.am;
    return _hour == expectedHour &&
        _minute == expectedMinute &&
        _isAm == expectedIsAm;
  }

  void _initializeFromSelectedTime() {
    if (widget.use24HourFormat) {
      _hour = widget.selectedTime.hour;
      _isAm = true;
    } else {
      _hour = widget.selectedTime.hourOfPeriod == 0
          ? 12
          : widget.selectedTime.hourOfPeriod;
      _isAm = widget.selectedTime.period == DayPeriod.am;
    }
    _minute = widget.selectedTime.minute;

    _hourController = FixedExtentScrollController(
      initialItem: widget.use24HourFormat ? _hour : _hour - 1,
    );
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _amPmController = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _amPmController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    int hour24;
    if (widget.use24HourFormat) {
      hour24 = _hour;
    } else {
      hour24 = _isAm
          ? (_hour == 12 ? 0 : _hour)
          : (_hour == 12 ? 12 : _hour + 12);
    }
    widget.onTimeChanged(TimeOfDay(hour: hour24, minute: _minute));
  }

  Widget _buildDrum({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
    double width = 60,
    double selectedFontSize = 36,
    double unselectedFontSize = 26,
  }) {
    return SizedBox(
      width: width,
      height: 22.h,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 56,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          HapticFeedback.selectionClick();
          onChanged(index);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index >= itemCount) return null;
            final isSelected =
                controller.hasClients && controller.selectedItem == index;
            return Center(
              child: Text(
                labelBuilder(index),
                style: TextStyle(
                  fontSize: isSelected ? selectedFontSize : unselectedFontSize,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w300,
                  color: isSelected
                      ? AppTheme.primaryText
                      : AppTheme.inactiveText,
                ),
              ),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.subtleBorder),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection highlight
          Container(
            height: 56,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentOrange.withValues(alpha: 0.3),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour drum
              _buildDrum(
                controller: _hourController,
                itemCount: widget.use24HourFormat ? 24 : 12,
                labelBuilder: (i) => widget.use24HourFormat
                    ? i.toString().padLeft(2, '0')
                    : (i + 1).toString().padLeft(2, '0'),
                onChanged: (i) {
                  setState(() => _hour = widget.use24HourFormat ? i : i + 1);
                  _notifyChange();
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ),
              // Minute drum
              _buildDrum(
                controller: _minuteController,
                itemCount: 60,
                labelBuilder: (i) => i.toString().padLeft(2, '0'),
                onChanged: (i) {
                  setState(() => _minute = i);
                  _notifyChange();
                },
              ),
              if (!widget.use24HourFormat) ...[
                SizedBox(width: 3.w),
                // AM/PM drum
                _buildDrum(
                  controller: _amPmController,
                  itemCount: 2,
                  labelBuilder: (i) => i == 0 ? 'AM' : 'PM',
                  onChanged: (i) {
                    setState(() => _isAm = i == 0);
                    _notifyChange();
                  },
                  width: 78,
                  selectedFontSize: 30,
                  unselectedFontSize: 22,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
