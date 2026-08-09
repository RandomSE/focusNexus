import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/progressive_visuals_points_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/settings/app_settings.dart';

import '../helpers/in_memory_key_value_storage.dart';

/// Integration coverage for the PV momentum hook wired into the goal
/// completion pipeline (planCompleteGoal -> persistCompletePlan).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryKeyValueStorage storage;
  late GoalsUseCase useCase;
  late ProgressiveVisualsPointsRepository pv;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    final goals = GoalsRepository(storage);
    final points = PointsRepository(storage);
    final userPrefs = UserPrefsRepository(storage);
    final counters = AchievementCountersRepository(storage);
    final theme = ThemeRepository(userPrefs);
    final settings = AppSettings(userPrefs, theme);
    final streaks = AchievementStreakService(counters, userPrefs);
    pv = ProgressiveVisualsPointsRepository(storage);
    useCase = GoalsUseCase(
      goals: goals,
      points: points,
      streaks: streaks,
      settings: settings,
      notifications: const NoopGoalNotifications(),
      repeatSeries: TimeWindowRepeatRepository(storage),
      progressiveVisualsPoints: pv,
      deadlineFormat: DateFormat('dd MMMM yyyy HH:mm'),
    );
  });

  Future<void> completeQualifyingGoal(int goalId, {int points = 60}) async {
    final goal = GoalSet(title: 'Q$goalId', points: points, goalId: goalId);
    final plan = useCase.planCompleteGoal(
      goalId,
      activeSnapshot: [goal],
      completedSnapshot: const [],
      goalsCompletedTodayBefore: 0,
    );
    expect(plan, isNotNull);
    await useCase.persistCompletePlan(plan!);
    await Future<void>.delayed(Duration.zero);
  }

  group('PV daily momentum hook', () {
    test('a single qualifying completion grants no PV (below first threshold)',
        () async {
      await completeQualifyingGoal(1, points: 60);

      expect(await pv.readBalance(), 0);
    });

    test('non-qualifying completions (points < 50) never increment the counter',
        () async {
      for (var i = 1; i <= 15; i++) {
        await completeQualifyingGoal(i, points: 49);
      }

      expect(await pv.readBalance(), 0);
    });

    test('the 10th qualifying completion in a day grants +1000 PV', () async {
      for (var i = 1; i <= 10; i++) {
        await completeQualifyingGoal(i, points: 60);
      }

      expect(await pv.readBalance(), 1000);
    });

    test('10/20/30 qualifying completions in one day grant the full 3000 PV cap',
        () async {
      for (var i = 1; i <= 30; i++) {
        await completeQualifyingGoal(i, points: 60);
      }

      expect(await pv.readBalance(), 3000);
    });

    test('completions past 30 in the same day grant no further PV', () async {
      for (var i = 1; i <= 35; i++) {
        await completeQualifyingGoal(i, points: 60);
      }

      expect(await pv.readBalance(), 3000);
    });

    test('mixing qualifying and non-qualifying completions only counts qualifying ones',
        () async {
      var id = 1;
      // 9 qualifying completions interleaved with non-qualifying noise.
      for (var i = 0; i < 9; i++) {
        await completeQualifyingGoal(id++, points: 10); // non-qualifying
        await completeQualifyingGoal(id++, points: 60); // qualifying
      }
      expect(await pv.readBalance(), 0);

      // 10th qualifying completion crosses the threshold.
      await completeQualifyingGoal(id++, points: 10);
      await completeQualifyingGoal(id++, points: 60);

      expect(await pv.readBalance(), 1000);
    });

    test('without a wired PV repository the pipeline is a no-op (does not throw)',
        () async {
      final goals = GoalsRepository(storage);
      final points = PointsRepository(storage);
      final userPrefs = UserPrefsRepository(storage);
      final counters = AchievementCountersRepository(storage);
      final theme = ThemeRepository(userPrefs);
      final settings = AppSettings(userPrefs, theme);
      final streaks = AchievementStreakService(counters, userPrefs);
      final noPvUseCase = GoalsUseCase(
        goals: goals,
        points: points,
        streaks: streaks,
        settings: settings,
        notifications: const NoopGoalNotifications(),
        repeatSeries: TimeWindowRepeatRepository(storage),
        deadlineFormat: DateFormat('dd MMMM yyyy HH:mm'),
      );
      final goal = GoalSet(title: 'NoPv', points: 60, goalId: 900);
      final plan = noPvUseCase.planCompleteGoal(
        900,
        activeSnapshot: [goal],
        completedSnapshot: const [],
        goalsCompletedTodayBefore: 0,
      );

      await noPvUseCase.persistCompletePlan(plan!);
      await Future<void>.delayed(Duration.zero);
    });
  });
}
