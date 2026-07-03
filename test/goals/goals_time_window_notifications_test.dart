import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/goals/goals_time_window_service.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/settings/app_settings.dart';

import '../helpers/in_memory_key_value_storage.dart';

class _RecordingGoalNotifications implements GoalNotifications {
  final scheduled = <({GoalSet goal, bool isStart})>[];

  @override
  Future<void> cancelAiEncouragement(int goalId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelForGoal(GoalSet goal) async {}

  @override
  Future<void> schedule({
    required GoalSet goal,
    required String notificationStyle,
    required String notificationFrequency,
    required int deadlineHours,
  }) async {}

  @override
  Future<void> scheduleActionWindow({
    required GoalSet goal,
    required DateTime reminderAt,
    required String notificationStyle,
    required bool isStartReminder,
  }) async {
    scheduled.add((goal: goal, isStart: isStartReminder));
  }
}

void main() {
  test('does not schedule start reminder when goal is already in slot', () async {
    final storage = InMemoryKeyValueStorage();
    final prefs = UserPrefsRepository(storage);
    final settings = AppSettings(prefs, ThemeRepository(prefs));
    await settings.setNotificationFrequency('Medium');
    final notifications = _RecordingGoalNotifications();
    final service = GoalsTimeWindowService(
      repeats: TimeWindowRepeatRepository(storage),
      notifications: notifications,
      settings: settings,
    );

    final now = DateTime(2026, 7, 2, 12, 0);
    final end = now.add(const Duration(hours: 12));
    await service.createGoal(
      input: CreateTimeWindowGoalInput(
        title: 'In-slot repeat',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '30',
        steps: '1',
        windowEndAt: end,
        windowDuration: const Duration(days: 1),
        repeatRule: const RepeatRule(enabled: true, unit: RepeatUnit.days),
      ),
      now: now,
      activeSnapshot: const [],
    );

    final startReminders =
        notifications.scheduled.where((e) => e.isStart).toList();
    expect(startReminders, isEmpty);
  });
}
