import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatMetricCardWidget extends StatelessWidget {
  final String value;
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final List<double>? trendData;

  const StatMetricCardWidget({
    super.key,
    required this.value,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.trendData,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final iconContainer = compact ? 34.0 : 40.0;
        final iconSize = compact ? 18.0 : 20.0;
        final horizontalPadding = compact ? 12.0 : 16.0;
        final verticalPadding = compact ? 12.0 : 16.0;
        final valueFont = compact ? 24.0 : 30.0;
        final labelFont = compact ? 12.0 : 13.0;
        final subtitleFont = compact ? 10.0 : 11.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconContainer,
                    height: iconContainer,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(icon, color: accentColor, size: iconSize),
                  ),
                  if (trendData != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _MiniTrendLine(
                          data: trendData!,
                          color: accentColor,
                          compact: compact,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: GoogleFonts.manrope(
                    fontSize: valueFont,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: labelFont,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFB8B8B8),
                ),
              ),
              const Spacer(),
              if (subtitle != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 8,
                    vertical: compact ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: subtitleFont,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniTrendLine extends StatelessWidget {
  final List<double> data;
  final Color color;
  final bool compact;

  const _MiniTrendLine({
    required this.data,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 48 : 60,
      height: compact ? 22 : 28,
      child: CustomPaint(
        painter: _TrendLinePainter(data: data, color: color),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _TrendLinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
