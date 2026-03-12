import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TimeDisplayWidget extends StatelessWidget {
  final DateTime currentTime;
  final String alarmLabel;
  final AnimationController pulseController;

  const TimeDisplayWidget({
    super.key,
    required this.currentTime,
    required this.alarmLabel,
    required this.pulseController,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getAmPm(DateTime time) {
    return time.hour >= 12 ? 'PM' : 'AM';
  }

  String _heroCta(DateTime time, String label) {
    final normalized = label.toLowerCase();
    const eventKeywords = <String>[
      'meeting',
      'event',
      'exam',
      'medication',
      'travel',
      'reminder',
      'appointment',
    ];
    if (eventKeywords.any(normalized.contains)) {
      return 'BE READY';
    }

    final hour = time.hour;
    if (hour >= 5 && hour <= 11) return 'WAKE UP';
    if (hour >= 12 && hour <= 17) return 'STAY SHARP';
    if (hour >= 18 && hour <= 21) return 'EVENING';
    return 'NIGHT ALERT';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(currentTime),
                style: TextStyle(
                  fontSize: 22.w,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  _getAmPm(currentTime),
                  style: TextStyle(
                    fontSize: 5.w,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inactiveText,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        AnimatedBuilder(
          animation: pulseController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.7 + (pulseController.value * 0.3),
              child: child,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.accentOrange.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'alarm',
                    color: AppTheme.accentOrange,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _heroCta(currentTime, alarmLabel),
                    style: TextStyle(
                      fontSize: 4.5.w,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentOrange,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          alarmLabel,
          style: TextStyle(
            fontSize: 4.w,
            fontWeight: FontWeight.w400,
            color: AppTheme.inactiveText,
            letterSpacing: 1,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
