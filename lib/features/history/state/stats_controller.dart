import '../../../platform/guardian_platform_models.dart';
import '../domain/stats_repository.dart';

class StatsController {
  StatsController(this._repository);

  final StatsRepository _repository;

  Future<StatsSummaryModel> getSummary({String range = '30d'}) =>
      _repository.getSummary(range: range);

  Future<List<StatsTrendPointModel>> getTrends({String range = '30d'}) =>
      _repository.getTrends(range: range);
}
