import '../../../platform/guardian_platform_api.dart';
import '../../../platform/guardian_platform_models.dart';
import '../domain/stats_repository.dart';

class StatsRepositoryPlatformImpl implements StatsRepository {
  StatsRepositoryPlatformImpl({GuardianPlatformApi? api})
    : _api = api ?? GuardianPlatformApi.instance;

  final GuardianPlatformApi _api;

  @override
  Future<StatsSummaryModel> getSummary({String range = '30d'}) =>
      _api.getStatsSummary(range: range);

  @override
  Future<List<StatsTrendPointModel>> getTrends({String range = '30d'}) =>
      _api.getStatsTrends(range: range);
}
