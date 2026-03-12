import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/haptic_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class MathChallengeWidget extends StatefulWidget {
  final VoidCallback onSolved;

  const MathChallengeWidget({super.key, required this.onSolved});

  @override
  State<MathChallengeWidget> createState() => _MathChallengeWidgetState();
}

class _MathChallengeWidgetState extends State<MathChallengeWidget>
    with SingleTickerProviderStateMixin {
  late int _num1;
  late int _num2;
  late String _operator;
  late int _correctAnswer;
  String _userInput = '';
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _generateChallenge();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _generateChallenge() {
    final random = Random();
    _num1 = random.nextInt(30) + 10;
    _num2 = random.nextInt(20) + 5;
    final ops = ['+', '-'];
    _operator = ops[random.nextInt(ops.length)];
    switch (_operator) {
      case '+':
        _correctAnswer = _num1 + _num2;
        break;
      case '-':
        if (_num1 < _num2) {
          final tmp = _num1;
          _num1 = _num2;
          _num2 = tmp;
        }
        _correctAnswer = _num1 - _num2;
        break;
      default:
        _correctAnswer = _num1 + _num2;
    }
  }

  void _onKeyTap(String value) {
    HapticService.challengeKeyTap();
    setState(() {
      _isError = false;
      if (value == 'DEL') {
        if (_userInput.isNotEmpty) {
          _userInput = _userInput.substring(0, _userInput.length - 1);
        }
      } else if (_userInput.length < 5) {
        _userInput += value;
      }
    });
  }

  void _checkAnswer() {
    HapticService.buttonMedium();
    final answer = int.tryParse(_userInput);
    if (answer == _correctAnswer) {
      HapticService.challengeCorrect();
      widget.onSolved();
    } else {
      HapticService.challengeWrong();
      setState(() {
        _isError = true;
        _userInput = '';
      });
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _isError = false);
          _generateChallenge();
        }
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Solve to dismiss',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB8B8B8),
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFF2D2D2D)),
          ),
          child: Text(
            '$_num1 $_operator $_num2 = ?',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 2.5.h),
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = _isError
                ? ((_shakeAnimation.value * 4).round() % 2 == 0 ? -8.0 : 8.0)
                : 0.0;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: _isError
                  ? const Color(0xFF2A0000)
                  : const Color(0xFF151515),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: _isError
                    ? const Color(0xFFFF453A)
                    : const Color(0xFF2D2D2D),
                width: _isError ? 2 : 1,
              ),
            ),
            child: Text(
              _userInput.isEmpty
                  ? (_isError ? 'Wrong! Try again' : '_ _ _')
                  : _userInput,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: _isError ? const Color(0xFFFF453A) : Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        _buildNumpad(),
      ],
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['DEL', '0', 'OK'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 1.5.h),
          child: Row(
            children: row.map((key) {
              final isOk = key == 'OK';
              final isDel = key == 'DEL';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                  child: GestureDetector(
                    onTap: () => isOk ? _checkAnswer() : _onKeyTap(key),
                    child: Container(
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: isOk
                            ? const Color(0xFFFF7A1A)
                            : const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isOk
                              ? const Color(0xFFFF7A1A)
                              : const Color(0xFF2D2D2D),
                        ),
                      ),
                      child: Center(
                        child: isDel
                            ? CustomIconWidget(
                                iconName: 'backspace',
                                color: const Color(0xFFB8B8B8),
                                size: 6.w,
                              )
                            : Text(
                                key,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
