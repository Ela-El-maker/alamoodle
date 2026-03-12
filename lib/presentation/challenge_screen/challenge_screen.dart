import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/math_challenge_widget.dart';
import './widgets/memory_challenge_widget.dart';
import './widgets/qr_challenge_widget.dart';

enum ChallengeType { math, qr, memory }

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late ChallengeType _challengeType;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _challengeType = ChallengeType.math;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ChallengeType) {
      setState(() => _challengeType = args);
    } else if (args is String) {
      switch (args.toLowerCase()) {
        case 'qr':
          _challengeType = ChallengeType.qr;
          break;
        case 'steps':
        case 'walk':
          _challengeType = ChallengeType.math;
          break;
        case 'memory':
          _challengeType = ChallengeType.memory;
          break;
        default:
          _challengeType = ChallengeType.math;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onChallengeSolved() {
    HapticFeedback.heavyImpact();
    _showSuccessAndNavigate();
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: const Color(0xFF32D74B), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF32D74B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 10.w,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Challenge Complete!',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Alarm dismissed. Good morning!',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFB8B8B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(AppRoutes.homeDashboard);
      }
    });
  }

  String get _challengeTitle {
    switch (_challengeType) {
      case ChallengeType.math:
        return 'Math Challenge';
      case ChallengeType.qr:
        return 'QR Scan';
      case ChallengeType.memory:
        return 'Memory Challenge';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFF2D2D2D)),
                      ),
                      child: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: const Color(0xFFB8B8B8),
                        size: 5.w,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _challengeTitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Challenge type switcher
                  _buildTypeSwitcher(),
                ],
              ),
              SizedBox(height: 3.h),
              // Challenge content
              Expanded(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _challengeType == ChallengeType.math
                          ? _pulseAnimation.value
                          : 1.0,
                      child: child,
                    );
                  },
                  child: _buildChallengeContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSwitcher() {
    return GestureDetector(
      onTap: () => _showTypePicker(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFF2D2D2D)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'swap_horiz',
              color: const Color(0xFFFF7A1A),
              size: 4.w,
            ),
            SizedBox(width: 1.w),
            Text(
              'Switch',
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFFFF7A1A)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
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
                  'Choose Challenge',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildTypeOption(
                  ctx,
                  ChallengeType.math,
                  'Math',
                  'Solve an equation',
                  'calculate',
                ),
                _buildTypeOption(
                  ctx,
                  ChallengeType.qr,
                  'QR Scan',
                  'Scan a QR code',
                  'qr_code_scanner',
                ),
                _buildTypeOption(
                  ctx,
                  ChallengeType.memory,
                  'Memory',
                  'Repeat the sequence',
                  'grid_view',
                ),
                SizedBox(height: 1.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeOption(
    BuildContext ctx,
    ChallengeType type,
    String title,
    String subtitle,
    String icon,
  ) {
    final isSelected = _challengeType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _challengeType = type);
        Navigator.pop(ctx);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
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
                iconName: icon,
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
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFFF7A1A)
                          : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
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
  }

  Widget _buildChallengeContent() {
    switch (_challengeType) {
      case ChallengeType.math:
        return MathChallengeWidget(onSolved: _onChallengeSolved);
      case ChallengeType.qr:
        return QrChallengeWidget(onSolved: _onChallengeSolved);
      case ChallengeType.memory:
        return MemoryChallengeWidget(onSolved: _onChallengeSolved);
    }
  }
}
