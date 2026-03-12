import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../theme/app_theme.dart';

/// Inline persistent error card (e.g. scheduling failure on an alarm card)
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color errorBg = Color(0x1AFF453A); // #FF453A at ~10% opacity
    const Color errorColor = Color(0xFFFF453A);

    if (compact) {
      // Compact inline warning strip (used on alarm card)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: errorBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: errorColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: errorColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: errorColor,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }

    // Full-screen error state with retry
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: errorBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: errorColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.alarm_off_rounded,
                  color: errorColor,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 2.5.h),
            Text(
              'Couldn\'t load alarms',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.inactiveText,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.primaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Static SnackBar helpers ─────────────────────────────────────────────

  /// Show a transient error SnackBar (dark surface, orange accent border)
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF151515),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFF7A1A), width: 1),
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: const Color(0xFFFF7A1A),
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show a success SnackBar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF151515),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF32D74B), width: 1),
        ),
      ),
    );
  }
}
