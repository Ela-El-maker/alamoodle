import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToughestAlarmWidget extends StatelessWidget {
  const ToughestAlarmWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFFFFB020).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB020).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFFB020),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Toughest Alarm',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB8B8B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '05:45',
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'AM',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB8B8B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gym Days • Snoozed avg 3.2×',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB8B8B8),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: 0.68,
              backgroundColor: const Color(0xFFFFB020).withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFB020),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '68% dismiss rate on first ring',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB8B8B8),
            ),
          ),
        ],
      ),
    );
  }
}
