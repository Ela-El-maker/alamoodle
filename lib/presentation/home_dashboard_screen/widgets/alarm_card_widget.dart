import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AlarmCardWidget extends StatelessWidget {
  final Map<String, dynamic> alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const AlarmCardWidget({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool enabled = alarm["enabled"] as bool;
    final String time = alarm["time"] as String;
    final String period = alarm["period"] as String;
    final String name = alarm["name"] as String;
    final List repeatDays = alarm["repeatDays"] as List;
    final String challenge = alarm["challenge"] as String;

    return Slidable(
      key: ValueKey(alarm["id"]),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: AppTheme.primaryText,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppTheme.warningRed,
            foregroundColor: AppTheme.primaryText,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTheme.fastAnimation,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.secondaryBackground
                : AppTheme.secondaryBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? AppTheme.subtleBorder
                  : AppTheme.subtleBorder.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: enabled
                                ? AppTheme.primaryText
                                : AppTheme.inactiveText,
                            fontWeight: FontWeight.w700,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(width: 1.5.w),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            period,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: enabled
                                  ? AppTheme.accentOrange
                                  : AppTheme.inactiveText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? AppTheme.inactiveText
                            : AppTheme.inactiveText.withValues(alpha: 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 0.8.h),
                    Row(
                      children: [
                        _buildChallengeBadge(theme, challenge, enabled),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: repeatDays.take(4).map((day) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: enabled
                                      ? AppTheme.accentOrange.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppTheme.subtleBorder.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  day.toString(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: enabled
                                        ? AppTheme.accentOrange
                                        : AppTheme.inactiveText.withValues(
                                            alpha: 0.5,
                                          ),
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: AppTheme.accentOrange,
                activeTrackColor: AppTheme.accentOrange.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.inactiveText,
                inactiveTrackColor: AppTheme.subtleBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeBadge(ThemeData theme, String challenge, bool enabled) {
    IconData icon;
    switch (challenge) {
      case 'Math Puzzle':
        icon = Icons.calculate_outlined;
        break;
      case 'Memory Tiles':
        icon = Icons.grid_view_outlined;
        break;
      case 'QR Scanner':
        icon = Icons.qr_code_scanner_outlined;
        break;
      case 'Walking Counter':
        icon = Icons.directions_walk_outlined;
        break;
      case 'Shake Phone':
        icon = Icons.vibration_outlined;
        break;
      default:
        icon = Icons.extension_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: enabled
            ? AppTheme.challengeAccent.withValues(alpha: 0.1)
            : AppTheme.subtleBorder.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enabled
              ? AppTheme.challengeAccent.withValues(alpha: 0.3)
              : AppTheme.subtleBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: enabled ? AppTheme.challengeAccent : AppTheme.inactiveText,
          ),
          const SizedBox(width: 3),
          Text(
            challenge,
            style: theme.textTheme.labelSmall?.copyWith(
              color: enabled ? AppTheme.challengeAccent : AppTheme.inactiveText,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
