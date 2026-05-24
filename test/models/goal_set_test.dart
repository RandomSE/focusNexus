import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

void main() {
  test('fromMap and toMap roundtrip preserves casing and types', () {
    final map = {
      'title': 'Finish report',
      'category': 'Work',
      'complexity': 'High',
      'effort': 'Medium',
      'motivation': 'Low',
      'time': '90',
      'Deadline': '10 May 2026 18:00',
      'steps': '12',
      'points': '45',
      'stepProgress': '3',
      'Id': '999',
    };

    final goal = GoalSet.fromMap(map);
    expect(goal.title, 'Finish report');
    expect(goal.deadline, '10 May 2026 18:00');
    expect(goal.time, 90);
    expect(goal.steps, 12);
    expect(goal.points, 45);
    expect(goal.stepProgress, 3);
    expect(goal.goalId, 999);

    final back = goal.toMap();
    expect(back['Deadline'], '10 May 2026 18:00');
    expect(back['Id'], 999);
  });

  test('fromMap defaults missing fields', () {
    final goal = GoalSet.fromMap({});
    expect(goal.title, '');
    expect(goal.time, 0);
    expect(goal.goalId, 0);
  });
}
