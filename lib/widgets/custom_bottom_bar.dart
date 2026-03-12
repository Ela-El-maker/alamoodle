import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBackground,
        border: Border(top: BorderSide(color: AppTheme.subtleBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.access_time_outlined,
                activeIcon: Icons.access_time_filled,
                label: 'Home',
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                label: 'Add',
                isAccent: true,
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Stats',
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isAccent = false,
  }) {
    final bool isSelected = currentIndex == index;
    final Color selectedColor = isAccent
        ? AppTheme.accentOrange
        : AppTheme.accentOrange;
    final Color unselectedColor = AppTheme.inactiveText;
    final Color itemColor = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppTheme.fastAnimation,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppTheme.fastAnimation,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: itemColor,
                  size: isAccent ? 28 : 24,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: AppTheme.fastAnimation,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: itemColor,
                  letterSpacing: 0.5,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 1),
              AnimatedContainer(
                duration: AppTheme.fastAnimation,
                height: 2,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
