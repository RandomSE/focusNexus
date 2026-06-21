import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/goals/time_window_points_label.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/goal_points.dart';

void main() {
  test('formatActionWindowEndLabel omits seconds', () {
    final label = formatActionWindowEndLabel(
      DateTime(2026, 6, 21, 15, 25, 2, 91, 356),
    );
    expect(label, '21/6/2026 15:25');
    expect(label.contains('.'), isFalse);
  });

  test('timeWindowGoalPointsLabel includes multiplier', () {
    final goal = GoalSet(
      title: 'Walk',
      category: 'Health',
      complexity: 'Low',
      effort: 'Low',
      motivation: 'Low',
      time: 10,
      deadline: '',
      steps: 1,
      points: GoalPoints.calculateTimeWindowPoints(
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        windowDuration: const Duration(hours: 2),
      ),
      goalId: 1,
      goalKind: GoalKind.timeWindow,
      actionWindowStart: DateTime(2026, 6, 21, 13).toIso8601String(),
      actionWindowEnd: DateTime(2026, 6, 21, 15).toIso8601String(),
    );
    expect(timeWindowGoalPointsLabel(goal), contains('2× strict slot'));
    expect(timeWindowGoalPointsLabel(goal), startsWith('${goal.points} pts'));
  });
}
