import 'package:alarmmaster/features/history/domain/stats_repository.dart';
import 'package:alarmmaster/features/history/state/stats_controller.dart';
import 'package:alarmmaster/platform/guardian_platform_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stats controller returns native summary and trends', () async {
    final controller = StatsController(_FakeStatsRepository());

    final summary = await controller.getSummary(range: '30d');
    final trends = await controller.getTrends(range: '7d');

    expect(summary.totalFired, 12);
    expect(summary.repairedCount, 2);
    expect(trends, hasLength(2));
    expect(trends.first.fired, 4);
  });
}

class _FakeStatsRepository implements StatsRepository {
  @override
  Future<StatsSummaryModel> getSummary({String range = '30d'}) async {
    return const StatsSummaryModel(
      totalFired: 12,
      totalDismissed: 9,
      totalSnoozed: 2,
      totalMissed: 1,
      repairedCount: 2,
      dismissRate: 0.75,
      snoozeRate: 0.166,
      streakDays: 3,
    );
  }

  @override
  Future<List<StatsTrendPointModel>> getTrends({String range = '30d'}) async {
    return const [
      StatsTrendPointModel(
        dayUtcStartMillis: 1,
        fired: 4,
        dismissed: 3,
        snoozed: 1,
        missed: 0,
        repaired: 1,
      ),
      StatsTrendPointModel(
        dayUtcStartMillis: 2,
        fired: 8,
        dismissed: 6,
        snoozed: 1,
        missed: 1,
        repaired: 1,
      ),
    ];
  }
}
