import '../../../platform/guardian_platform_api.dart';
import '../domain/history_record.dart';
import '../domain/history_repository.dart';

class HistoryRepositoryPlatformImpl implements HistoryRepository {
  HistoryRepositoryPlatformImpl({GuardianPlatformApi? api})
    : _api = api ?? GuardianPlatformApi.instance;

  final GuardianPlatformApi _api;

  @override
  Future<List<HistoryRecord>> getRecent({int limit = 25, int? alarmId}) async {
    final dtos = await _api.getRecentHistory(limit: limit, alarmId: alarmId);
    return dtos
        .map(
          (dto) => HistoryRecord(
            historyId: dto.historyId,
            alarmId: dto.alarmId,
            triggerId: dto.triggerId,
            eventType: dto.eventType,
            occurredAtUtcMillis: dto.occurredAtUtcMillis,
            meta: dto.meta,
          ),
        )
        .toList();
  }
}
