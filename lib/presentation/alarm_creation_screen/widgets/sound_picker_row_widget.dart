import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SoundPickerRowWidget extends StatelessWidget {
  final String selectedSound;
  final VoidCallback onTap;

  const SoundPickerRowWidget({
    super.key,
    required this.selectedSound,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.subtleBorder),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'music_note',
              color: AppTheme.accentOrange,
              size: 22,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                selectedSound,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.inactiveText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
