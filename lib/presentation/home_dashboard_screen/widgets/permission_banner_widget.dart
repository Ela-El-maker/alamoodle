import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PermissionBannerWidget extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onFix;

  const PermissionBannerWidget({
    super.key,
    required this.onDismiss,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: AppTheme.warningRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningRed.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'warning_amber',
            color: AppTheme.warningRed,
            size: 18,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Alarm permissions need attention',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warningRed,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: onFix,
            child: Text(
              'Fix',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.accentOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: onDismiss,
            child: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.inactiveText,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
