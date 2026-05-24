/// Parses `"dd MM yyyy|count"` completion streak storage.
class CompletedTodayCodec {
  CompletedTodayCodec._();

  static int nextCount({required String? stored, required String today}) {
    if (stored == null || stored.isEmpty) return 1;

    final parts = stored.split('|');
    if (parts.isEmpty) return 1;

    final storedDate = parts.first;
    final storedCount = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    if (storedDate == today) return storedCount + 1;
    return 1;
  }

  static String encode({required String today, required int count}) {
    return '$today|$count';
  }
}
