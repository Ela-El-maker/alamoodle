class HistoryRecord {
  const HistoryRecord({
    required this.historyId,
    required this.alarmId,
    required this.triggerId,
    required this.eventType,
    required this.occurredAtUtcMillis,
    required this.meta,
  });

  final int historyId;
  final int alarmId;
  final String triggerId;
  final String eventType;
  final int occurredAtUtcMillis;
  final String meta;
}
