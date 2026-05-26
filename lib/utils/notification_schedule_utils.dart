import 'package:timezone/timezone.dart' as tz;

/// Parsing and planning helpers for local notification schedules.
abstract final class NotificationScheduleUtils {
  NotificationScheduleUtils._();

  static const String defaultAffirmationTime = '06:00';
  static const int affirmationHorizonDays = 90;
  static const int affirmationTopUpLeadDays = 14;

  /// Normalizes user-entered clock strings to `HH:mm` (24h).
  static String normalizeHHmm(String? raw, {String fallback = defaultAffirmationTime}) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return fallback;

    final parsed = parseClock(trimmed);
    if (parsed == null) return fallback;

    final hour = parsed.$1.toString().padLeft(2, '0');
    final minute = parsed.$2.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Parses `HH:mm`, `H:mm`, optional `am/pm`.
  static (int hour, int minute)? parseClock(String input) {
    var value = input.trim().toLowerCase().replaceAll('.', '');
    if (value.isEmpty) return null;

    var isPm = false;
    var isAm = false;
    if (value.endsWith('pm')) {
      isPm = true;
      value = value.substring(0, value.length - 2).trim();
    } else if (value.endsWith('am')) {
      isAm = true;
      value = value.substring(0, value.length - 2).trim();
    }

    final parts = value.split(':');
    if (parts.length != 2) return null;

    var hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return null;
    if (minute < 0 || minute > 59) return null;

    if (isPm || isAm) {
      if (hour < 1 || hour > 12) return null;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
    } else if (hour < 0 || hour > 23) {
      return null;
    }

    return (hour, minute);
  }

  /// Next occurrence of [hhmm] in [location] (today if still ahead, else tomorrow).
  static tz.TZDateTime? nextTriggerFromHHmm(
    String hhmm, {
    tz.Location? location,
  }) {
    final loc = location ?? tz.local;
    final clock = parseClock(normalizeHHmm(hhmm));
    if (clock == null) return null;

    final now = tz.TZDateTime.now(loc);
    var candidate = tz.TZDateTime(
      loc,
      now.year,
      now.month,
      now.day,
      clock.$1,
      clock.$2,
    );

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Builds [days] consecutive triggers starting at [firstTrigger].
  static List<tz.TZDateTime> dailyTriggersFrom({
    required tz.TZDateTime firstTrigger,
    required int days,
  }) {
    if (days <= 0) return const [];
    return List.generate(
      days,
      (i) => firstTrigger.add(Duration(days: i)),
    );
  }

  static String formatDateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime? parseDateKey(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// True when affirmations should be re-planned (missing or running out soon).
  static bool shouldRefreshAffirmationSchedule({
    required DateTime? scheduledUntil,
    required DateTime now,
    int leadDays = affirmationTopUpLeadDays,
  }) {
    if (scheduledUntil == null) return true;
    final threshold = DateTime(now.year, now.month, now.day)
        .add(Duration(days: leadDays));
    return !scheduledUntil.isAfter(threshold);
  }
}
