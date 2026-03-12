import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

enum SwipeDirection { up, down }

class SwipeIndicatorWidget extends StatelessWidget {
  final SwipeDirection direction;
  final String label;

  const SwipeIndicatorWidget({
    super.key,
    required this.direction,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = direction == SwipeDirection.up;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isUp)
          CustomIconWidget(
            iconName: 'keyboard_arrow_down',
            color: AppTheme.inactiveText.withValues(alpha: 0.5),
            size: 5.w,
          ),
        Text(
          label,
          style: TextStyle(
            fontSize: 2.8.w,
            color: AppTheme.inactiveText.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        if (isUp)
          CustomIconWidget(
            iconName: 'keyboard_arrow_up',
            color: AppTheme.inactiveText.withValues(alpha: 0.5),
            size: 5.w,
          ),
      ],
    );
  }
}
