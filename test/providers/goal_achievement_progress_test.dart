import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

Future<void> _waitForBackgroundCounters() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    GoalNotifier.resetForTesting();
    AchievementTrackingVariables.resetForTesting();
  });

  group('goal actions refresh achievement progress', () {
    test('createGoal through provider updates Goal Setter I progress', () async {
      final storage = InMemoryKeyValueStorage();
      final container = await createTestContainer(storage: storage, bootstrap: true);
      addTearDown(container.dispose);

      await container.read(goalsProvider.notifier).createGoal(
            title: 'Achievement test',
            category: 'Health',
            complexity: 'Low',
            effort: 'Low',
            motivation: 'Low',
            time: '5',
            steps: '1',
            deadlineHours: 0,
            anchor: DateTime(2026, 6, 7, 12),
          );
      await _waitForBackgroundCounters();

      final service = container.read(achievementServiceProvider);
      final progress = service.getById('1')?.progress ?? 0;
      expect(progress, 10.0);
    });

    test('completeGoal through provider updates Completionist I progress', () async {
      final storage = InMemoryKeyValueStorage();
      final container = await createTestContainer(storage: storage, bootstrap: true);
      addTearDown(container.dispose);

      final goals = container.read(goalsProvider.notifier);
      await goals.createGoal(
        title: 'Finish for achievement',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 7, 12),
      );
      await _waitForBackgroundCounters();

      final goalId = container.read(goalsProvider).activeGoals.single.goalId;
      goals.completeGoalOptimistic(goalId);
      await _waitForBackgroundCounters();

      final service = container.read(achievementServiceProvider);
      final progress = service.getById('6')?.progress ?? 0;
      expect(progress, 10.0);
    });

    test('createGoal updates scalar counter and achievement progress', () async {
      final storage = InMemoryKeyValueStorage();
      final container = await createTestContainer(storage: storage, bootstrap: true);
      addTearDown(container.dispose);

      await container.read(goalsProvider.notifier).createGoal(
            title: 'Shared storage',
            category: 'Health',
            complexity: 'Low',
            effort: 'Low',
            motivation: 'Low',
            time: '5',
            steps: '1',
            deadlineHours: 0,
            anchor: DateTime(2026, 6, 7, 12),
          );
      await _waitForBackgroundCounters();

      expect(await storage.read(key: StorageKeys.totalGoalsCreated), '1');
      expect(
        container.read(achievementServiceProvider).getById('1')?.progress,
        10.0,
      );
    });
  });
}
