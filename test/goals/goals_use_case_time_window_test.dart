import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/goals/goals_time_window_service.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/settings/app_settings.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/recording_goal_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsUseCase time-window', () {
    late InMemoryKeyValueStorage storage;
    late GoalsUseCase useCase;
    late RecordingGoalNotifications notifications;
    late TimeWindowRepeatRepository repeats;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      notifications = RecordingGoalNotifications();
      final goals = GoalsRepository(storage);
      repeats = TimeWindowRepeatRepository(storage);
      final userPrefs = UserPrefsRepository(storage);
      final counters = AchievementCountersRepository(storage);
      final theme = ThemeRepository(userPrefs);
      final settings = AppSettings(userPrefs, theme);
      final streaks = AchievementStreakService(counters, userPrefs);
      useCase = GoalsUseCase(
        goals: goals,
        points: PointsRepository(storage),
        streaks: streaks,
        settings: settings,
        notifications: notifications,
        repeatSeries: repeats,
      );
    });

    Future<CreateTimeWindowGoalInput> walkInput({
      required DateTime end,
      RepeatRule repeat = RepeatRule.none,
      int goalId = 501,
    }) async {
      return CreateTimeWindowGoalInput(
        title: 'Walk',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        windowEndAt: end,
        windowDuration: const Duration(hours: 1),
        repeatRule: repeat,
        goalId: goalId,
        seriesId: 9001,
      );
    }

    test('createTimeWindowGoal persists active time-window goal', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 2));
      final goal = await useCase.createTimeWindowGoal(
        input: await walkInput(end: end),
        now: now,
        activeSnapshot: const [],
      );

      expect(goal.goalKind, GoalKind.timeWindow);
      expect(goal.actionWindowEnd, isNotEmpty);
      expect(
        parseGoalDateTime(goal.actionWindowStart),
        now.add(const Duration(hours: 1)),
      );

      final snapshot = await useCase.load(now: now);
      expect(snapshot.active.single.goalId, 501);
    });

    test('completeGoal blocked outside action window', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 2));
      await useCase.createTimeWindowGoal(
        input: await walkInput(end: end),
        now: now,
        activeSnapshot: const [],
      );

      final tooEarly = now.subtract(const Duration(minutes: 1));
      expect(await useCase.completeGoal(501, now: tooEarly), isNull);

      final during = now.add(const Duration(hours: 1, minutes: 30));
      final result = await useCase.completeGoal(501, now: during);
      expect(result, isNotNull);
      expect(result!.goal.goalId, 501);
      expect(
        (await useCase.load(now: during)).active,
        isEmpty,
      );
    });

    test('expired time-window goal removed on load', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 1));
      await useCase.createTimeWindowGoal(
        input: await walkInput(end: end),
        now: now,
        activeSnapshot: const [],
      );

      final afterEnd = end.add(const Duration(minutes: 1));
      final snapshot = await useCase.load(now: afterEnd);
      expect(snapshot.active, isEmpty);
      expect(notifications.cancelled, isNotEmpty);
    });

    test('removeGoal and clearActiveGoals cancel time-window goals', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 2));
      final goal = await useCase.createTimeWindowGoal(
        input: await walkInput(end: end),
        now: now,
        activeSnapshot: const [],
      );

      await useCase.removeGoal(goal.goalId);
      expect(notifications.cancelled.map((g) => g.goalId), contains(goal.goalId));

      final second = await useCase.createTimeWindowGoal(
        input: await walkInput(end: end, goalId: 502),
        now: now,
        activeSnapshot: const [],
      );
      await useCase.clearActiveGoals();
      expect(
        notifications.cancelled.map((g) => g.goalId),
        contains(second.goalId),
      );
    });
  });
}
