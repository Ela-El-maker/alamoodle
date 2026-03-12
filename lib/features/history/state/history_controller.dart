import '../domain/history_record.dart';
import '../domain/history_repository.dart';

class HistoryController {
  HistoryController(this._repository);

  final HistoryRepository _repository;

  Future<List<HistoryRecord>> getRecent({int limit = 25, int? alarmId}) {
    return _repository.getRecent(limit: limit, alarmId: alarmId);
  }
}
