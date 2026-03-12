import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../platform/guardian_platform_api.dart';
import '../../../platform/guardian_platform_models.dart';

class OnboardingTestRingWidget extends StatefulWidget {
  const OnboardingTestRingWidget({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingTestRingWidget> createState() =>
      _OnboardingTestRingWidgetState();
}

class _OnboardingTestRingWidgetState extends State<OnboardingTestRingWidget>
    with SingleTickerProviderStateMixin {
  final GuardianPlatformApi _api = GuardianPlatformApi.instance;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isRunning = false;
  TestAlarmResultModel? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runNativeTest() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRunning = true;
      _error = null;
      _result = null;
    });
    _pulseController.repeat(reverse: true);

    try {
      final result = await _api.runTestAlarm();
      if (!mounted) return;
      setState(() {
        _result = result;
        _isRunning = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isRunning = false;
      });
    } finally {
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Run a real test alarm',
                  style: GoogleFonts.manrope(
                    fontSize: compact ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This schedules a native pipeline test (scheduler -> receiver -> service).',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFB8B8B8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(height: compact ? 280 : 360, child: _buildStateCard()),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runNativeTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isRunning ? 'Scheduling Test...' : 'Run Test Alarm',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onFinish();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB8B8B8),
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text(
                      'Finish Setup',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: _result?.success == true
              ? const Color(0xFF32D74B).withValues(alpha: 0.35)
              : const Color(0xFFFF7A1A).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRunning ? _pulseAnimation.value : 1,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _result?.success == true
                      ? Icons.check_circle_rounded
                      : _isRunning
                      ? Icons.schedule_rounded
                      : Icons.alarm_rounded,
                  color: _result?.success == true
                      ? const Color(0xFF32D74B)
                      : const Color(0xFFFF7A1A),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _isRunning
                      ? 'Scheduling native test alarm...'
                      : _result == null
                      ? 'Ready to verify native reliability'
                      : _result!.success
                      ? 'Native test scheduled successfully'
                      : 'Native test failed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ??
                      _result?.message ??
                      'Tap the button below to run now.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB8B8B8),
                  ),
                ),
                if (_result?.scheduledAtUtcMillis != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Scheduled at: ${DateTime.fromMillisecondsSinceEpoch(_result!.scheduledAtUtcMillis!, isUtc: true).toLocal()}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
