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

/// Regression: daily 02:34-13:34 slot mid-window with no active instance must
/// rematerialize today's window (not only tomorrow's pending instance).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('computeContainingWindowEnd', () {
    test('finds 02:34-13:34 daily slot at 11:28', () {
      final anchorEnd = DateTime(2026, 7, 17, 13, 34);
      final now = DateTime(2026, 7, 19, 11, 28);
      final end = computeContainingWindowEnd(
        rule: const RepeatRule(
          enabled: true,
          unit: RepeatUnit.days,
          interval: 1,
        ),
        anchorEndAt: anchorEnd,
        duration: const Duration(hours: 11),
        now: now,
      );
      expect(end, DateTime(2026, 7, 19, 13, 34));
    });

    test('returns null when now is past today slot', () {
      final end = computeContainingWindowEnd(
        rule: const RepeatRule(
          enabled: true,
          unit: RepeatUnit.days,
          interval: 1,
        ),
        anchorEndAt: DateTime(2026, 7, 17, 13, 34),
        duration: const Duration(hours: 11),
        now: DateTime(2026, 7, 19, 14, 0),
      );
      expect(end, isNull);
    });
  });

  group('mid-window rematerialize regression', () {
    late GoalsUseCase useCase;
    late TimeWindowRepeatRepository repeats;

    CreateTimeWindowGoalInput dailyLongSlot(DateTime end) {
      return CreateTimeWindowGoalInput(
        title: 'Long slot',
        category: 'Focus',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '10',
        steps: '1',
        windowEndAt: end,
        windowDuration: const Duration(hours: 11),
        repeatRule: const RepeatRule(
          enabled: true,
          unit: RepeatUnit.days,
          interval: 1,
        ),
        goalId: 801,
        seriesId: 9801,
      );
    }

    setUp(() {
      final storage = InMemoryKeyValueStorage();
      repeats = TimeWindowRepeatRepository(storage);
      useCase = GoalsUseCase(
        goals: GoalsRepository(storage),
        points: PointsRepository(storage),
        streaks: AchievementStreakService(
          AchievementCountersRepository(storage),
          UserPrefsRepository(storage),
        ),
        settings: AppSettings(
          UserPrefsRepository(storage),
          ThemeRepository(UserPrefsRepository(storage)),
        ),
        notifications: RecordingGoalNotifications(),
        repeatSeries: repeats,
      );
    });

    test(
      'cleared daily 02:34-13:34 series rematerializes today while still in slot',
      () async {
        final dayStart = DateTime(2026, 7, 19, 2, 34);
        final dayEnd = DateTime(2026, 7, 19, 13, 34);
        final midWindow = DateTime(2026, 7, 19, 11, 28);

        await useCase.createTimeWindowGoal(
          input: dailyLongSlot(dayEnd),
          now: dayStart,
        );
        await useCase.clearActiveGoals(cancelRepeatSeries: false);

        final snapshot = await useCase.load(now: midWindow);
        expect(snapshot.active, isNotEmpty);
        expect(snapshot.active.single.goalKind, GoalKind.timeWindow);
        expect(snapshot.active.single.repeatSeriesId, 9801);
        expect(
          parseGoalDateTime(snapshot.active.single.actionWindowEnd),
          dayEnd,
        );
        expect(
          isActionWindowActive(snapshot.active.single, midWindow),
          isTrue,
        );
      },
    );

    test(
      'complete mid-window still advances to next day, not same slot',
      () async {
        final dayStart = DateTime(2026, 7, 19, 2, 34);
        final dayEnd = DateTime(2026, 7, 19, 13, 34);
        final midWindow = DateTime(2026, 7, 19, 11, 28);

        await useCase.createTimeWindowGoal(
          input: dailyLongSlot(dayEnd),
          now: dayStart,
        );
        await useCase.completeGoal(801, now: midWindow);

        final snapshot = await useCase.load(now: midWindow);
        expect(snapshot.active, isNotEmpty);
        final nextEnd = parseGoalDateTime(snapshot.active.single.actionWindowEnd);
        expect(nextEnd, DateTime(2026, 7, 20, 13, 34));
        expect(isActionWindowActive(snapshot.active.single, midWindow), isFalse);
      },
    );

    test(
      'multi-day gap catch-up rematerializes today without staying stuck',
      () async {
        final createdEnd = DateTime(2026, 7, 15, 13, 34);
        final midWindow = DateTime(2026, 7, 19, 11, 28);

        await useCase.createTimeWindowGoal(
          input: dailyLongSlot(createdEnd),
          now: DateTime(2026, 7, 15, 2, 34),
        );
        await useCase.clearActiveGoals(cancelRepeatSeries: false);

        final snapshot = await useCase.load(now: midWindow);
        expect(snapshot.active, isNotEmpty);
        expect(
          parseGoalDateTime(snapshot.active.single.actionWindowEnd),
          DateTime(2026, 7, 19, 13, 34),
        );
        expect(
          isActionWindowActive(snapshot.active.single, midWindow),
          isTrue,
        );
      },
    );
  });
}
