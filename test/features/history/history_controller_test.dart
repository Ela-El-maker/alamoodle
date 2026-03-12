import 'package:alarmmaster/features/history/domain/history_record.dart';
import 'package:alarmmaster/features/history/domain/history_repository.dart';
import 'package:alarmmaster/features/history/state/history_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history controller returns native-backed records', () async {
    final controller = HistoryController(_FakeHistoryRepository());

    final records = await controller.getRecent(limit: 10);

    expect(records, isNotEmpty);
    expect(records.first.eventType, 'RESTORED_AFTER_BOOT');
  });
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryRecord>> getRecent({int limit = 25, int? alarmId}) async {
    return const [
      HistoryRecord(
        historyId: 1,
        alarmId: 99,
        triggerId: 'trg',
        eventType: 'RESTORED_AFTER_BOOT',
        occurredAtUtcMillis: 1,
        meta: 'reason=BOOT_COMPLETED',
      ),
    ];
  }
}
