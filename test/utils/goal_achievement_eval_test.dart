import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/goal_achievement_eval.dart';

void main() {
  GoalSet goal({
    int points = 50,
    String complexity = 'Low',
    String effort = 'Low',
    String motivation = 'Low',
    int time = 30,
    int steps = 5,
    String deadline = 'no deadline',
  }) {
    return GoalSet(
      title: 'Test',
      category: 'Work',
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      deadline: deadline,
      steps: steps,
      points: points,
      stepProgress: 0,
      goalId: 1,
    );
  }

  group('GoalAchievementEval', () {
    test('flags high attribute thresholds', () {
      final result = GoalAchievementEval.evaluate(
        goal(
          points: 120,
          complexity: 'High',
          effort: 'High',
          motivation: 'High',
          time: 200,
          steps: 20,
        ),
        DateTime.utc(2026, 1, 1),
      );
      expect(result.highPoints, isTrue);
      expect(result.highComplexity, isTrue);
      expect(result.highEffort, isTrue);
      expect(result.highMotivation, isTrue);
      expect(result.allHigh, isTrue);
      expect(result.highTimeRequirement, isTrue);
      expect(result.manySteps, isTrue);
    });

    test('completedEarly when deadline is 20+ hours away', () {
      final now = DateTime.utc(2026, 5, 10, 12);
      final deadline = '12 May 2026 14:00';
      final result = GoalAchievementEval.evaluate(
        goal(deadline: deadline),
        now,
      );
      expect(result.completedEarly, isTrue);
    });

    test('completedEarly false for invalid or missing deadline', () {
      expect(
        GoalAchievementEval.evaluate(goal(), DateTime.utc(2026, 1, 1)).completedEarly,
        isFalse,
      );
      expect(
        GoalAchievementEval.evaluate(
          goal(deadline: 'not-a-date'),
          DateTime.utc(2026, 1, 1),
        ).completedEarly,
        isFalse,
      );
    });

    test('completedEarly false when less than 20 hours remain', () {
      final now = DateTime.utc(2026, 5, 10, 12);
      final result = GoalAchievementEval.evaluate(
        goal(deadline: '10 May 2026 20:00'),
        now,
      );
      expect(result.completedEarly, isFalse);
    });
  });
}
