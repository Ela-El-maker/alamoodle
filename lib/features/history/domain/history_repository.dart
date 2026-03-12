import 'history_record.dart';

abstract class HistoryRepository {
  Future<List<HistoryRecord>> getRecent({int limit, int? alarmId});
}
