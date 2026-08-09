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

  group('computeDailyCompletionReward Option 1', () {
    test('first of day: 1.35x effort + 10 momentum', () {
      // 5*1.35+10 = 16.75 -> 20; stays under Word Bloom playCost 80.
      expect(GoalPoints.computeDailyCompletionReward(5, 1), 20);
      expect(GoalPoints.computeDailyCompletionReward(220, 1), 310);
      expect(GoalPoints.computeDailyCompletionReward(440, 1), 605);
    });

    test('counts 2..5: 1.20x effort + 8 momentum', () {
      expect(GoalPoints.computeDailyCompletionReward(5, 2), 15);
      expect(GoalPoints.computeDailyCompletionReward(5, 5), 15);
      expect(GoalPoints.computeDailyCompletionReward(20, 2), 35);
    });

    test('counts 6..10: 1.10x effort + 5 momentum', () {
      expect(GoalPoints.computeDailyCompletionReward(5, 6), 10);
      expect(GoalPoints.computeDailyCompletionReward(5, 10), 10);
      expect(GoalPoints.computeDailyCompletionReward(20, 6), 30);
    });

    test('eleventh and beyond: 1.0x effort + 0 momentum', () {
      expect(GoalPoints.computeDailyCompletionReward(5, 11), 5);
      expect(GoalPoints.computeDailyCompletionReward(17, 11), 20);
      expect(GoalPoints.computeDailyCompletionReward(220, 11), 220);
    });

    test('first-to-late ratio on trivial A stays at most ~4x', () {
      final first = GoalPoints.computeDailyCompletionReward(5, 1);
      final late = GoalPoints.computeDailyCompletionReward(5, 11);
      expect(first / late, lessThanOrEqualTo(4.0));
      expect(first, greaterThan(late));
    });

    test('breakdown exposes effort and momentum before final round', () {
      final b = GoalPoints.computeDailyCompletionBreakdown(5, 1);
      expect(b.effortAward, closeTo(6.75, 1e-9));
      expect(b.momentumBonus, 10);
      expect(b.total, 20);
      expect(b.total, GoalPoints.computeDailyCompletionReward(5, 1));
    });
  });
}
