import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Riverpod goals provider', () {
    late ProviderContainer container;

    setUp(() async {
      container = await createTestContainer();
      container.read(appRepositoriesProvider);
    });

    tearDown(() => container.dispose());

    test('load populates active goals from use case', () async {
      final notifier = container.read(goalsProvider.notifier);
      final useCase = container.read(appRepositoriesProvider).goalsUseCase;
      await useCase.createGoal(
        title: 'Riverpod goal',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 42,
      );

      await notifier.load(now: DateTime(2026, 6, 3, 12));

      final state = container.read(goalsProvider);
      expect(state.activeGoals, hasLength(1));
      expect(state.activeGoals.single.title, 'Riverpod goal');
    });

    test('completeGoal updates provider state', () async {
      final notifier = container.read(goalsProvider.notifier);
      final useCase = container.read(appRepositoriesProvider).goalsUseCase;
      await useCase.createGoal(
        title: 'Done',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 7,
      );
      await notifier.load(now: DateTime(2026, 6, 3, 12));

      await notifier.completeGoal(7);

      final state = container.read(goalsProvider);
      expect(state.activeGoals, isEmpty);
      expect(state.completedGoals.single.goalId, 7);
    });
  });

  group('Riverpod app settings provider', () {
    test('load exposes defaults through view state', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      await container.read(appSettingsProvider.notifier).load();
      final view = container.read(appSettingsProvider);

      expect(view.isLoaded, isTrue);
      expect(view.snapshot.theme, 'light');
      expect(view.snapshot.fontSize, 14.0);
    });
  });
}
