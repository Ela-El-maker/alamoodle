import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ChallengeSheetWidget extends StatefulWidget {
  final String currentChallenge;
  final Function(String) onChanged;

  const ChallengeSheetWidget({
    super.key,
    required this.currentChallenge,
    required this.onChanged,
  });

  @override
  State<ChallengeSheetWidget> createState() => _ChallengeSheetWidgetState();
}

class _ChallengeSheetWidgetState extends State<ChallengeSheetWidget> {
  late String _selected;

  final List<Map<String, String>> _options = [
    {
      'name': 'Off',
      'desc': 'No challenge required',
      'icon': 'do_not_disturb_off',
    },
    {'name': 'Math', 'desc': 'Solve a math equation', 'icon': 'calculate'},
    {'name': 'QR Code', 'desc': 'Scan a QR code', 'icon': 'qr_code_scanner'},
    {'name': 'Memory', 'desc': 'Repeat a color sequence', 'icon': 'grid_view'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentChallenge;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 10.w,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Wake-up Challenge',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            ..._options.map((opt) {
              final isSelected = _selected == opt['name'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = opt['name']!);
                  widget.onChanged(opt['name']!);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF7A1A).withValues(alpha: 0.15)
                        : const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF7A1A)
                          : const Color(0xFF2D2D2D),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF7A1A).withValues(alpha: 0.2)
                              : const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: CustomIconWidget(
                          iconName: opt['icon']!,
                          color: isSelected
                              ? const Color(0xFFFF7A1A)
                              : const Color(0xFFB8B8B8),
                          size: 5.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['name']!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFFF7A1A)
                                    : Colors.white,
                              ),
                            ),
                            Text(
                              opt['desc']!,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFFB8B8B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: const Color(0xFFFF7A1A),
                          size: 5.w,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
