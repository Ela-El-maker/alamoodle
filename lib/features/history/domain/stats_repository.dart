import '../../../platform/guardian_platform_models.dart';

abstract class StatsRepository {
  Future<StatsSummaryModel> getSummary({String range});
  Future<List<StatsTrendPointModel>> getTrends({String range});
}
