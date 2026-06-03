import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/settings/app_settings.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsUseCase', () {
    late InMemoryKeyValueStorage storage;
    late GoalsUseCase useCase;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      final goals = GoalsRepository(storage);
      final points = PointsRepository(storage);
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
