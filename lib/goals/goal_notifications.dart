import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/notifier.dart';

/// Schedules and cancels goal reminders (wraps [GoalNotifier] for use-case tests).
abstract class GoalNotifications {
  Future<void> schedule({
    required GoalSet goal,
    required String notificationStyle,
    required String notificationFrequency,
    required int deadlineHours,
  });

  Future<void> scheduleActionWindow({
    required GoalSet goal,
    required DateTime reminderAt,
    required String notificationStyle,
    required bool isStartReminder,
  });

  Future<void> cancelForGoal(GoalSet goal);

  Future<void> cancelAiEncouragement(int goalId);

  Future<void> cancelAll();
}

class GoalNotifierNotifications implements GoalNotifications {
  const GoalNotifierNotifications();

  @override
  Future<void> schedule({
    required GoalSet goal,
    required String notificationStyle,
    required String notificationFrequency,
    required int deadlineHours,
  }) {
    return GoalNotifier.startGoalCheck(
      goal,
      notificationStyle,
      notificationFrequency,
      deadlineHours,
    );
  }

  @override
  Future<void> scheduleActionWindow({
    required GoalSet goal,
    required DateTime reminderAt,
    required String notificationStyle,
    required bool isStartReminder,
  }) {
    return GoalNotifier.scheduleActionWindowReminder(
      goal: goal,
      reminderAt: reminderAt,
      notificationStyle: notificationStyle,
      isStartReminder: isStartReminder,
    );
  }

  @override
  Future<void> cancelForGoal(GoalSet goal) =>
      GoalNotifier.cancelGoalNotification(goal);

  @override
  Future<void> cancelAiEncouragement(int goalId) =>
      GoalNotifier.cancelAiEncouragementNotification(goalId);

  @override
  Future<void> cancelAll() => GoalNotifier.cancelAllGoalNotifications();
}

/// No-op implementation for unit tests without a notification plugin.
class NoopGoalNotifications implements GoalNotifications {
  const NoopGoalNotifications();

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
  }) async {}

  @override
  Future<void> cancelForGoal(GoalSet goal) async {}

  @override
  Future<void> cancelAiEncouragement(int goalId) async {}

  @override
  Future<void> cancelAll() async {}
}
