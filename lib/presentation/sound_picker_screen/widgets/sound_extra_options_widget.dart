import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SoundExtraOptionsWidget extends StatefulWidget {
  final bool escalatingVolume;
  final bool vibrationOnRing;
  final ValueChanged<bool> onEscalatingVolumeChanged;
  final ValueChanged<bool> onVibrationChanged;

  const SoundExtraOptionsWidget({
    super.key,
    required this.escalatingVolume,
    required this.vibrationOnRing,
    required this.onEscalatingVolumeChanged,
    required this.onVibrationChanged,
  });

  @override
  State<SoundExtraOptionsWidget> createState() =>
      _SoundExtraOptionsWidgetState();
}

class _SoundExtraOptionsWidgetState extends State<SoundExtraOptionsWidget> {
  Widget _buildOptionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFB8B8B8), size: 18),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF6A6A6A),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
            activeThumbColor: const Color(0xFFFF7A1A),
            activeTrackColor: const Color(0xFFFF7A1A).withValues(alpha: 0.3),
            inactiveThumbColor: const Color(0xFF4A4A4A),
            inactiveTrackColor: const Color(0xFF2A2A2A),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            'PLAYBACK OPTIONS',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6A6A6A),
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildOptionRow(
          icon: Icons.trending_up_rounded,
          title: 'Escalating Volume',
          subtitle: 'Gradually increases from soft to loud',
          value: widget.escalatingVolume,
          onChanged: widget.onEscalatingVolumeChanged,
        ),
        _buildOptionRow(
          icon: Icons.vibration_rounded,
          title: 'Vibration on Ring',
          subtitle: 'Vibrate alongside the alarm sound',
          value: widget.vibrationOnRing,
          onChanged: widget.onVibrationChanged,
        ),
      ],
    );
  }
}
