import 'dart:math';

import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';

/// Deterministic July mock completions for debug-only consistency UI.
///
/// Delete with the dashboard mock panel after manual testing.
abstract final class ConsistencyMockJuly {
  ConsistencyMockJuly._();

  static const int defaultYear = 2025;
  static const int defaultSeed = 42;

  /// Builds completed goals for July [year] with mixed intensity tiers.
  ///
  /// Guarantees at least two calendar days with zero goals.
  static List<GoalSet> buildCompletedGoals({
    int year = defaultYear,
    int seed = defaultSeed,
  }) {
    final rng = Random(seed);
    final daysInJuly = ConsistencyDate.daysInMonth(year, 7);
    final zeroDays = <int>{};
    while (zeroDays.length < 2) {
      zeroDays.add(1 + rng.nextInt(daysInJuly));
    }

    final goals = <GoalSet>[];
    var nextId = 900000;
    for (var day = 1; day <= daysInJuly; day++) {
      if (zeroDays.contains(day)) continue;
      final count = _randomCountForTier(rng);
      for (var i = 0; i < count; i++) {
        nextId++;
        final completedAt = DateTime(year, 7, day, 9 + (i % 8), (i * 7) % 60);
        goals.add(
          GoalSet(
            title: 'Mock goal $day-$i',
            category: 'Mock',
            complexity: 'Easy',
            effort: 'Low',
            motivation: 'Debug',
            time: 15,
            completedAt: CompletionTimestamp.formatLabel(completedAt),
            steps: 1,
            points: 1,
            stepProgress: 1,
            goalId: nextId,
          ),
        );
      }
    }
    return goals;
  }

  /// Picks a count in one of the intensity bands (1-4, 5-9, 10-24, 25-50).
  static int _randomCountForTier(Random rng) {
    final tier = rng.nextInt(4);
    return switch (tier) {
      0 => 1 + rng.nextInt(4),
      1 => 5 + rng.nextInt(5),
      2 => 10 + rng.nextInt(15),
      _ => 25 + rng.nextInt(26),
    };
  }
}
