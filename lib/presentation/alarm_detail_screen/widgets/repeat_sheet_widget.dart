import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class RepeatSheetWidget extends StatefulWidget {
  final String currentRepeat;
  final List<bool> selectedDays;
  final Function(String, List<bool>) onChanged;

  const RepeatSheetWidget({
    super.key,
    required this.currentRepeat,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  State<RepeatSheetWidget> createState() => _RepeatSheetWidgetState();
}

class _RepeatSheetWidgetState extends State<RepeatSheetWidget> {
  late String _selected;
  late List<bool> _days;
  final List<String> _presets = ['Once', 'Weekdays', 'Every day', 'Custom'];
  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentRepeat;
    _days = List.from(widget.selectedDays);
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
              'Repeat',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            // Preset chips
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _presets.map((preset) {
                final isSelected = _selected == preset;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selected = preset;
                      if (preset == 'Weekdays') {
                        _days = [true, true, true, true, true, false, false];
                      } else if (preset == 'Every day') {
                        _days = List.filled(7, true);
                      } else if (preset == 'Once') {
                        _days = List.filled(7, false);
                      }
                    });
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
                      preset,
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
            if (_selected == 'Custom') ...[
              SizedBox(height: 2.h),
              Text(
                'Select days',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFB8B8B8),
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final isOn = _days[i];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _days[i] = !_days[i]);
                    },
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: isOn
                            ? const Color(0xFFFF7A1A)
                            : const Color(0xFF0A0A0A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOn
                              ? const Color(0xFFFF7A1A)
                              : const Color(0xFF2D2D2D),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: isOn
                                ? Colors.white
                                : const Color(0xFFB8B8B8),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onChanged(_selected, _days);
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
