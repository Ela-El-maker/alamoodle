import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingWelcomeWidget extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingWelcomeWidget({super.key, required this.onNext});

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
              children: [
                SizedBox(height: compact ? 12 : 36),
                Container(
                  width: compact ? 82 : 100,
                  height: compact ? 82 : 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A1A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: const Color(0xFFFF7A1A).withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '⏰',
                      style: TextStyle(fontSize: compact ? 40 : 48),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 20 : 32),
                Text(
                  'Wake up,\nwithout the struggle.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: compact ? 28 : 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A smarter alarm built for sleepy mornings.\nSimple, reliable, and impossible to miss.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFB8B8B8),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: compact ? 28 : 56),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onNext();
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
                      'Set your first alarm',
                      style: GoogleFonts.manrope(
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onNext();
                  },
                  child: Text(
                    'Skip intro',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB8B8B8),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
