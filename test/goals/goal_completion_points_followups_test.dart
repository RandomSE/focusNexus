import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_field_validators.dart';
import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/goals/goal_points_labels.dart';
import 'package:focusNexus/goals/goal_time_window_label.dart';
import 'package:focusNexus/goals/goals_time_window_service.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_points_label.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/goal_points.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/recording_goal_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FU-1 regular active daily bonus label', () {
    test('active regular rows mention split first-day preview', () {
      const goal = GoalSet(
        title: 'Task',
        goalId: 1,
        points: 5,
        deadline: 'no deadline',
      );
      final lines = goalListSubtitleLines(
        goal: goal,
        selectedStatusFilter: 'Active',
        now: DateTime(2026, 8, 9, 12),
      );
      expect(lines.first, contains('~20 if first today'));
      expect(lines.first, contains('momentum 10'));
    });

    test('completed regular rows keep awarded pts without preview', () {
      const goal = GoalSet(
        title: 'Done',
        goalId: 2,
        points: 20,
        completedAt: '09 August 2026 12:00',
      );
      final lines = goalListSubtitleLines(
        goal: goal,
        selectedStatusFilter: 'Completed',
        now: DateTime(2026, 8, 9, 12),
      );
      expect(lines.first, startsWith('20 pts ·'));
      expect(lines.first, isNot(contains('if first today')));
    });
  });

  group('FU-2 max TW first-of-day award 605', () {
    test('create max strict TW and complete as first today awards 605', () async {
      final storage = InMemoryKeyValueStorage(initial: {
        StorageKeys.points: '50',
      });
      final points = PointsRepository(storage);
      final goals = GoalsRepository(storage);
      final prefs = UserPrefsRepository(storage);
      final useCase = GoalsUseCase(
        goals: goals,
        points: points,
        streaks: AchievementStreakService(
          AchievementCountersRepository(storage),
          prefs,
        ),
        settings: AppSettings(prefs, ThemeRepository(prefs)),
        notifications: RecordingGoalNotifications(),
        repeatSeries: TimeWindowRepeatRepository(storage),
      );

      final now = DateTime(2026, 8, 9, 10);
      final end = now.add(const Duration(hours: 3));
      final goal = await useCase.createTimeWindowGoal(
        input: CreateTimeWindowGoalInput(
          title: 'Max Slot',
          category: 'Health',
          complexity: 'High',
          effort: 'High',
          motivation: 'High',
          time: '600',
          steps: '50',
          windowEndAt: end,
          windowDuration: const Duration(hours: 3),
          repeatRule: RepeatRule.none,
          goalId: 9801,
        ),
        now: now,
        activeSnapshot: const [],
      );

      expect(goal.goalKind, GoalKind.timeWindow);
      expect(goal.points, 440);

      final during = now.add(const Duration(hours: 1));
      final result = await useCase.completeGoal(
        9801,
        now: during,
        goalsCompletedTodayBefore: 0,
      );

      expect(result, isNotNull);
      expect(result!.pointsAwarded, 605);
      expect(result.goal.points, 605);
      expect(result.goalsCompletedToday, 1);

      final completed = await goals.readCompletedGoals();
      expect(completed.single.points, 605);
      expect(await points.readBalance(), 50 + 605);
    });
  });

  group('FU-3 award preview labels', () {
    test('activeGoalDetailPointsLabel includes split first-day estimate', () {
      // 70*1.35+10 = 104.5 -> 105
      expect(
        activeGoalDetailPointsLabel(70),
        'Points: 70 (~105 if first today (effort 94.5 + momentum 10))',
      );
    });

    test('timeWindowCreateRewardLabel includes split first-day estimate', () {
      expect(
        timeWindowCreateRewardLabel(
          storedPoints: 70,
          multiplierLabel: '2x strict slot',
        ),
        'Reward: 70 pts (2x strict slot); '
        '~105 if first today (effort 94.5 + momentum 10)',
      );
    });

    test('timeWindowGoalPointsLabel includes split first-day estimate', () {
      final label = timeWindowGoalPointsLabel(
        GoalSet(
          title: 'Slot',
          goalId: 3,
          goalKind: GoalKind.timeWindow,
          points: 70,
          actionWindowStart: DateTime(2026, 8, 9, 10).toIso8601String(),
          actionWindowEnd: DateTime(2026, 8, 9, 12).toIso8601String(),
        ),
      );
      expect(label, contains('~105 if first today'));
      expect(label, contains('momentum 10'));
    });
  });

  group('FU-4 TW uses unrounded template base', () {
    test('avoids double ceil that inflated strict TW awards', () {
      final roundedBase = GoalPoints.calculatePointsFromTemplate(
        complexity: 'High',
        effort: 'High',
        motivation: 'Low',
        time: '1',
        steps: '1',
        deadline: 'slot',
      );
      expect(roundedBase, 70);

      final strict = GoalPoints.calculateTimeWindowPoints(
        complexity: 'High',
        effort: 'High',
        motivation: 'Low',
        time: '1',
        steps: '1',
        windowDuration: const Duration(hours: 2),
      );
      expect(strict, 135);
      expect(strict, isNot(GoalPoints.roundUpToNearestFive(roundedBase * 2.0)));
    });
  });

  group('FU-5 field validators', () {
    test('time minutes reject above scoring plateau', () {
      expect(GoalFieldValidators.timeMinutes('600'), isNull);
      expect(GoalFieldValidators.timeMinutes('601'), contains('600'));
      expect(GoalFieldValidators.timeMinutes('0'), isNotNull);
    });

    test('steps reject above scoring plateau', () {
      expect(GoalFieldValidators.steps('50'), isNull);
      expect(GoalFieldValidators.steps('51'), contains('50'));
      expect(GoalFieldValidators.steps(''), isNull);
    });
  });
}
