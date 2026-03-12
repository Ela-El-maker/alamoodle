import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum PermissionStatus { ok, warning, critical }

class PermissionStatusRowWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusLabel;
  final PermissionStatus status;
  final VoidCallback? onFix;

  const PermissionStatusRowWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.status,
    this.onFix,
  });

  Color get _statusColor {
    switch (status) {
      case PermissionStatus.ok:
        return const Color(0xFF32D74B);
      case PermissionStatus.warning:
        return const Color(0xFFFFB020);
      case PermissionStatus.critical:
        return const Color(0xFFFF453A);
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case PermissionStatus.ok:
        return Icons.check_circle_rounded;
      case PermissionStatus.warning:
        return Icons.warning_amber_rounded;
      case PermissionStatus.critical:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status != PermissionStatus.ok
              ? _statusColor.withValues(alpha: 0.3)
              : const Color(0xFF2A2A2A),
          width: status != PermissionStatus.ok ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(_statusIcon, color: _statusColor, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF8A8A8A),
                height: 1.4,
              ),
            ),
            if (onFix != null && status != PermissionStatus.ok) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onFix!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build_rounded, color: _statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Fix issue',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
