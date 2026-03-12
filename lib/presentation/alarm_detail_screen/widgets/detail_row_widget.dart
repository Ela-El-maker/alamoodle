import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class DetailRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final String iconName;
  final VoidCallback onTap;
  final Color? valueColor;

  const DetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    required this.iconName,
    required this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: const Color(0xFFFF7A1A),
                size: 5.w,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: valueColor ?? const Color(0xFFB8B8B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: const Color(0xFF666666),
                  size: 4.w,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
