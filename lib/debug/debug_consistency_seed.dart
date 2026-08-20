import 'dart:math';

import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';

/// Debug-only completed-goal seed for the consistency calendar.
abstract final class DebugConsistencySeed {
  DebugConsistencySeed._();

  static const int minFilledCount = 1;
  static const int maxFilledCount = 50;

  static const List<String> _titles = [
    'Walk around the block',
    'Inbox to zero',
    'Drink a glass of water',
    'Read ten pages',
    'Stretch for five minutes',
    'Reply to one message',
    'Tidy the desk',
    'Take medication',
    'Write a short journal note',
    'Prep tomorrow bag',
    'Do a two-minute tidy',
    'Practice a skill',
    'Call a friend',
    'Cook a simple meal',
    'Review today priorities',
    'Sit outside briefly',
    'Sort one folder',
    'Do a breathing pause',
    'Plan the next task',
    'Put laundry away',
  ];

  static const List<String> _levels = ['Low', 'Medium', 'High'];
  static const List<int> _minutes = [5, 10, 15, 20, 30, 45, 60];

  /// One count per local day in [year]/[month]. Exactly one day is 0.
  static Map<DateTime, int> planDayCounts({
    required int year,
    required int month,
    required Random random,
  }) {
    final days = ConsistencyDate.daysInMonth(year, month);
    final zeroDay = random.nextInt(days) + 1;
    final out = <DateTime, int>{};
    for (var day = 1; day <= days; day++) {
      out[DateTime(year, month, day)] = day == zeroDay
          ? 0
          : random.nextInt(maxFilledCount) + minFilledCount;
    }
    return out;
  }

  /// Real [GoalSet] rows for [dayCounts]. Days with 0 are skipped.
  static List<GoalSet> buildGoals({
    required Map<DateTime, int> dayCounts,
    required Random random,
  }) {
    final goals = <GoalSet>[];
    final days = dayCounts.keys.toList()..sort();
    for (final day in days) {
      final count = dayCounts[day] ?? 0;
      for (var i = 0; i < count; i++) {
        final title = _titles[random.nextInt(_titles.length)];
        final hour = 8 + (i % 12);
        final minute = (i * 3) % 60;
        final completedAt = DateTime(day.year, day.month, day.day, hour, minute);
        goals.add(
          GoalSet(
            title: title,
            category: kGoalCategories[random.nextInt(kGoalCategories.length)],
            complexity: _levels[random.nextInt(_levels.length)],
            effort: _levels[random.nextInt(_levels.length)],
            motivation: _levels[random.nextInt(_levels.length)],
            time: _minutes[random.nextInt(_minutes.length)],
            deadline: 'no deadline',
            completedAt: CompletionTimestamp.formatLabel(completedAt),
            steps: 1,
            points: 0,
            stepProgress: 1,
            goalId: _idFor(day.year, day.month, day.day, i),
            goalKind: GoalKind.deadline,
          ),
        );
      }
    }
    return goals;
  }

  /// Drops existing completions in [year]/[month], then appends [seeded].
  static List<GoalSet> mergeMonth({
    required List<GoalSet> existing,
    required List<GoalSet> seeded,
    required int year,
    required int month,
  }) {
    final kept = <GoalSet>[];
    for (final goal in existing) {
      final parsed = CompletionTimestamp.tryParse(goal.completedAt);
      if (parsed != null && parsed.year == year && parsed.month == month) {
        continue;
      }
      kept.add(goal);
    }
    return [...kept, ...seeded];
  }

  /// Replaces the current month on disk with a fresh random seed.
  static Future<List<GoalSet>> replaceCurrentMonth({
    required GoalsRepository goals,
    required DateTime now,
    required Random random,
  }) async {
    final counts = planDayCounts(
      year: now.year,
      month: now.month,
      random: random,
    );
    final seeded = buildGoals(dayCounts: counts, random: random);
    final existing = await goals.readCompletedGoals();
    final merged = mergeMonth(
      existing: existing,
      seeded: seeded,
      year: now.year,
      month: now.month,
    );
    await goals.writeCompletedGoals(merged);
    return merged;
  }

  static int _idFor(int year, int month, int day, int index) {
    return 1600000000 +
        (year % 100) * 1000000 +
        month * 10000 +
        day * 100 +
        index;
  }
}
