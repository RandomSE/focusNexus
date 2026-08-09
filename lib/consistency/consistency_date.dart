/// Local calendar-date helpers for consistency aggregation (no time-of-day).
abstract final class ConsistencyDate {
  ConsistencyDate._();

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime monthStart(int year, int month) => DateTime(year, month, 1);

  /// First day of the month after [year]/[month].
  static DateTime nextMonthStart(int year, int month) {
    if (month == 12) return DateTime(year + 1, 1, 1);
    return DateTime(year, month + 1, 1);
  }

  static DateTime previousMonthStart(int year, int month) {
    if (month == 1) return DateTime(year - 1, 12, 1);
    return DateTime(year, month - 1, 1);
  }

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Monday=0 .. Sunday=6 for grid column alignment.
  static int mondayBasedWeekdayIndex(DateTime day) =>
      (day.weekday - DateTime.monday + 7) % 7;
}
