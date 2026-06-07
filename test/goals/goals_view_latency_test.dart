import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/latency_key_value_storage.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsView optimistic latency', () {
    late ProviderContainer container;

    setUp(() async {
      final storage = LatencyKeyValueStorage(
        inner: InMemoryKeyValueStorage(),
        operationDelay: const Duration(milliseconds: 100),
      );
      container = await createTestContainer(storage: storage);
      container.read(goalNotifierWiringProvider);
      await container.read(appRepositoriesProvider).points.ensureInitialized();
    });

    tearDown(() {
      container.dispose();
    });

    test('createGoal updates state before slow storage finishes', () async {
      final stopwatch = Stopwatch()..start();
      await container.read(goalsProvider.notifier).createGoal(
            title: 'Fast create',
            category: 'Health',
            complexity: 'Low',
            effort: 'Low',
            motivation: 'Low',
            time: '5',
            steps: '1',
            deadlineHours: 0,
            anchor: DateTime(2026, 6, 3, 12),
          );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(goalsUiUpdateBudgetMs));
      expect(
        container.read(goalsProvider).activeGoals.single.title,
        'Fast create',
      );

      await Future<void>.delayed(const Duration(milliseconds: 600));
      final useCase = container.read(appRepositoriesProvider).goalsUseCase;
      final snapshot = await useCase.load();
      expect(snapshot.active.single.title, 'Fast create');
    });

    test('completeGoal updates state before slow storage finishes', () async {
      await container.read(goalsProvider.notifier).createGoal(
            title: 'To complete',
            category: 'Health',
            complexity: 'Low',
            effort: 'Low',
            motivation: 'Low',
            time: '5',
            steps: '1',
            deadlineHours: 0,
            anchor: DateTime(2026, 6, 3, 12),
          );
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final goalId = container.read(goalsProvider).activeGoals.single.goalId;

      final stopwatch = Stopwatch()..start();
      container.read(goalsProvider.notifier).completeGoalOptimistic(goalId);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(goalsUiUpdateBudgetMs));
      expect(container.read(goalsProvider).activeGoals, isEmpty);
      expect(
        container.read(goalsProvider).completedGoals.single.goalId,
        goalId,
      );
    });
  });
}
