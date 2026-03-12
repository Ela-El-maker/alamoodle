import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class MemoryChallengeWidget extends StatefulWidget {
  final VoidCallback onSolved;

  const MemoryChallengeWidget({super.key, required this.onSolved});

  @override
  State<MemoryChallengeWidget> createState() => _MemoryChallengeWidgetState();
}

class _MemoryChallengeWidgetState extends State<MemoryChallengeWidget> {
  static const int _gridSize = 4;
  late List<int> _sequence;
  late List<int> _userSequence;
  int _showingIndex = -1;
  bool _isShowingSequence = false;
  bool _isUserTurn = false;
  bool _isComplete = false;
  bool _isError = false;
  int _round = 1;

  final List<Color> _tileColors = [
    const Color(0xFFFF7A1A),
    const Color(0xFF32D74B),
    const Color(0xFF0A84FF),
    const Color(0xFFFFB020),
  ];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _sequence = [];
    _userSequence = [];
    _isComplete = false;
    _isError = false;
    _addToSequence();
  }

  void _addToSequence() {
    _sequence.add(Random().nextInt(_gridSize));
    _userSequence = [];
    _showSequence();
  }

  Future<void> _showSequence() async {
    setState(() {
      _isShowingSequence = true;
      _isUserTurn = false;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    for (int i = 0; i < _sequence.length; i++) {
      setState(() => _showingIndex = _sequence[i]);
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _showingIndex = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    setState(() {
      _isShowingSequence = false;
      _isUserTurn = true;
    });
  }

  void _onTileTap(int index) {
    if (!_isUserTurn || _isShowingSequence) return;
    HapticFeedback.selectionClick();
    _userSequence.add(index);

    final pos = _userSequence.length - 1;
    if (_userSequence[pos] != _sequence[pos]) {
      // Wrong
      HapticFeedback.vibrate();
      setState(() => _isError = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _isError = false);
          _startGame();
        }
      });
      return;
    }

    if (_userSequence.length == _sequence.length) {
      if (_round >= 3) {
        // Complete after 3 rounds
        HapticFeedback.heavyImpact();
        setState(() => _isComplete = true);
        Future.delayed(const Duration(milliseconds: 800), widget.onSolved);
      } else {
        _round++;
        Future.delayed(const Duration(milliseconds: 400), _addToSequence);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _isComplete
              ? 'Well done! Dismissing...'
              : _isError
              ? 'Wrong! Starting over...'
              : _isShowingSequence
              ? 'Watch the sequence'
              : 'Repeat the sequence',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: _isComplete
                ? const Color(0xFF32D74B)
                : _isError
                ? const Color(0xFFFF453A)
                : const Color(0xFFB8B8B8),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Round $_round / 3',
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF666666)),
        ),
        SizedBox(height: 3.h),
        Expanded(
          child: Center(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _gridSize,
              itemBuilder: (context, index) {
                final isHighlighted = _showingIndex == index;
                final baseColor = _tileColors[index];
                return GestureDetector(
                  onTap: () => _onTileTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? baseColor
                          : baseColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: isHighlighted
                            ? baseColor
                            : baseColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: baseColor.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 2.h),
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _sequence.length,
            (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _userSequence.length
                    ? const Color(0xFF32D74B)
                    : const Color(0xFF2D2D2D),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
