import 'package:intl/intl.dart';

/// Week/month streak helpers used by [AchievementStreakService].
class StreakLogic {
  StreakLogic._();

  static String getWeekIdentifier(DateTime date) {
    final int weekday = date.weekday;
    final DateTime startOfWeek = date.subtract(Duration(days: weekday - 1));
    return DateFormat('yyyy-MM-dd').format(startOfWeek);
  }

  static bool isPreviousWeek(String storedWeek, String currentWeek) {
    if (storedWeek.isEmpty || currentWeek.isEmpty) return false;

    try {
      final DateTime current = DateFormat('yyyy-MM-dd').parse(currentWeek);
      final DateTime previousWeekStart = current.subtract(const Duration(days: 7));
      final String previousWeek = getWeekIdentifier(previousWeekStart);
      return storedWeek == previousWeek;
    } catch (_) {
      return false;
    }
  }

  static String monthIdentifier(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
}
