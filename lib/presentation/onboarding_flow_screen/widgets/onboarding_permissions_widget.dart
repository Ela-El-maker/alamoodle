import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../platform/guardian_platform_api.dart';
import '../../../platform/guardian_platform_models.dart';

class OnboardingPermissionsWidget extends StatefulWidget {
  const OnboardingPermissionsWidget({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<OnboardingPermissionsWidget> createState() =>
      _OnboardingPermissionsWidgetState();
}

class _OnboardingPermissionsWidgetState
    extends State<OnboardingPermissionsWidget> {
  final GuardianPlatformApi _api = GuardianPlatformApi.instance;

  OnboardingReadinessModel? _readiness;
  OemGuidanceModel? _oemGuidance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReadiness();
  }

  Future<void> _loadReadiness() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final readiness = await _api.getOnboardingReadiness();
      final oemGuidance = await _api.getOemGuidance();
      if (!mounted) return;
      setState(() {
        _readiness = readiness;
        _oemGuidance = oemGuidance;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission(String key) async {
    HapticFeedback.mediumImpact();
    final target = switch (key) {
      'exact_alarms' => 'exact_alarm',
      'notifications' => 'notifications',
      'battery' => 'battery_optimization',
      _ => 'app_details',
    };

    await _api.openSystemSettings(target);
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _loadReadiness();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7A1A)),
      );
    }

    if (_error != null || _readiness == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Unable to load native readiness',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFFB8B8B8),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadReadiness, child: const Text('Retry')),
          ],
        ),
      );
    }

    final readiness = _readiness!;
    final exactGranted = readiness.exactAlarmReady;
    final notificationsGranted = readiness.notificationsReady;
    final batterySafe = readiness.batteryOptimizationRisk == 'low';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Allow permissions',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Live native checks. These settings determine whether alarms reliably fire.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFB8B8B8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _PermissionCard(
                  icon: Icons.alarm_rounded,
                  title: 'Exact Alarms',
                  description:
                      'Required for precise schedule delivery (main, pre-alert, snooze).',
                  isGranted: exactGranted,
                  isCritical: true,
                  onAllow: () => _requestPermission('exact_alarms'),
                ),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  description:
                      'Required for visible ring controls and lock-screen actions.',
                  isGranted: notificationsGranted,
                  isCritical: true,
                  onAllow: () => _requestPermission('notifications'),
                ),
                const SizedBox(height: 12),
                _PermissionCard(
                  icon: Icons.battery_saver_rounded,
                  title: 'Battery Optimization',
                  description:
                      'Low risk is recommended for consistent alarm execution.',
                  isGranted: batterySafe,
                  isCritical: false,
                  onAllow: () => _requestPermission('battery'),
                ),
                if (_oemGuidance != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Text(
                      '${_oemGuidance!.manufacturer.toUpperCase()}: ${_oemGuidance!.summary}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFFB8B8B8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Note: Android and OEM power policies can still delay alarms in extreme states (for example after force-stop or when the phone is powered off).',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    color: const Color(0xFF8F8F8F),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onNext();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _loadReadiness,
                    child: Text(
                      'Re-check status',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB8B8B8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.isCritical,
    required this.onAllow,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isCritical;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF32D74B).withValues(alpha: 0.3)
              : isCritical
              ? const Color(0xFFFF7A1A).withValues(alpha: 0.2)
              : const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF32D74B).withValues(alpha: 0.12)
                  : const Color(0xFFFF7A1A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              isGranted ? Icons.check_rounded : icon,
              color: isGranted
                  ? const Color(0xFF32D74B)
                  : const Color(0xFFFF7A1A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (isCritical && !isGranted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF453A,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          'Required',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF453A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFB8B8B8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          isGranted
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF32D74B),
                  size: 24,
                )
              : GestureDetector(
                  onTap: onAllow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A1A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Fix',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF7A1A),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
