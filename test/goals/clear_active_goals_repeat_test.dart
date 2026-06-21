import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/goals/goals_time_window_service.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
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

  group('clearActiveGoals with repeats', () {
    late InMemoryKeyValueStorage storage;
    late GoalsUseCase useCase;
    late RecordingGoalNotifications notifications;
    late TimeWindowRepeatRepository repeats;

    CreateTimeWindowGoalInput repeatingWalk(DateTime end) {
      return CreateTimeWindowGoalInput(
        title: 'Walk',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        windowEndAt: end,
        windowDuration: const Duration(hours: 2),
        repeatRule: const RepeatRule(
          enabled: true,
          unit: RepeatUnit.days,
          interval: 1,
        ),
        goalId: 601,
        seriesId: 9101,
      );
    }

    setUp(() {
      storage = InMemoryKeyValueStorage();
      notifications = RecordingGoalNotifications();
      repeats = TimeWindowRepeatRepository(storage);
      final goals = GoalsRepository(storage);
      final userPrefs = UserPrefsRepository(storage);
      final counters = AchievementCountersRepository(storage);
      final theme = ThemeRepository(userPrefs);
      final settings = AppSettings(userPrefs, theme);
      useCase = GoalsUseCase(
        goals: goals,
        points: PointsRepository(storage),
        streaks: AchievementStreakService(counters, userPrefs),
        settings: settings,
        notifications: notifications,
        repeatSeries: repeats,
      );
    });

    test('clear without cancelRepeatSeries keeps series active', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 2));
      await useCase.createTimeWindowGoal(
        input: repeatingWalk(end),
        now: now,
      );
      expect(useCase.activeGoalsIncludeRepeats(
        (await useCase.load(now: now)).active,
      ), isTrue);

      await useCase.clearActiveGoals(cancelRepeatSeries: false);

      final series = await useCase.readActiveRepeatSeries();
      expect(series, isNotEmpty);
      expect(series.single.isActive, isTrue);
      expect((await useCase.load(now: now)).active, isEmpty);
    });

    test('clear with cancelRepeatSeries deactivates series', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 2));
      await useCase.createTimeWindowGoal(
        input: repeatingWalk(end),
        now: now,
      );

      await useCase.clearActiveGoals(cancelRepeatSeries: true);

      expect(await useCase.readActiveRepeatSeries(), isEmpty);
      final all = await repeats.readAll();
      expect(all.single.isActive, isFalse);
    });

    test('spawn after clear without cancel produces next goal on load', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 2));
      await useCase.createTimeWindowGoal(
        input: repeatingWalk(end),
        now: now,
      );
      await useCase.clearActiveGoals(cancelRepeatSeries: false);

      final nextSpawnCheck = end.add(const Duration(hours: 23));
      final snapshot = await useCase.load(now: nextSpawnCheck);
      expect(snapshot.active, isNotEmpty);
      expect(snapshot.active.single.goalKind, GoalKind.timeWindow);
      expect(snapshot.active.single.repeatSeriesId, 9101);
    });

    test('deactivateRepeatSeries stops future spawns', () async {
      final now = DateTime(2026, 6, 21, 9);
      final end = now.add(const Duration(hours: 2));
      await useCase.createTimeWindowGoal(
        input: repeatingWalk(end),
        now: now,
      );
      await useCase.deactivateRepeatSeries(9101);
      await useCase.clearActiveGoals(cancelRepeatSeries: false);

      final nextSpawnCheck = end.add(const Duration(hours: 23));
      final snapshot = await useCase.load(now: nextSpawnCheck);
      expect(snapshot.active, isEmpty);
    });
  });
}
