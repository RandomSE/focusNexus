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

  group('repeat series lifecycle', () {
    late GoalsUseCase useCase;
    late RecordingGoalNotifications notifications;

    setUp(() {
      final storage = InMemoryKeyValueStorage();
      notifications = RecordingGoalNotifications();
      final goals = GoalsRepository(storage);
      useCase = GoalsUseCase(
        goals: goals,
        points: PointsRepository(storage),
        streaks: AchievementStreakService(
          AchievementCountersRepository(storage),
          UserPrefsRepository(storage),
        ),
        settings: AppSettings(
          UserPrefsRepository(storage),
          ThemeRepository(UserPrefsRepository(storage)),
        ),
        notifications: notifications,
        repeatSeries: TimeWindowRepeatRepository(storage),
      );
    });

    test('complete spawns next repeating instance', () async {
      final now = DateTime(2026, 6, 21, 10);
      final end = now.add(const Duration(hours: 1));
      await useCase.createTimeWindowGoal(
        input: CreateTimeWindowGoalInput(
          title: 'Shower',
          category: 'Health',
          complexity: 'Low',
          effort: 'Low',
          motivation: 'Low',
          time: '10',
          steps: '1',
          windowEndAt: end,
          windowDuration: const Duration(minutes: 30),
          repeatRule: const RepeatRule(
            enabled: true,
            unit: RepeatUnit.days,
            interval: 1,
          ),
          goalId: 701,
          seriesId: 9201,
        ),
        now: now,
      );

      await useCase.completeGoal(701, now: now.add(const Duration(minutes: 15)));
      final snapshot = await useCase.load(now: end);
      expect(snapshot.active.length, 1);
      expect(snapshot.active.single.goalId, isNot(701));
      expect(snapshot.active.single.repeatSeriesId, 9201);
    });

    test('expire spawns next repeating instance', () async {
      final now = DateTime(2026, 6, 21, 10);
      final end = now.add(const Duration(hours: 1));
      await useCase.createTimeWindowGoal(
        input: CreateTimeWindowGoalInput(
          title: 'Shower',
          category: 'Health',
          complexity: 'Low',
          effort: 'Low',
          motivation: 'Low',
          time: '10',
          steps: '1',
          windowEndAt: end,
          windowDuration: const Duration(minutes: 30),
          repeatRule: const RepeatRule(
            enabled: true,
            unit: RepeatUnit.hours,
            interval: 2,
          ),
          goalId: 702,
          seriesId: 9202,
        ),
        now: now,
      );

      final after = end.add(const Duration(minutes: 5));
      final snapshot = await useCase.load(now: after);
      expect(snapshot.active, isNotEmpty);
      expect(snapshot.active.any((g) => g.goalId == 702), isFalse);
      expect(notifications.cancelled, isNotEmpty);
    });
  });
}
