import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class EmptyAlarmWidget extends StatefulWidget {
  final VoidCallback onAddAlarm;

  const EmptyAlarmWidget({super.key, required this.onAddAlarm});

  @override
  State<EmptyAlarmWidget> createState() => _EmptyAlarmWidgetState();
}

class _EmptyAlarmWidgetState extends State<EmptyAlarmWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnim.value),
            child: child,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 300;
          final iconExtent = (constraints.maxWidth * 0.26).clamp(68.0, 104.0);
          final buttonWidth = (constraints.maxWidth * 0.72).clamp(180.0, 280.0);
          final titleSize = compactHeight ? 22.0 : 26.0;
          final bodySize = compactHeight ? 13.0 : 14.0;
          final topGap = compactHeight ? 12.0 : 20.0;
          final midGap = compactHeight ? 6.0 : 10.0;
          final buttonGap = compactHeight ? 14.0 : 24.0;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing alarm icon
                      Container(
                        width: iconExtent.toDouble(),
                        height: iconExtent.toDouble(),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentOrange.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                          border: Border.all(
                            color: AppTheme.accentOrange.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'alarm',
                            color: AppTheme.accentOrange,
                            size: compactHeight ? 36 : 44,
                          ),
                        ),
                      ),
                      SizedBox(height: topGap),
                      Text(
                        'No alarms yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: titleSize,
                        ),
                      ),
                      SizedBox(height: midGap),
                      Text(
                        'Tap + to set your first alarm and\nnever oversleep again',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.inactiveText,
                          height: 1.45,
                          fontSize: bodySize,
                        ),
                      ),
                      SizedBox(height: buttonGap),
                      SizedBox(
                        width: buttonWidth.toDouble(),
                        height: compactHeight ? 44 : 50,
                        child: ElevatedButton(
                          onPressed: widget.onAddAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: AppTheme.primaryText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'add',
                                color: AppTheme.primaryText,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '+ Set First Alarm',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
