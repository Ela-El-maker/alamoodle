import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/settings/data/sound_repository_platform_impl.dart';
import '../../features/settings/state/sound_controller.dart';
import '../../platform/guardian_platform_models.dart';
import '../../services/haptic_service.dart';
import './widgets/sound_extra_options_widget.dart';
import './widgets/sound_row_widget.dart';
import './widgets/sound_section_header_widget.dart';

class SoundPickerScreen extends StatefulWidget {
  const SoundPickerScreen({super.key, this.selectedSoundId});

  final String? selectedSoundId;

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen>
    with SingleTickerProviderStateMixin {
  final SoundController _controller = SoundController(
    SoundRepositoryPlatformImpl(),
  );

  List<SoundProfileModel> _sounds = const <SoundProfileModel>[];
  String? _selectedSoundId;
  String? _playingSoundId;
  String? _error;
  bool _isLoading = true;
  bool _escalatingVolume = false;
  bool _vibrationOnRing = true;
  double _escalationStartVolume = 0.7;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedSoundId = widget.selectedSoundId;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadCatalog();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller.stopSoundPreview();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sounds = await _controller.getSoundCatalog();
      if (!mounted) return;
      final fallbackId = sounds.isNotEmpty ? sounds.first.id : null;
      setState(() {
        _sounds = sounds;
        _selectedSoundId ??= fallbackId;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlay(String soundId) async {
    if (_playingSoundId == soundId) {
      await _stopPlayback();
      return;
    }

    HapticService.soundPreviewPlay();
    final ok = await _controller.previewSound(soundId);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start preview on this device')),
      );
      return;
    }

    setState(() {
      _playingSoundId = soundId;
      _pulseController.repeat(reverse: true);
    });
  }

  Future<void> _stopPlayback() async {
    HapticService.soundPreviewStop();
    await _controller.stopSoundPreview();
    if (!mounted) return;
    setState(() {
      _playingSoundId = null;
      _pulseController.stop();
    });
  }

  void _selectSound(String soundId) {
    HapticService.soundSelected();
    setState(() {
      _selectedSoundId = soundId;
      if (_playingSoundId != soundId) {
        _playingSoundId = null;
      }
    });
  }

  List<SoundProfileModel> _getSoundsByCategory(String category) {
    return _sounds.where((s) => s.category == category).toList();
  }

  String _labelForCategory(String category) {
    switch (category) {
      case 'recommended':
        return 'RECOMMENDED';
      case 'gentle':
        return 'GENTLE';
      case 'classic':
        return 'CLASSIC';
      case 'loud':
        return 'LOUD';
      default:
        return 'OTHER';
    }
  }

  Widget _buildSoundSection(String category) {
    final sounds = _getSoundsByCategory(category);
    if (sounds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoundSectionHeaderWidget(title: _labelForCategory(category)),
        ...sounds.map(
          (sound) => SoundRowWidget(
            name: sound.name,
            tag: sound.tag,
            duration: null,
            isSelected: _selectedSoundId == sound.id,
            isPlaying: _playingSoundId == sound.id,
            onTap: () => _selectSound(sound.id),
            onPlayToggle: () => _togglePlay(sound.id),
          ),
        ),
      ],
    );
  }

  Widget _buildNowPlayingBanner() {
    if (_playingSoundId == null) return const SizedBox.shrink();
    final playing = _sounds.firstWhere(
      (s) => s.id == _playingSoundId,
      orElse: () => const SoundProfileModel(
        id: '',
        name: '',
        tag: '',
        category: '',
        vibrationProfileIds: <String>[],
      ),
    );
    if (playing.id.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A1A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF7A1A).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.graphic_eq_rounded,
              color: Color(0xFFFF7A1A),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Now previewing: ${playing.name}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF7A1A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _stopPlayback,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A1A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF7A1A).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stop_rounded,
                      color: Color(0xFFFF7A1A),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stop',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF7A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationStartVolumeSlider() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFFB8B8B8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Escalation Start Volume',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB8B8B8),
                  ),
                ),
              ),
              Text(
                '${(_escalationStartVolume * 100).round()}%',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF7A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.volume_mute_rounded,
                color: Color(0xFF4A4A4A),
                size: 16,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    activeTrackColor: const Color(0xFFFF7A1A),
                    inactiveTrackColor: const Color(0xFF2A2A2A),
                    thumbColor: const Color(0xFFFF7A1A),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayColor: const Color(
                      0xFFFF7A1A,
                    ).withValues(alpha: 0.2),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: _escalationStartVolume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _escalationStartVolume = v);
                    },
                  ),
                ),
              ),
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF4A4A4A),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _selectionResult() {
    final selectedId = _selectedSoundId;
    final selected = _sounds.firstWhere(
      (sound) => sound.id == selectedId,
      orElse: () => const SoundProfileModel(
        id: 'default_alarm',
        name: 'Default Alarm',
        tag: 'Classic',
        category: 'recommended',
        vibrationProfileIds: <String>['default'],
      ),
    );

    final String vibrationProfileId;
    if (!_vibrationOnRing) {
      vibrationProfileId = 'off';
    } else {
      vibrationProfileId = selected.vibrationProfileIds.isNotEmpty
          ? selected.vibrationProfileIds.first
          : 'default';
    }

    return <String, dynamic>{
      'soundId': selected.id,
      'soundName': selected.name,
      'vibrationProfileId': vibrationProfileId,
      'escalationPolicy': _escalatingVolume
          ? '{"enabled":true,"mode":"ramp","startVolume":${_escalationStartVolume.toStringAsFixed(2)},"endVolume":1.0,"stepSeconds":20,"maxSteps":3}'
          : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, _selectionResult());
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFFFFFFF),
              size: 18,
            ),
          ),
        ),
        title: Text(
          'Choose Sound',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, _selectionResult());
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7A1A)),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load native sound catalog.\n$_error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: const Color(0xFFB8B8B8)),
                ),
              ),
            )
          : Column(
              children: [
                _buildNowPlayingBanner(),
                _buildEscalationStartVolumeSlider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      _buildSoundSection('recommended'),
                      _buildSoundSection('gentle'),
                      _buildSoundSection('classic'),
                      _buildSoundSection('loud'),
                      SoundExtraOptionsWidget(
                        escalatingVolume: _escalatingVolume,
                        vibrationOnRing: _vibrationOnRing,
                        onEscalatingVolumeChanged: (v) =>
                            setState(() => _escalatingVolume = v),
                        onVibrationChanged: (v) =>
                            setState(() => _vibrationOnRing = v),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
