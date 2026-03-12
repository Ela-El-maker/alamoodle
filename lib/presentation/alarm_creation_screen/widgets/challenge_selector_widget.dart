import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ChallengeSelectorWidget extends StatelessWidget {
  final String selectedChallenge;
  final List<String> challengeOptions;
  final ValueChanged<String> onChallengeChanged;

  const ChallengeSelectorWidget({
    super.key,
    required this.selectedChallenge,
    required this.challengeOptions,
    required this.onChallengeChanged,
  });

  IconData _iconForChallenge(String challenge) {
    switch (challenge) {
      case 'Math':
        return Icons.calculate_outlined;
      case 'Memory':
        return Icons.grid_view_outlined;
      case 'QR Code':
        return Icons.qr_code_scanner;
      case 'Walking':
        return Icons.directions_walk_outlined;
      case 'Shake':
        return Icons.vibration;
      default:
        return Icons.block_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: challengeOptions.map((option) {
        final isSelected = option == selectedChallenge;
        return GestureDetector(
          onTap: () => onChallengeChanged(option),
          child: AnimatedContainer(
            duration: AppTheme.fastAnimation,
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentOrange
                  : AppTheme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentOrange
                    : AppTheme.subtleBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForChallenge(option),
                  size: 16,
                  color: isSelected ? Colors.white : AppTheme.inactiveText,
                ),
                SizedBox(width: 1.5.w),
                Text(
                  option,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.white : AppTheme.inactiveText,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
