import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChallengeWidget extends StatefulWidget {
  final VoidCallback onSolved;
  final VoidCallback onCancel;

  const ChallengeWidget({
    super.key,
    required this.onSolved,
    required this.onCancel,
  });

  @override
  State<ChallengeWidget> createState() => _ChallengeWidgetState();
}

class _ChallengeWidgetState extends State<ChallengeWidget> {
  late int _num1;
  late int _num2;
  late String _operator;
  late int _correctAnswer;
  String _userInput = '';
  bool _isError = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  void _generateChallenge() {
    final random = Random();
    _num1 = random.nextInt(30) + 10;
    _num2 = random.nextInt(20) + 5;
    final ops = ['+', '-', 'x'];
    _operator = ops[random.nextInt(ops.length)];
    switch (_operator) {
      case '+':
        _correctAnswer = _num1 + _num2;
        break;
      case '-':
        _correctAnswer = _num1 - _num2;
        break;
      case 'x':
        _num1 = random.nextInt(12) + 2;
        _num2 = random.nextInt(12) + 2;
        _correctAnswer = _num1 * _num2;
        break;
      default:
        _correctAnswer = _num1 + _num2;
    }
  }

  void _onKeyTap(String value) {
    HapticFeedback.selectionClick();
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
    final answer = int.tryParse(_userInput);
    if (answer == _correctAnswer) {
      HapticFeedback.heavyImpact();
      widget.onSolved();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _isError = true;
        _userInput = '';
      });
      _generateChallenge();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onCancel,
                child: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.inactiveText,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'Solve to Dismiss',
                style: TextStyle(
                  fontSize: 4.5.w,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.subtleBorder),
            ),
            child: Text(
              '$_num1 $_operator $_num2 = ?',
              style: TextStyle(
                fontSize: 12.w,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryText,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isError ? AppTheme.warningRed : AppTheme.subtleBorder,
                width: _isError ? 2 : 1,
              ),
            ),
            child: Text(
              _userInput.isEmpty
                  ? (_isError ? 'Try again!' : '_ _ _')
                  : _userInput,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.w,
                fontWeight: FontWeight.w800,
                color: _isError ? AppTheme.warningRed : AppTheme.primaryText,
                letterSpacing: 4,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          _buildNumpad(),
        ],
      ),
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
                      height: 7.h,
                      decoration: BoxDecoration(
                        color: isOk
                            ? AppTheme.accentOrange
                            : isDel
                            ? AppTheme.secondaryBackground
                            : AppTheme.secondaryBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOk
                              ? AppTheme.accentOrange
                              : AppTheme.subtleBorder,
                        ),
                      ),
                      child: Center(
                        child: isDel
                            ? CustomIconWidget(
                                iconName: 'backspace',
                                color: AppTheme.inactiveText,
                                size: 5.w,
                              )
                            : Text(
                                key,
                                style: TextStyle(
                                  fontSize: 5.w,
                                  fontWeight: FontWeight.w700,
                                  color: isOk
                                      ? AppTheme.primaryText
                                      : AppTheme.primaryText,
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
