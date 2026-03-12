import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DismissSnoozeButtonsWidget extends StatelessWidget {
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;
  final int snoozeCount;
  final bool isChallengeEnabled;
  final int snoozeDuration;

  const DismissSnoozeButtonsWidget({
    super.key,
    required this.onSnooze,
    required this.onDismiss,
    required this.snoozeCount,
    required this.isChallengeEnabled,
    this.snoozeDuration = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: _buildSnoozeButton()),
              SizedBox(width: 4.w),
              Expanded(child: _buildDismissButton()),
            ],
          ),
          if (snoozeCount > 0) ...[
            SizedBox(height: 1.5.h),
            Text(
              'Snoozed $snoozeCount time${snoozeCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 3.w,
                color: AppTheme.warningRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSnoozeButton() {
    return GestureDetector(
      onTap: onSnooze,
      child: Container(
        height: 14.h,
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.subtleBorder, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'snooze',
              color: AppTheme.inactiveText,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              'SNOOZE',
              style: TextStyle(
                fontSize: 4.5.w,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryText,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '$snoozeDuration min',
              style: TextStyle(fontSize: 3.w, color: AppTheme.inactiveText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissButton() {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        height: 14.h,
        decoration: BoxDecoration(
          color: AppTheme.accentOrange.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentOrange, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: isChallengeEnabled ? 'extension' : 'alarm_off',
              color: AppTheme.accentOrange,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              'DISMISS',
              style: TextStyle(
                fontSize: 4.5.w,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentOrange,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              isChallengeEnabled ? 'solve first' : 'wake up',
              style: TextStyle(fontSize: 3.w, color: AppTheme.inactiveText),
            ),
          ],
        ),
      ),
    );
  }
}
