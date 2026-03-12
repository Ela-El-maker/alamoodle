import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import './widgets/onboarding_welcome_widget.dart';
import './widgets/onboarding_permissions_widget.dart';
import './widgets/onboarding_test_ring_widget.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _buildStepIndicator(),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingWelcomeWidget(onNext: _nextStep),
                  OnboardingPermissionsWidget(onNext: _nextStep),
                  OnboardingTestRingWidget(onFinish: _finishOnboarding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive || isCompleted
                        ? const Color(0xFFFF7A1A)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 16),
        _currentStep > 0
            ? GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _currentStep--);
                  _pageController.animateToPage(
                    _currentStep,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFFB8B8B8),
                    size: 16,
                  ),
                ),
              )
            : const SizedBox(width: 36),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _finishOnboarding();
          },
          child: Text(
            'Skip',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB8B8B8),
            ),
          ),
        ),
      ],
    );
  }
}
