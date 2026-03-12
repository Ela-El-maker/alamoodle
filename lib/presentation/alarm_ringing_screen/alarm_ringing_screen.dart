import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../alarm/config/alarm_engine_mode.dart';
import '../../core/app_export.dart';
import '../../services/alarm_notification_service.dart';
import '../../services/haptic_service.dart';
import './widgets/challenge_widget.dart';
import './widgets/dismiss_snooze_buttons_widget.dart';
import './widgets/swipe_indicator_widget.dart';
import './widgets/time_display_widget.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _gradientAnimation;
  late Timer _timeTimer;

  DateTime _currentTime = DateTime.now();
  int _snoozeCount = 0;
  bool _showChallenge = false;
  bool _isSnoozing = false;

  // Alarm data read from route arguments
  int _alarmId = 1;
  String _alarmLabel = 'Morning Alarm';
  int _snoozeDuration = 5; // minutes
  bool _isChallengeEnabled = false;
  String _soundName = 'Default Alarm';
  String _challenge = 'None';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTimeTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    HapticService.alarmRinging();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read alarm data from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _alarmId = args['id'] as int? ?? 1;
      _alarmLabel =
          args['name'] as String? ?? args['label'] as String? ?? 'Alarm';
      _snoozeDuration = args['snoozeDuration'] as int? ?? 5;
      _isChallengeEnabled = (args['challenge'] as String? ?? 'None') != 'None';
      _soundName = args['sound'] as String? ?? 'Default Alarm';
      _challenge = args['challenge'] as String? ?? 'None';
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
  }

  void _startTimeTimer() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _handleSnooze() async {
    if (_isSnoozing) return;
    setState(() => _isSnoozing = true);

    // Haptic: snooze activated pattern
    await HapticService.snoozeActivated();

    if (kNativeRingPipelineEnabled && !kLegacyEmergencyRingFallbackEnabled) {
      if (!mounted) return;
      setState(() => _isSnoozing = false);
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed(AppRoutes.homeDashboard);
      return;
    }

    // Reschedule alarm notification X minutes from now
    final int snoozeId = await AlarmNotificationService.instance.snoozeAlarm(
      alarmId: _alarmId,
      label: _alarmLabel,
      snoozeMinutes: _snoozeDuration,
      soundName: _soundName,
      challenge: _challenge,
    );

    final bool snoozeOk = snoozeId != -1;

    if (mounted) {
      setState(() {
        _snoozeCount++;
        _isSnoozing = false;
      });

      // Snooze success haptic
      if (snoozeOk) {
        await HapticService.snoozeSuccess();
        if (!mounted) return;
      }

      // Show snooze confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                snoozeOk ? Icons.snooze_rounded : Icons.warning_amber_rounded,
                color: snoozeOk ? AppTheme.accentOrange : AppTheme.warningRed,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  snoozeOk
                      ? 'Snoozed $_snoozeDuration min · rings again soon'
                      : 'Snooze scheduled (notification may be delayed)',
                  style: TextStyle(color: AppTheme.primaryText, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.secondaryBackground,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: snoozeOk ? AppTheme.accentOrange : AppTheme.warningRed,
              width: 1,
            ),
          ),
        ),
      );

      // Navigate back to home with snooze result
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushReplacementNamed(AppRoutes.homeDashboard);
        }
      });
    }
  }

  void _handleDismiss() {
    if (_isChallengeEnabled) {
      HapticService.buttonMedium();
      setState(() {
        _showChallenge = true;
      });
    } else {
      _dismissAlarm();
    }
  }

  void _dismissAlarm() {
    HapticService.alarmDismissed();
    _pulseController.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(AppRoutes.homeDashboard);
  }

  void _onChallengeSolved() {
    _dismissAlarm();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gradientController.dispose();
    _timeTimer.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -300) {
              _handleDismiss();
            } else if (details.primaryVelocity! > 300) {
              _handleSnooze();
            }
          }
        },
        child: AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      AppTheme.primaryBackground,
                      const Color(0xFF1A0A00),
                      _gradientAnimation.value * 0.6,
                    )!,
                    AppTheme.primaryBackground,
                    Color.lerp(
                      AppTheme.primaryBackground,
                      const Color(0xFF0D0500),
                      _gradientAnimation.value * 0.4,
                    )!,
                  ],
                ),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: _showChallenge
                ? ChallengeWidget(
                    onSolved: _onChallengeSolved,
                    onCancel: () => setState(() => _showChallenge = false),
                  )
                : _buildMainRingingUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainRingingUI() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: SwipeIndicatorWidget(
            direction: SwipeDirection.up,
            label: 'Swipe up to dismiss',
          ),
        ),
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: TimeDisplayWidget(
              currentTime: _currentTime,
              alarmLabel: _alarmLabel,
              pulseController: _pulseController,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: DismissSnoozeButtonsWidget(
            onSnooze: _handleSnooze,
            onDismiss: _handleDismiss,
            snoozeCount: _snoozeCount,
            isChallengeEnabled: _isChallengeEnabled,
            snoozeDuration: _snoozeDuration,
          ),
        ),
        Expanded(
          flex: 1,
          child: SwipeIndicatorWidget(
            direction: SwipeDirection.down,
            label: 'Swipe down to snooze',
          ),
        ),
      ],
    );
  }
}
