import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/goals/goals_filter_sort.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:intl/intl.dart';

GoalSet _goal({
  required int id,
  required String title,
  String kind = GoalKind.deadline,
  String windowStart = '',
  String windowEnd = '',
}) {
  return GoalSet(
    title: title,
    category: 'Health',
    complexity: 'Low',
    effort: 'Low',
    motivation: 'Low',
    time: 10,
    deadline: kind == GoalKind.timeWindow ? '' : 'no deadline',
    steps: 1,
    points: 5,
    goalId: id,
    goalKind: kind,
    actionWindowStart: windowStart,
    actionWindowEnd: windowEnd,
  );
}

void main() {
  final format = DateFormat('dd MMMM yyyy HH:mm');
  final now = DateTime(2026, 6, 21, 12);

  test('default sort puts in-window time-window goals first', () {
    final inWindow = _goal(
      id: 1,
      title: 'Walk',
      kind: GoalKind.timeWindow,
      windowStart: now.subtract(const Duration(minutes: 30)).toIso8601String(),
      windowEnd: now.add(const Duration(hours: 1)).toIso8601String(),
    );
    final outside = _goal(
      id: 2,
      title: 'Later',
      kind: GoalKind.timeWindow,
      windowStart: now.add(const Duration(hours: 2)).toIso8601String(),
      windowEnd: now.add(const Duration(hours: 3)).toIso8601String(),
    );
    final normal = _goal(id: 3, title: 'Normal');

    final sorted = filterAndSortGoals(
      source: [outside, normal, inWindow],
      categoryFilter: 'All',
      complexityFilter: 'All',
      sortBy: 'None',
      deadlineFormat: format,
      now: now,
    );

    expect(sorted.map((g) => g.goalId), [1, 3, 2]);
  });

  test('Time-slot only keeps all time-slot goals regardless of slot state', () {
    final inWindow = _goal(
      id: 1,
      title: 'Now',
      kind: GoalKind.timeWindow,
      windowStart: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      windowEnd: now.add(const Duration(hours: 1)).toIso8601String(),
    );
    final outside = _goal(
      id: 2,
      title: 'Later',
      kind: GoalKind.timeWindow,
      windowStart: now.add(const Duration(hours: 2)).toIso8601String(),
      windowEnd: now.add(const Duration(hours: 3)).toIso8601String(),
    );
    final normal = _goal(id: 3, title: 'Normal');

    final filtered = filterAndSortGoals(
      source: [normal, outside, inWindow],
      categoryFilter: 'All',
      complexityFilter: 'All',
      sortBy: 'Time-slot only',
      deadlineFormat: format,
      now: now,
    );

    expect(filtered, hasLength(2));
    expect(filtered.map((g) => g.goalId).toSet(), {1, 2});
  });

  test('Time-slot only keeps time-slot goals', () {
    final tw = _goal(
      id: 1,
      title: 'TW',
      kind: GoalKind.timeWindow,
      windowEnd: now.add(const Duration(hours: 1)).toIso8601String(),
    );
    final normal = _goal(id: 2, title: 'Normal');

    final filtered = filterAndSortGoals(
      source: [normal, tw],
      categoryFilter: 'All',
      complexityFilter: 'All',
      sortBy: 'Time-slot only',
      deadlineFormat: format,
      now: now,
    );

    expect(filtered, hasLength(1));
    expect(isTimeWindowGoal(filtered.single), isTrue);
  });

  test('In slot now keeps only active slots', () {
    final inWindow = _goal(
      id: 1,
      title: 'Now',
      kind: GoalKind.timeWindow,
      windowStart: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      windowEnd: now.add(const Duration(hours: 1)).toIso8601String(),
    );
    final later = _goal(
      id: 2,
      title: 'Later',
      kind: GoalKind.timeWindow,
      windowStart: now.add(const Duration(hours: 2)).toIso8601String(),
      windowEnd: now.add(const Duration(hours: 3)).toIso8601String(),
    );

    final filtered = filterAndSortGoals(
      source: [later, inWindow],
      categoryFilter: 'All',
      complexityFilter: 'All',
      sortBy: 'In slot now',
      deadlineFormat: format,
      now: now,
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.goalId, 1);
  });
}
