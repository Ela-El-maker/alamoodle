import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// ─── Shimmer Base ────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const Color _base = Color(0xFF1E1E1E);
  static const Color _highlight = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [_base, _highlight, _base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─── Next Alarm Card Skeleton ────────────────────────────────────────────────

class NextAlarmCardSkeleton extends StatelessWidget {
  const NextAlarmCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          _ShimmerBox(width: 20.w, height: 1.5.h, borderRadius: 6),
          SizedBox(height: 1.h),
          // Large time block
          _ShimmerBox(width: 55.w, height: 5.h, borderRadius: 10),
          SizedBox(height: 0.8.h),
          // Subtitle line 1
          _ShimmerBox(width: 40.w, height: 1.5.h, borderRadius: 6),
          SizedBox(height: 0.5.h),
          // Subtitle line 2
          _ShimmerBox(width: 30.w, height: 1.5.h, borderRadius: 6),
          SizedBox(height: 2.h),
          // Two button outlines
          Row(
            children: [
              Expanded(
                child: _ShimmerBox(
                  width: double.infinity,
                  height: 4.5.h,
                  borderRadius: 12,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _ShimmerBox(
                  width: double.infinity,
                  height: 4.5.h,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Alarm Card Skeleton ─────────────────────────────────────────────────────

class AlarmCardSkeleton extends StatelessWidget {
  const AlarmCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
      ),
      child: Row(
        children: [
          // Time block on left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 22.w, height: 2.5.h, borderRadius: 8),
              SizedBox(height: 0.6.h),
              _ShimmerBox(width: 16.w, height: 1.4.h, borderRadius: 6),
            ],
          ),
          SizedBox(width: 3.w),
          // Center label lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  width: double.infinity,
                  height: 1.5.h,
                  borderRadius: 6,
                ),
                SizedBox(height: 0.6.h),
                _ShimmerBox(width: 25.w, height: 1.2.h, borderRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          // Toggle outline on right
          _ShimmerBox(width: 12.w, height: 3.h, borderRadius: 14),
        ],
      ),
    );
  }
}
