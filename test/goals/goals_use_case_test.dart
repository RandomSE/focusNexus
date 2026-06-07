import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsUseCase', () {
    late InMemoryKeyValueStorage storage;
    late GoalsUseCase useCase;
    late PointsRepository points;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      final goals = GoalsRepository(storage);
      points = PointsRepository(storage);
      final userPrefs = UserPrefsRepository(storage);
      final counters = AchievementCountersRepository(storage);
      final theme = ThemeRepository(userPrefs);
      final settings = AppSettings(userPrefs, theme);
      final streaks = AchievementStreakService(counters, userPrefs);
      useCase = GoalsUseCase(
        goals: goals,
        points: points,
        streaks: streaks,
        settings: settings,
        notifications: const NoopGoalNotifications(),
      );
    });

    test('createGoal persists active goal with points', () async {
      final goal = await useCase.createGoal(
        title: 'Test goal',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 99,
      );

      expect(goal.goalId, 99);
      expect(goal.points, greaterThan(0));

      final snapshot = await useCase.load();
      expect(snapshot.active.single.title, 'Test goal');
    });

    test('completeGoal moves goal and awards points', () async {
      await useCase.createGoal(
        title: 'Finish me',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 100,
      );

      final result = await useCase.completeGoal(100);
      expect(result, isNotNull);
      expect(result!.pointsAwarded, greaterThan(0));

      final snapshot = await useCase.load();
      expect(snapshot.active, isEmpty);
      expect(snapshot.completed.single.goalId, 100);
    });

    test('completeGoal persists awarded points to storage', () async {
      await points.ensureInitialized();
      await useCase.createGoal(
        title: 'Points persist',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 301,
      );

      final result = await useCase.completeGoal(301);
      expect(result, isNotNull);

      points.clearBalanceCacheForTesting();
      final persisted = await points.readBalance();
      expect(persisted, PointsRepository.defaultBalance + result!.pointsAwarded);
    });

    test('incrementStepProgress persists awarded points after final step', () async {
      await points.ensureInitialized();
      await useCase.createGoal(
        title: 'Step points',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '2',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 302,
      );

      await useCase.incrementStepProgress(302);
      final completed = await useCase.incrementStepProgress(302);
      expect(completed?.completed, isNotNull);

      points.clearBalanceCacheForTesting();
      final persisted = await points.readBalance();
      expect(
        persisted,
        PointsRepository.defaultBalance + completed!.completed!.pointsAwarded,
      );
    });

    test('persistCompletePlan with optimistic cache credit flushes credited balance',
        () async {
      await points.ensureInitialized();
      final created = await useCase.createGoal(
        title: 'Optimistic flush',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 303,
        activeSnapshot: const [],
      );
      await Future<void>.delayed(Duration.zero);

      final plan = useCase.planCompleteGoal(
        303,
        activeSnapshot: [created],
        completedSnapshot: const [],
        goalsCompletedTodayBefore: 0,
      );
      expect(plan, isNotNull);

      points.creditBalance(plan!.pointsDelta);
      await useCase.persistCompletePlan(
        plan,
        optimisticCacheCredit: true,
      );

      points.clearBalanceCacheForTesting();
      expect(
        await points.readBalance(),
        PointsRepository.defaultBalance + plan.pointsDelta,
      );
    });

    test('completeGoal updates per-category achievement counters', () async {
      await useCase.createGoal(
        title: 'Category goal',
        category: 'Learning',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 200,
      );

      await useCase.completeGoal(200);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        await storage.read(key: StorageKeys.categoriesWithAtLeast1Goal),
        '1',
      );
      expect(
        await storage.read(key: StorageKeys.categoriesWithAllTypesCompleted),
        '1',
      );
    });

    test('createGoal defers streak counters off critical path', () async {
      await useCase.createGoal(
        title: 'Fast create',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 50,
        activeSnapshot: const [],
      );

      final snapshot = await useCase.load();
      expect(snapshot.active.single.goalId, 50);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        await storage.read(key: StorageKeys.totalGoalsCreated),
        '1',
      );
    });

    test('completeGoal with snapshots persists without extra list reads', () async {
      final created = await useCase.createGoal(
        title: 'Snap complete',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 51,
        activeSnapshot: const [],
      );
      await Future<void>.delayed(Duration.zero);

      final result = await useCase.completeGoal(
        51,
        activeSnapshot: [created],
        completedSnapshot: const [],
        goalsCompletedTodayBefore: 0,
      );
      expect(result, isNotNull);
      expect(result!.goalsCompletedToday, 1);

      final snapshot = await useCase.load();
      expect(snapshot.active, isEmpty);
      expect(snapshot.completed.single.goalId, 51);
    });

    test('incrementStepProgress completes when steps reached', () async {
      await useCase.createGoal(
        title: 'Steps',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '2',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        goalId: 101,
      );

      final first = await useCase.incrementStepProgress(101);
      expect(first?.completed, isNull);

      final second = await useCase.incrementStepProgress(101);
      expect(second?.completed, isNotNull);
      expect(second!.completed!.goal.goalId, 101);
    });
  });
}
