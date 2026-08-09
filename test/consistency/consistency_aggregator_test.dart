import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/consistency/consistency_aggregator.dart';
import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';

GoalSet _goal({
  required int id,
  required String title,
  required DateTime completedAt,
}) {
  return GoalSet(
    title: title,
    category: 'Test',
    complexity: 'Easy',
    effort: 'Low',
    motivation: 'x',
    time: 10,
    completedAt: CompletionTimestamp.formatLabel(completedAt),
    steps: 1,
    points: 1,
    stepProgress: 1,
    goalId: id,
  );
}

void main() {
  group('ConsistencyAggregator', () {
    test('countsByDay groups by local calendar day', () {
      final goals = [
        _goal(id: 1, title: 'A', completedAt: DateTime(2026, 7, 2, 9, 0)),
        _goal(id: 2, title: 'B', completedAt: DateTime(2026, 7, 2, 18, 30)),
        _goal(id: 3, title: 'C', completedAt: DateTime(2026, 7, 3, 10, 0)),
      ];
      final counts = ConsistencyAggregator.countsByDay(goals);
      expect(counts[DateTime(2026, 7, 2)], 2);
      expect(counts[DateTime(2026, 7, 3)], 1);
    });

    test('skips unparseable CompletedAt without throwing', () {
      final goals = [
        const GoalSet(
          title: 'Bad',
          category: 'Test',
          completedAt: 'not-a-date',
          goalId: 9,
        ),
        _goal(id: 1, title: 'Ok', completedAt: DateTime(2026, 7, 1, 12, 0)),
      ];
      final counts = ConsistencyAggregator.countsByDay(goals);
      expect(counts.length, 1);
      expect(counts[DateTime(2026, 7, 1)], 1);
    });

    test('goalsOnDay sorts by CompletedAt ascending', () {
      final goals = [
        _goal(id: 2, title: 'Later', completedAt: DateTime(2026, 7, 5, 15, 0)),
        _goal(id: 1, title: 'Earlier', completedAt: DateTime(2026, 7, 5, 9, 0)),
        _goal(id: 3, title: 'Other', completedAt: DateTime(2026, 7, 6, 9, 0)),
      ];
      final day = ConsistencyAggregator.goalsOnDay(goals, DateTime(2026, 7, 5));
      expect(day.map((g) => g.title), ['Earlier', 'Later']);
    });

    test('countsForMonth filters to month', () {
      final goals = [
        _goal(id: 1, title: 'Jul', completedAt: DateTime(2026, 7, 1, 9, 0)),
        _goal(id: 2, title: 'Aug', completedAt: DateTime(2026, 8, 1, 9, 0)),
      ];
      final july = ConsistencyAggregator.countsForMonth(goals, 2026, 7);
      expect(july.length, 1);
      expect(july[DateTime(2026, 7, 1)], 1);
    });

    test('earliestCompletionMonth returns first month start', () {
      final goals = [
        _goal(id: 1, title: 'Aug', completedAt: DateTime(2026, 8, 10, 9, 0)),
        _goal(id: 2, title: 'Jun', completedAt: DateTime(2026, 6, 2, 9, 0)),
      ];
      expect(
        ConsistencyAggregator.earliestCompletionMonth(goals),
        ConsistencyDate.monthStart(2026, 6),
      );
      expect(ConsistencyAggregator.earliestCompletionMonth(const []), isNull);
    });
  });
}
