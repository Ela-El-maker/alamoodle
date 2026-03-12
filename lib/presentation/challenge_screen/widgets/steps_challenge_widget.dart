import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class StepsChallengeWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final int targetSteps;

  const StepsChallengeWidget({
    super.key,
    required this.onSolved,
    this.targetSteps = 20,
  });

  @override
  State<StepsChallengeWidget> createState() => _StepsChallengeWidgetState();
}

class _StepsChallengeWidgetState extends State<StepsChallengeWidget>
    with SingleTickerProviderStateMixin {
  int _currentSteps = 0;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _addStep() {
    HapticFeedback.selectionClick();
    if (_currentSteps >= widget.targetSteps) return;
    setState(() {
      _currentSteps++;
    });
    final newProgress = _currentSteps / widget.targetSteps;
    _progressAnimation =
        Tween<double>(
          begin: _progressAnimation.value,
          end: newProgress,
        ).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
        );
    _progressController.forward(from: 0);

    if (_currentSteps >= widget.targetSteps) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 600), widget.onSolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _currentSteps >= widget.targetSteps;

    return Column(
      children: [
        Text(
          'Walk ${widget.targetSteps} steps to dismiss',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8B8B8),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _addStep,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 65.w,
                    height: 65.w,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: _progressAnimation.value,
                        isComplete: isComplete,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_currentSteps',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: isComplete
                                    ? const Color(0xFF32D74B)
                                    : Colors.white,
                              ),
                            ),
                            Text(
                              '/ ${widget.targetSteps}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFFB8B8B8),
                              ),
                            ),
                            if (isComplete)
                              Text(
                                '✓',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: const Color(0xFF32D74B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          isComplete ? 'Great job! Dismissing...' : 'Keep moving',
          style: TextStyle(
            fontSize: 13.sp,
            color: isComplete
                ? const Color(0xFF32D74B)
                : const Color(0xFFB8B8B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        if (!isComplete)
          GestureDetector(
            onTap: _addStep,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFF2D2D2D)),
              ),
              child: Text(
                'Tap to count step (demo)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFB8B8B8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isComplete;

  _CircularProgressPainter({required this.progress, required this.isComplete});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = isComplete ? const Color(0xFF32D74B) : const Color(0xFFFF7A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isComplete != isComplete;
}
