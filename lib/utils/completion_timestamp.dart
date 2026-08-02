import 'package:intl/intl.dart';

/// Shared minute-precision completion timestamps (goals + achievements).
abstract final class CompletionTimestamp {
  static const pattern = 'dd MMMM yyyy HH:mm';

  static final DateFormat format = DateFormat(pattern);

  /// Wall-clock truncated to the minute (no seconds / fractional seconds).
  static DateTime atMinute([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour, n.minute);
  }

  static String formatLabel(DateTime dt) => format.format(atMinute(dt));

  /// Parses goal-style labels or legacy ISO-8601 values.
  static DateTime? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return atMinute(format.parse(raw));
    } catch (_) {
      final iso = DateTime.tryParse(raw);
      return iso == null ? null : atMinute(iso);
    }
  }
}
