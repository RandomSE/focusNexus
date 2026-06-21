import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/goal_points.dart';

void main() {
  group('GoalPoints time-slot multipliers', () {
    const makeMeal = (
      complexity: 'Medium',
      effort: 'Medium',
      motivation: 'Medium',
      time: '30',
      steps: '2',
    );

    test('deadline goal baseline for Make a meal is 35', () {
      final points = GoalPoints.calculatePointsFromTemplate(
        complexity: makeMeal.complexity,
        effort: makeMeal.effort,
        motivation: makeMeal.motivation,
        time: makeMeal.time,
        steps: makeMeal.steps,
        deadline: '24',
      );
      expect(points, 35);
    });

    test('Make a meal 1.5x slot is 55', () {
      final points = GoalPoints.calculateTimeWindowPoints(
        complexity: makeMeal.complexity,
        effort: makeMeal.effort,
        motivation: makeMeal.motivation,
        time: makeMeal.time,
        steps: makeMeal.steps,
        windowDuration: const Duration(hours: 5),
      );
      expect(points, 55);
    });

    test('Make a meal 2x strict slot is 70', () {
      final points = GoalPoints.calculateTimeWindowPoints(
        complexity: makeMeal.complexity,
        effort: makeMeal.effort,
        motivation: makeMeal.motivation,
        time: makeMeal.time,
        steps: makeMeal.steps,
        windowDuration: const Duration(hours: 2),
      );
      expect(points, 70);
    });

    test('applies 1.5x on deadline-bonus base for standard slots', () {
      final base = GoalPoints.calculatePointsFromTemplate(
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        deadline: 'slot',
      );
      final boosted = GoalPoints.calculateTimeWindowPoints(
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        windowDuration: const Duration(hours: 5),
      );
      expect(boosted, GoalPoints.roundUpToNearestFive(base * 1.5));
    });

    test('applies 2x on deadline-bonus base for strict slots', () {
      final base = GoalPoints.calculatePointsFromTemplate(
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        deadline: 'slot',
      );
      final boosted = GoalPoints.calculateTimeWindowPoints(
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        windowDuration: const Duration(hours: 2),
      );
      expect(boosted, GoalPoints.roundUpToNearestFive(base * 2.0));
    });
  });
}
