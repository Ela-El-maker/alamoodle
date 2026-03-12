import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NextAlarmWidget extends StatelessWidget {
  final Map<String, dynamic>? alarm;

  const NextAlarmWidget({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentOrange.withValues(alpha: 0.15),
            AppTheme.secondaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: alarm == null ? _buildNoAlarm(theme) : _buildNextAlarm(theme),
    );
  }

  Widget _buildNoAlarm(ThemeData theme) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'alarm_off',
          color: AppTheme.inactiveText,
          size: 32,
        ),
        SizedBox(height: 1.h),
        Text(
          'No upcoming alarms',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.inactiveText,
          ),
        ),
      ],
    );
  }

  Widget _buildNextAlarm(ThemeData theme) {
    final time = alarm!["time"] as String;
    final period = alarm!["period"] as String;
    final name = alarm!["name"] as String;
    final repeatDays = (alarm!["repeatDays"] as List);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'alarm',
              color: AppTheme.accentOrange,
              size: 16,
            ),
            SizedBox(width: 1.5.w),
            Text(
              'NEXT ALARM',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.accentOrange,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 28.sp,
                letterSpacing: -1,
              ),
            ),
            SizedBox(width: 2.w),
            Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Text(
                period,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.inactiveText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 2.w),
            Wrap(
              spacing: 4,
              children: repeatDays.take(3).map((day) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    day.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.accentOrange,
                      fontSize: 9,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }
}
