import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakBannerWidget extends StatelessWidget {
  final int streakDays;
  final VoidCallback? onTap;

  const StreakBannerWidget({super.key, required this.streakDays, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final horizontalPadding = compact ? 14.0 : 20.0;
        final verticalPadding = compact ? 14.0 : 20.0;
        final iconSize = compact ? 44.0 : 52.0;
        final titleSize = compact ? 18.0 : 22.0;
        final subtitleSize = compact ? 12.0 : 13.0;
        final title = streakDays == 1
            ? '1-day streak'
            : '$streakDays-day streak';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.0),
            child: Ink(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF7A1A).withValues(alpha: 0.18),
                    const Color(0xFFFF7A1A).withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: const Color(0xFFFF7A1A).withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A1A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: const Center(
                      child: Text('🔥', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to view daily streak details',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFB8B8B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF7A1A),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
