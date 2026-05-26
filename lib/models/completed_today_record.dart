import 'package:freezed_annotation/freezed_annotation.dart';

part 'completed_today_record.freezed.dart';

/// Daily completion counter stored as `"date|count"`.
@freezed
class CompletedTodayRecord with _$CompletedTodayRecord {
  const CompletedTodayRecord._();

  const factory CompletedTodayRecord({
    required String dateKey,
    @Default(1) int count,
  }) = _CompletedTodayRecord;

  factory CompletedTodayRecord.initial(String today) =>
      CompletedTodayRecord(dateKey: today, count: 1);

  factory CompletedTodayRecord.fromStorage(String? stored) {
    if (stored == null || stored.isEmpty) {
      return const CompletedTodayRecord(dateKey: '', count: 0);
    }
    final parts = stored.split('|');
    if (parts.isEmpty) {
      return const CompletedTodayRecord(dateKey: '', count: 0);
    }
    final dateKey = parts.first;
    final count = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return CompletedTodayRecord(dateKey: dateKey, count: count);
  }

  String toStorage() => '$dateKey|$count';

  /// Next count after completing a goal on [today].
  CompletedTodayRecord nextForDay(String today) {
    if (dateKey.isEmpty || dateKey != today) {
      return CompletedTodayRecord.initial(today);
    }
    return copyWith(count: count + 1);
  }
}
