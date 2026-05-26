import 'package:focusNexus/models/completed_today_record.dart';

export 'package:focusNexus/models/completed_today_record.dart';

/// Parses `"dd MM yyyy|count"` completion streak storage.
class CompletedTodayCodec {
  CompletedTodayCodec._();

  static int nextCount({required String? stored, required String today}) {
    return CompletedTodayRecord.fromStorage(stored).nextForDay(today).count;
  }

  static String encode({required String today, required int count}) {
    return CompletedTodayRecord(dateKey: today, count: count).toStorage();
  }
}
