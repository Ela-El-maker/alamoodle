import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/history/data/stats_repository_platform_impl.dart';
import '../../features/history/state/stats_controller.dart';
import '../../platform/guardian_platform_models.dart';

class StreakDetailsScreen extends StatefulWidget {
  const StreakDetailsScreen({super.key});

  @override
  State<StreakDetailsScreen> createState() => _StreakDetailsScreenState();
}

class _StreakDetailsScreenState extends State<StreakDetailsScreen> {
  final StatsController _controller = StatsController(
    StatsRepositoryPlatformImpl(),
  );

  bool _isLoading = true;
  String? _error;
  StatsSummaryModel _summary = const StatsSummaryModel(
    totalFired: 0,
    totalDismissed: 0,
    totalSnoozed: 0,
    totalMissed: 0,
    repairedCount: 0,
    dismissRate: 0,
    snoozeRate: 0,
    streakDays: 0,
  );
  List<StatsTrendPointModel> _trends = const <StatsTrendPointModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final summary = await _controller.getSummary(range: '30d');
      final trends = await _controller.getTrends(range: '30d');
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _trends = trends;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A1A)),
              )
            : _error != null
            ? _buildErrorState()
            : RefreshIndicator(
                color: const Color(0xFFFF7A1A),
                onRefresh: _load,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Daily streak status (last 30 days)'),
                    const SizedBox(height: 12),
                    ..._buildDailyRows(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load streak details',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: const Color(0xFFB8B8B8)),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Streaks',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Native-backed daily consistency',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFB8B8B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final activeDays = _trends.where((trend) => trend.fired > 0).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF7A1A).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _buildSummaryMetric('${_summary.streakDays}', 'Current streak'),
          _buildSummaryMetric('$activeDays', 'Active days (30d)'),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB8B8B8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  List<Widget> _buildDailyRows() {
    final byDayUtc = <int, StatsTrendPointModel>{
      for (final trend in _trends) trend.dayUtcStartMillis: trend,
    };
    final todayUtc = DateTime.now().toUtc();
    final todayStartUtc = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day,
    );

    final rows = <Widget>[];
    for (int i = 0; i < 30; i++) {
      final day = todayStartUtc.subtract(Duration(days: i));
      final dayKey = day.millisecondsSinceEpoch;
      final trend = byDayUtc[dayKey];
      final fired = trend?.fired ?? 0;
      final missed = trend?.missed ?? 0;
      final completed = fired > 0 && missed == 0;
      final statusColor = completed
          ? const Color(0xFF32D74B)
          : (missed > 0 ? const Color(0xFFFF453A) : const Color(0xFF7E7E7E));
      final statusText = completed
          ? 'Streak day'
          : (missed > 0 ? 'Missed' : 'No ring');

      rows.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDay(day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  String _formatDay(DateTime dayUtc) {
    final month = _monthName(dayUtc.month);
    return '${_weekdayName(dayUtc.weekday)}, ${dayUtc.day} $month';
  }

  String _monthName(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  String _weekdayName(int weekday) {
    const names = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }
}
