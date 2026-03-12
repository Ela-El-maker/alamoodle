import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SoundRowWidget extends StatelessWidget {
  final String name;
  final String tag;
  final String? duration;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayToggle;

  const SoundRowWidget({
    super.key,
    required this.name,
    required this.tag,
    this.duration,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGentle = tag == 'Gentle';
    final Color tagColor = isGentle
        ? const Color(0xFF32D74B)
        : const Color(0xFFFFB020);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1200) : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A1A)
                : const Color(0xFF2A2A2A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Play/Stop button — separate from row selection
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onPlayToggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? const Color(0xFFFF7A1A).withValues(alpha: 0.2)
                      : const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                  border: isPlaying
                      ? Border.all(
                          color: const Color(0xFFFF7A1A).withValues(alpha: 0.5),
                          width: 1.5,
                        )
                      : null,
                ),
                child: isPlaying
                    ? const _PlayingBarsIcon()
                    : const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFFB8B8B8),
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFE0E0E0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tagColor,
                          ),
                        ),
                      ),
                      if (duration != null)
                        Text(
                          duration!,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF6A6A6A),
                          ),
                        ),
                      if (isPlaying)
                        Text(
                          'Playing',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF7A1A),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              )
            else
              const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

/// Animated equalizer bars shown when a sound is playing
class _PlayingBarsIcon extends StatefulWidget {
  const _PlayingBarsIcon();

  @override
  State<_PlayingBarsIcon> createState() => _PlayingBarsIconState();
}

class _PlayingBarsIconState extends State<_PlayingBarsIcon>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 120),
      )..repeat(reverse: true);
    });
    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 4,
        end: 14,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) {
              return Container(
                width: 3,
                height: _animations[i].value,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A1A),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
