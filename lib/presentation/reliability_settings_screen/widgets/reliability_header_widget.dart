import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReliabilityHeaderWidget extends StatelessWidget {
  final int criticalCount;
  final int warningCount;
  final int okCount;

  const ReliabilityHeaderWidget({
    super.key,
    required this.criticalCount,
    required this.warningCount,
    required this.okCount,
  });

  @override
  Widget build(BuildContext context) {
    final bool allGood = criticalCount == 0 && warningCount == 0;
    final Color headerColor = criticalCount > 0
        ? const Color(0xFFFF453A)
        : warningCount > 0
        ? const Color(0xFFFFB020)
        : const Color(0xFF32D74B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final iconSize = compact ? 44.0 : 52.0;
        final titleSize = compact ? 15.0 : 16.0;
        final subtitleSize = compact ? 12.0 : 13.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            color: headerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: headerColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allGood ? Icons.verified_rounded : Icons.shield_outlined,
                  color: headerColor,
                  size: compact ? 22 : 26,
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allGood ? 'All systems ready' : 'Action needed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: headerColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allGood
                          ? 'Your alarms will ring reliably'
                          : '${criticalCount > 0 ? '$criticalCount critical' : ''}${criticalCount > 0 && warningCount > 0 ? ', ' : ''}${warningCount > 0 ? '$warningCount warning' : ''} issue${(criticalCount + warningCount) > 1 ? 's' : ''} found',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: subtitleSize,
                        color: const Color(0xFFB8B8B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _buildBadge(okCount.toString(), const Color(0xFF32D74B)),
                  const SizedBox(height: 4),
                  Text(
                    'OK',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: const Color(0xFF6A6A6A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String count, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}
