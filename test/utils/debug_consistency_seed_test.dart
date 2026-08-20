import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/consistency/consistency_aggregator.dart';
import 'package:focusNexus/debug/debug_consistency_seed.dart';
import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('DebugConsistencySeed.planDayCounts', () {
    test('covers every day; one zero; rest 1-50', () {
      final counts = DebugConsistencySeed.planDayCounts(
        year: 2026,
        month: 8,
        random: Random(42),
      );
      expect(counts.length, 31);
      final zeros = counts.values.where((c) => c == 0).length;
      expect(zeros, 1);
      for (final entry in counts.entries) {
        expect(entry.key.year, 2026);
        expect(entry.key.month, 8);
        if (entry.value == 0) continue;
        expect(entry.value, inInclusiveRange(1, 50));
      }
    });

    test('February non-leap has 28 days', () {
      final counts = DebugConsistencySeed.planDayCounts(
        year: 2026,
        month: 2,
        random: Random(7),
      );
      expect(counts.length, 28);
      expect(counts.values.where((c) => c == 0).length, 1);
    });
  });

  group('DebugConsistencySeed.buildGoals', () {
    test('emits actual GoalSets matching the plan', () {
      final counts = DebugConsistencySeed.planDayCounts(
        year: 2026,
        month: 8,
        random: Random(42),
      );
      final goals = DebugConsistencySeed.buildGoals(
        dayCounts: counts,
        random: Random(42),
      );
      final expectedTotal = counts.values.fold<int>(0, (a, b) => a + b);
      expect(goals.length, expectedTotal);
      expect(goals, isNotEmpty);

      final ids = goals.map((g) => g.goalId).toSet();
      expect(ids.length, goals.length);
      for (final goal in goals) {
        expect(goal.title, isNotEmpty);
        expect(kGoalCategories, contains(goal.category));
        expect(goal.completedAt, isNotEmpty);
        expect(CompletionTimestamp.tryParse(goal.completedAt), isNotNull);
        expect(goal.points, 0);
        expect(goal.goalId, greaterThan(0));
      }

      final aggregated = ConsistencyAggregator.countsForMonth(goals, 2026, 8);
      var zeroDays = 0;
      for (var day = 1; day <= 31; day++) {
        final count = aggregated[DateTime(2026, 8, day)] ?? 0;
        if (count == 0) {
          zeroDays += 1;
        } else {
          expect(count, inInclusiveRange(1, 50));
        }
      }
      expect(zeroDays, 1);
    });
  });

  group('DebugConsistencySeed.mergeMonth', () {
    test('replaces the target month and keeps other months', () {
      final july = GoalSet(
        title: 'Keep July',
        category: 'Health',
        completedAt: CompletionTimestamp.formatLabel(DateTime(2026, 7, 4, 9)),
        goalId: 11,
        points: 5,
      );
      final augustOld = GoalSet(
        title: 'Replace August',
        category: 'Work',
        completedAt: CompletionTimestamp.formatLabel(DateTime(2026, 8, 1, 8)),
        goalId: 12,
        points: 5,
      );
      final seeded = DebugConsistencySeed.buildGoals(
        dayCounts: {
          DateTime(2026, 8, 2): 2,
          DateTime(2026, 8, 3): 0,
        },
        random: Random(1),
      );
      final merged = DebugConsistencySeed.mergeMonth(
        existing: [july, augustOld],
        seeded: seeded,
        year: 2026,
        month: 8,
      );
      expect(merged.any((g) => g.goalId == 11), isTrue);
      expect(merged.any((g) => g.goalId == 12), isFalse);
      expect(merged.where((g) => g.goalId == 11).single.points, 5);
      expect(seeded.length, 2);
      expect(merged.length, 3);
    });
  });

  test('replaceCurrentMonth writes seeded goals to the repository', () async {
    final repo = GoalsRepository(InMemoryKeyValueStorage());
    final merged = await DebugConsistencySeed.replaceCurrentMonth(
      goals: repo,
      now: DateTime(2026, 8, 16, 15),
      random: Random(3),
    );
    final stored = await repo.readCompletedGoals();
    expect(stored.length, merged.length);
    expect(stored, isNotEmpty);
    final counts = ConsistencyAggregator.countsForMonth(stored, 2026, 8);
    expect(counts.values.where((c) => c == 0).length, 0);
    var emptyDays = 0;
    for (var day = 1; day <= 31; day++) {
      final count = counts[DateTime(2026, 8, day)] ?? 0;
      if (count == 0) emptyDays += 1;
    }
    expect(emptyDays, 1);
  });
}
