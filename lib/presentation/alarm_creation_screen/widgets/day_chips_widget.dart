import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class DayChipsWidget extends StatelessWidget {
  final List<bool> selectedDays;
  final ValueChanged<int> onDayToggled;

  const DayChipsWidget({
    super.key,
    required this.selectedDays,
    required this.onDayToggled,
  });

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = selectedDays[index];
        return GestureDetector(
          onTap: () => onDayToggled(index),
          child: AnimatedContainer(
            duration: AppTheme.fastAnimation,
            width: 11.w,
            height: 11.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppTheme.accentOrange
                  : AppTheme.secondaryBackground,
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentOrange
                    : AppTheme.subtleBorder,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _dayLabels[index],
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.inactiveText,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
