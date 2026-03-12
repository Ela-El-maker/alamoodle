import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/history/data/stats_repository_platform_impl.dart';
import '../../features/history/state/stats_controller.dart';
import '../../platform/guardian_platform_models.dart';
import '../../routes/app_routes.dart';
import './widgets/stat_metric_card_widget.dart';
import './widgets/streak_banner_widget.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final StatsController _controller = StatsController(
    StatsRepositoryPlatformImpl(),
  );

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String? _error;
  StatsSummaryModel? _summary;
  List<StatsTrendPointModel> _trends = const <StatsTrendPointModel>[];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _controller.getSummary(range: '30d');
      final trends = await _controller.getTrends(range: '7d');
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF7A1A)),
                )
              : _error != null
              ? _buildErrorState()
              : _buildStatsBody(),
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
              'Unable to load native stats',
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
            TextButton(onPressed: _loadStats, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBody() {
    final summary =
        _summary ??
        const StatsSummaryModel(
          totalFired: 0,
          totalDismissed: 0,
          totalSnoozed: 0,
          totalMissed: 0,
          repairedCount: 0,
          dismissRate: 0,
          snoozeRate: 0,
          streakDays: 0,
        );

    return RefreshIndicator(
      color: const Color(0xFFFF7A1A),
      onRefresh: _loadStats,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildHeader(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: StreakBannerWidget(
                streakDays: summary.streakDays,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRoutes.streakDetails);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSectionTitle('Native Stats (30d)'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final crossAxisCount = width < 440 ? 1 : 2;
                final mainAxisExtent = crossAxisCount == 1 ? 176.0 : 190.0;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: mainAxisExtent,
                  ),
                  delegate: SliverChildListDelegate([
                    StatMetricCardWidget(
                      value: '${summary.totalFired}',
                      label: 'Fired',
                      subtitle: 'Total ring events',
                      icon: Icons.notifications_active_rounded,
                      accentColor: const Color(0xFFFF7A1A),
                      trendData: _metricTrend((t) => t.fired),
                    ),
                    StatMetricCardWidget(
                      value: '${(summary.dismissRate * 100).round()}%',
                      label: 'Dismiss Rate',
                      subtitle: '${summary.totalDismissed} dismissed',
                      icon: Icons.check_circle_rounded,
                      accentColor: const Color(0xFF32D74B),
                      trendData: _ratioTrend(
                        (t) => t.dismissed,
                        (t) => t.fired,
                      ),
                    ),
                    StatMetricCardWidget(
                      value: '${(summary.snoozeRate * 100).round()}%',
                      label: 'Snooze Rate',
                      subtitle: '${summary.totalSnoozed} snoozed',
                      icon: Icons.snooze_rounded,
                      accentColor: const Color(0xFFFFB020),
                      trendData: _ratioTrend((t) => t.snoozed, (t) => t.fired),
                    ),
                    StatMetricCardWidget(
                      value: '${summary.totalMissed}',
                      label: 'Missed',
                      subtitle: '${summary.repairedCount} repaired',
                      icon: Icons.warning_rounded,
                      accentColor: const Color(0xFFFF453A),
                      trendData: _metricTrend((t) => t.missed),
                    ),
                  ]),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSectionTitle('Weekly Overview (Native)'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: _buildWeeklyOverview(),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _metricTrend(int Function(StatsTrendPointModel point) select) {
    if (_trends.isEmpty) return const [0, 0, 0, 0, 0, 0, 0];
    final values = _trends.map((trend) => select(trend).toDouble()).toList();
    while (values.length < 7) {
      values.insert(0, 0);
    }
    return values.takeLast(7);
  }

  List<double> _ratioTrend(
    int Function(StatsTrendPointModel point) numerator,
    int Function(StatsTrendPointModel point) denominator,
  ) {
    if (_trends.isEmpty) return const [0, 0, 0, 0, 0, 0, 0];
    final values = _trends.map((trend) {
      final base = denominator(trend);
      if (base <= 0) return 0.0;
      return (numerator(trend) / base) * 100.0;
    }).toList();
    while (values.length < 7) {
      values.insert(0, 0);
    }
    return values.takeLast(7);
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
                'Your Progress',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Computed from native history',
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

  Widget _buildWeeklyOverview() {
    final rows = _trends.takeLast(7);
    final labels = rows
        .map(
          (row) => DateTime.fromMillisecondsSinceEpoch(
            row.dayUtcStartMillis,
            isUtc: true,
          ),
        )
        .map((date) => _weekdayLetter(date.weekday))
        .toList();
    final maxTotal = rows
        .map((row) => (row.dismissed + row.snoozed + row.missed).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    final normalized = rows.map((row) {
      final total = (row.dismissed + row.snoozed + row.missed).toDouble();
      if (maxTotal <= 0 || total <= 0) return 0.15;
      return (total / maxTotal).clamp(0.15, 1.0);
    }).toList();

    final colors = rows.map((row) {
      if (row.missed > 0) return const Color(0xFFFF453A);
      if (row.snoozed > 0) return const Color(0xFFFFB020);
      return const Color(0xFF32D74B);
    }).toList();

    while (labels.length < 7) {
      labels.insert(0, '-');
      normalized.insert(0, 0.15);
      colors.insert(0, const Color(0xFF2A2A2A));
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dismiss / Snooze / Missed mix',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB8B8B8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 80 * normalized[i],
                    decoration: BoxDecoration(
                      color: colors[i].withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB8B8B8),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendDot(const Color(0xFF32D74B), 'Dismissed'),
              _buildLegendDot(const Color(0xFFFFB020), 'Snoozed'),
              _buildLegendDot(const Color(0xFFFF453A), 'Missed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
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

  String _weekdayLetter(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      default:
        return 'S';
    }
  }
}

extension _TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
