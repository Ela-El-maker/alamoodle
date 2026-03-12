import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class SnoozeSheetWidget extends StatefulWidget {
  final int duration;
  final int count;
  final Function(int, int) onChanged;

  const SnoozeSheetWidget({
    super.key,
    required this.duration,
    required this.count,
    required this.onChanged,
  });

  @override
  State<SnoozeSheetWidget> createState() => _SnoozeSheetWidgetState();
}

class _SnoozeSheetWidgetState extends State<SnoozeSheetWidget> {
  late int _duration;
  late int _count;
  final List<int> _durations = [1, 2, 5, 10, 15, 20, 30];
  final List<int> _counts = [1, 2, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _duration = widget.duration;
    _count = widget.count;
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
              'Snooze Settings',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Duration',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB8B8B8)),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _durations.map((d) {
                final isSelected = _duration == d;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _duration = d);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A1A)
                          : const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF7A1A)
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                    child: Text(
                      '$d min',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFB8B8B8),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 2.h),
            Text(
              'Max snoozes',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB8B8B8)),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _counts.map((c) {
                final isSelected = _count == c;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _count = c);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A1A)
                          : const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF7A1A)
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                    child: Text(
                      '$c ${c == 1 ? "time" : "times"}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFB8B8B8),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onChanged(_duration, _count);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A1A),
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
