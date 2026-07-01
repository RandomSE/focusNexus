import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final anchor = DateTime(2026, 6, 3, 12);

  Future<ProviderContainer> goalsContainer() async {
    final container = await createTestContainer();
    await lightTestBootstrap(container);
    return container;
  }

  Future<int> createTestGoal(ProviderContainer container, {String steps = '1'}) async {
    final goal = await container.read(goalsProvider.notifier).createGoal(
          title: 'Test goal',
          category: 'Health',
          complexity: 'Low',
          effort: 'Low',
          motivation: 'Low',
          time: '5',
          steps: steps,
          deadlineHours: 0,
          anchor: anchor,
        );
    return goal.goalId;
  }

  group('GoalsView notifier', () {
    test('load updates provider state', () async {
      final container = await goalsContainer();
      addTearDown(container.dispose);

      await container.read(goalsProvider.notifier).load(now: anchor);

      expect(container.read(goalsProvider).activeGoals, isEmpty);
    });

    test('completeGoalOptimistic returns null for unknown goalId', () async {
      final container = await goalsContainer();
      addTearDown(container.dispose);

      final result =
          container.read(goalsProvider.notifier).completeGoalOptimistic(-1);

      expect(result, isNull);
      expect(container.read(goalsProvider).activeGoals, isEmpty);
    });

    test('completeGoalOptimistic moves goal and credits points', () async {
      final container = await goalsContainer();
      addTearDown(container.dispose);
      await container.read(pointsBalanceProvider.future);

      final goalId = await createTestGoal(container);
      final balanceBefore = container.read(pointsBalanceProvider).value!;

      final result =
          container.read(goalsProvider.notifier).completeGoalOptimistic(goalId);

      expect(result, isNotNull);
      expect(container.read(goalsProvider).activeGoals, isEmpty);
      expect(
        container.read(goalsProvider).completedGoals.single.goalId,
        goalId,
      );
      expect(container.read(goalsProvider).goalsCompletedToday, 1);

      final balanceAfter = await container.read(pointsBalanceProvider.future);
      expect(balanceAfter, greaterThan(balanceBefore));
    });

    test('incrementStepProgress auto-completes single-step goal', () async {
      final container = await goalsContainer();
      addTearDown(container.dispose);

      final goalId = await createTestGoal(container, steps: '1');

      final result =
          await container.read(goalsProvider.notifier).incrementStepProgress(
                goalId,
              );

      expect(result?.completed, isNotNull);
      expect(container.read(goalsProvider).activeGoals, isEmpty);
      expect(
        container.read(goalsProvider).completedGoals.single.goalId,
        goalId,
      );
    });

    test('incrementStepProgress returns null for unknown goalId', () async {
      final container = await goalsContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(goalsProvider.notifier).incrementStepProgress(
                999,
              );

      expect(result, isNull);
    });

    test('removeGoal drops goal from active list', () async {
      final container = await goalsContainer();
      addTearDown(container.dispose);

      final goalId = await createTestGoal(container);
      await container.read(goalsProvider.notifier).removeGoal(goalId);

      expect(container.read(goalsProvider).activeGoals, isEmpty);
    });

    test('achievement refresh tolerates disposed container', () async {
      final container = await goalsContainer();
      await createTestGoal(container);
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  });
}
