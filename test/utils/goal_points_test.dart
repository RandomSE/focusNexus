import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/goal_points.dart';

void main() {
  group('calculatePointsFromTemplate', () {
    test('minimum template with no deadline', () {
      expect(
        GoalPoints.calculatePointsFromTemplate(
          complexity: 'Low',
          effort: 'Low',
          motivation: 'Low',
          time: '1',
          steps: '1',
          deadline: 'no deadline',
        ),
        5,
      );
    });

    test('deadline adds bonus to additive multiplier', () {
      final withDeadline = GoalPoints.calculatePointsFromTemplate(
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '1',
        steps: '1',
        deadline: '01 January 2027 12:00',
      );
      final without = GoalPoints.calculatePointsFromTemplate(
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '1',
        steps: '1',
        deadline: 'no deadline',
      );
      expect(withDeadline, greaterThan(without));
    });

    test('high-count multiplier tiers', () {
      final oneHigh = GoalPoints.calculatePointsFromTemplate(
        complexity: 'High',
        effort: 'Low',
        motivation: 'Low',
        time: '30',
        steps: '4',
        deadline: 'no deadline',
      );
      final twoHigh = GoalPoints.calculatePointsFromTemplate(
        complexity: 'High',
        effort: 'High',
        motivation: 'Low',
        time: '30',
        steps: '4',
        deadline: 'no deadline',
      );
      final threeHigh = GoalPoints.calculatePointsFromTemplate(
        complexity: 'High',
        effort: 'High',
        motivation: 'High',
        time: '600',
        steps: '50',
        deadline: '01 January 2027 12:00',
      );
      expect(twoHigh, greaterThan(oneHigh));
      expect(threeHigh, greaterThan(twoHigh));
      expect(threeHigh % 5, 0);
    });

    test('always rounds up to nearest five', () {
      expect(GoalPoints.roundUpToNearestFive(1), 5);
      expect(GoalPoints.roundUpToNearestFive(5), 5);
      expect(GoalPoints.roundUpToNearestFive(6), 10);
    });

    test('invalid numeric strings treated as zero', () {
      expect(
        GoalPoints.calculatePointsFromTemplate(
          complexity: 'Low',
          effort: 'Low',
          motivation: 'Low',
          time: 'abc',
          steps: '',
          deadline: '',
        ),
        5,
      );
    });
  });

  group('computeDailyCompletionReward', () {
    test('first completion doubles plus flat bonus', () {
      expect(GoalPoints.computeDailyCompletionReward(10, 1), 120);
    });

    test('second through fifth use 1.5x + 20', () {
      expect(GoalPoints.computeDailyCompletionReward(20, 2), 50);
      expect(GoalPoints.computeDailyCompletionReward(10, 5), 35);
    });

    test('sixth through tenth use 1.25x + 5', () {
      expect(GoalPoints.computeDailyCompletionReward(20, 6), 30);
      expect(GoalPoints.computeDailyCompletionReward(20, 10), 30);
    });

    test('eleventh and beyond use base amount rounded', () {
      expect(GoalPoints.computeDailyCompletionReward(17, 11), 20);
    });
  });
}
