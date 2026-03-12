import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SnoozeSettingsWidget extends StatelessWidget {
  final int snoozeDuration;
  final int snoozeCount;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<int> onCountChanged;

  const SnoozeSettingsWidget({
    super.key,
    required this.snoozeDuration,
    required this.snoozeCount,
    required this.onDurationChanged,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.subtleBorder),
      ),
      child: Column(
        children: [
          _buildStepperRow(
            context: context,
            label: 'Duration',
            value: snoozeDuration,
            unit: 'min',
            min: 1,
            max: 30,
            onDecrement: () {
              if (snoozeDuration > 1) onDurationChanged(snoozeDuration - 1);
            },
            onIncrement: () {
              if (snoozeDuration < 30) onDurationChanged(snoozeDuration + 1);
            },
          ),
          Divider(color: AppTheme.subtleBorder, height: 2.h),
          _buildStepperRow(
            context: context,
            label: 'Max Snoozes',
            value: snoozeCount,
            unit: 'times',
            min: 1,
            max: 10,
            onDecrement: () {
              if (snoozeCount > 1) onCountChanged(snoozeCount - 1);
            },
            onIncrement: () {
              if (snoozeCount < 10) onCountChanged(snoozeCount + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepperRow({
    required BuildContext context,
    required String label,
    required int value,
    required String unit,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepButton(
              icon: 'remove',
              onTap: onDecrement,
              enabled: value > min,
            ),
            SizedBox(width: 2.w),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 66, maxWidth: 96),
              child: Text(
                '$value $unit',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            _stepButton(icon: 'add', onTap: onIncrement, enabled: value < max),
          ],
        );

        final isCompact = constraints.maxWidth < 290;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryText,
                ),
              ),
              SizedBox(height: 1.h),
              Align(alignment: Alignment.centerRight, child: controls),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryText,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            controls,
          ],
        );
      },
    );
  }

  Widget _stepButton({
    required String icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.accentOrange.withValues(alpha: 0.15)
              : AppTheme.subtleBorder.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppTheme.accentOrange.withValues(alpha: 0.4)
                : AppTheme.subtleBorder,
          ),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: icon,
            color: enabled ? AppTheme.accentOrange : AppTheme.inactiveText,
            size: 18,
          ),
        ),
      ),
    );
  }
}
