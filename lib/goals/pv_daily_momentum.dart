import 'package:focusNexus/models/completed_today_record.dart';

/// Progressive-visuals momentum bonus, layered alongside the wallet's Option 1
/// daily-completion tiers (see `goal_points.dart`). Does not change the
/// wallet formula; only qualifying goal completions count toward the streak.
abstract final class PvDailyMomentum {
  /// Minimum pre-daily-multiplier goal points required to count today.
  static const int qualifyingPointsThreshold = 50;

  /// Qualifying-completions-today counts that each trigger a PV grant.
  static const List<int> grantThresholds = [10, 20, 30];

  static const int grantPerThreshold = 1000;

  /// Sum of all thresholds' grants (10 + 20 + 30 hits => 3000/day max).
  static const int maxDailyGrant = 3000;

  /// Whether a goal's pre-daily-multiplier points count toward momentum.
  static bool qualifies(int preDailyPoints) =>
      preDailyPoints >= qualifyingPointsThreshold;

  /// PV to grant now that today's qualifying-completion count is
  /// [qualifyingCountToday]. Zero unless the count lands exactly on a
  /// threshold (each threshold grants once per day).
  static int grantForQualifyingCount(int qualifyingCountToday) {
    return grantThresholds.contains(qualifyingCountToday)
        ? grantPerThreshold
        : 0;
  }

  /// Next qualifying-count-today record after a qualifying completion on
  /// [today]. Resets to 1 when the stored record is from a different day.
  static CompletedTodayRecord nextQualifyingCount({
    required String? stored,
    required String today,
  }) {
    return CompletedTodayRecord.fromStorage(stored).nextForDay(today);
  }
}
