import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoundSectionHeaderWidget extends StatelessWidget {
  final String title;

  const SoundSectionHeaderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6A6A6A),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
