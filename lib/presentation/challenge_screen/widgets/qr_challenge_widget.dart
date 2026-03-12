import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class QrChallengeWidget extends StatefulWidget {
  final VoidCallback onSolved;

  const QrChallengeWidget({super.key, required this.onSolved});

  @override
  State<QrChallengeWidget> createState() => _QrChallengeWidgetState();
}

class _QrChallengeWidgetState extends State<QrChallengeWidget>
    with SingleTickerProviderStateMixin {
  bool _flashlightOn = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  void _toggleFlashlight() {
    HapticFeedback.selectionClick();
    setState(() => _flashlightOn = !_flashlightOn);
  }

  void _simulateScan() {
    HapticFeedback.heavyImpact();
    widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Scan bathroom code to dismiss',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8B8B8),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        Expanded(
          child: Stack(
            children: [
              // Camera preview simulation
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Stack(
                    children: [
                      // Dark camera background
                      Container(
                        color: _flashlightOn
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF050505),
                      ),
                      // QR frame overlay
                      Center(
                        child: Container(
                          width: 55.w,
                          height: 55.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFFF7A1A),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Stack(
                            children: [
                              // Corner decorations
                              Positioned(
                                top: 0,
                                left: 0,
                                child: _buildCorner(),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Transform.rotate(
                                  angle: 1.5708,
                                  child: _buildCorner(),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Transform.rotate(
                                  angle: -1.5708,
                                  child: _buildCorner(),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Transform.rotate(
                                  angle: 3.14159,
                                  child: _buildCorner(),
                                ),
                              ),
                              // Scan line
                              AnimatedBuilder(
                                animation: _scanLineAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: _scanLineAnimation.value * 55.w - 1,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            const Color(
                                              0xFFFF7A1A,
                                            ).withValues(alpha: 0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Flashlight button
              Positioned(
                top: 2.h,
                right: 4.w,
                child: GestureDetector(
                  onTap: _toggleFlashlight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _flashlightOn
                          ? const Color(0xFFFF7A1A)
                          : const Color(0xFF151515),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2D2D2D)),
                    ),
                    child: CustomIconWidget(
                      iconName: _flashlightOn
                          ? 'flashlight_on'
                          : 'flashlight_off',
                      color: Colors.white,
                      size: 6.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        // Fallback button
        GestureDetector(
          onTap: _simulateScan,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF2D2D2D)),
            ),
            child: Text(
              'Tap to simulate scan (demo)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFFB8B8B8)),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Point camera at the QR code placed in another room',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildCorner() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFFF7A1A), width: 3),
          left: BorderSide(color: Color(0xFFFF7A1A), width: 3),
        ),
      ),
    );
  }
}
