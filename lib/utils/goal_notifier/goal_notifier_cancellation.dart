import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import 'package:focusNexus/goals/time_window_goal.dart';
import 'goal_notifier_bindings.dart';
import 'goal_notifier_daily_affirmations.dart';
import 'goal_notifier_permissions.dart';
import 'goal_notifier_runtime.dart';

/// Cancel notifications for a specific goal. The group/summary notifications are not removed here, only by cancel all goals (a summary is only shown if there are at least 2 notifications in that group. So an empty summary is not an issue.)
Future<void> cancelGoalNotification(GoalSet goalSet) async {
  final r = GoalNotifierRuntime.I;
  final goalId = goalSet.goalId;
  final goalName = goalSet.title;
  final deadline = goalSet.deadline;
  debugLog('Cancelling notifications for goal: $goalName, goalID: $goalId');

  if (isTimeWindowGoal(goalSet)) {
    await Future.wait([
      r.plugin.cancel(goalId + actionWindowStartNotificationOffset),
      r.plugin.cancel(goalId + actionWindowEndReminderNotificationOffset),
    ]);
  } else {
    final hasDeadline = deadline != 'no deadline' && deadline.trim().isNotEmpty;
    if (!hasDeadline) {
      // No deadline-based notifications to cancel.
    } else {
    final now = DateTime.now();
    final deadlineDate = r.formatter.parse(deadline);
    final daysToExpire = deadlineDate.difference(now).inDays;

    final cancelOps = <Future<void>>[
      r.plugin.cancel(goalId), // 1-hour before - High
      r.plugin.cancel(goalId + 1), // 4-hours before - all
      r.plugin.cancel(goalId + 3), // 2-hours before - High
      r.plugin.cancel(goalId + actionWindowStartNotificationOffset),
      r.plugin.cancel(goalId + actionWindowEndReminderNotificationOffset),
    ];

    if (daysToExpire > 0) {
      for (var i = 1; i <= daysToExpire; i++) {
        cancelOps.add(r.plugin.cancel(goalId + 10 + i));
      }
      cancelOps.add(r.plugin.cancel(goalId + 2)); // 1 day before - medium, High
      for (final offset in GoalNotifierRuntime.aiEncouragementSlotOffsets) {
        cancelOps.add(r.plugin.cancel(goalId + offset));
      }
    }

    await Future.wait(cancelOps);
    }
  }

  // Cancel any active timers
  if (r.activeTimers.containsKey(goalName)) {
    for (final timer in r.activeTimers[goalName]!) {
      timer.cancel();
    }
    r.activeTimers.remove(goalName);
  }

  debugLog('Notifications cancelled for goal: $goalName');
}

Future<void> cancelAiEncouragementNotification(int goalId) async {
  final r = GoalNotifierRuntime.I;
  for (final offset in GoalNotifierRuntime.aiEncouragementSlotOffsets) {
    await r.plugin.cancel(goalId + offset);
  }
  debugLog(
    'AI encouragement for goal canceled due to step progress addition.',
  );
}

Future<void> cancelDailyAffirmationsNotification() async {
  final r = GoalNotifierRuntime.I;
  final cancelOps = <Future<void>>[
    r.plugin.cancel(r.dailyAffirmationsGroupId),
    for (var day = 0; day < r.dailyAffirmationsHorizonDays; day++)
      r.plugin.cancel(dailyAffirmationNotificationIdForDay(day)),
  ];
  await Future.wait(cancelOps);
  await goalNotifierStorage().delete(key: StorageKeys.dailyAffirmationsScheduledUntil);
  debugLog('Daily affirmations canceled.');
}

/// Cancel all notifications and timers indiscriminately
Future<void> cancelAllGoalNotifications() async {
  final r = GoalNotifierRuntime.I;
  debugLog('Cancelling all goal-related notifications and timers…');

  // Cancel all scheduled notifications
  await r.plugin.cancelAll();

  // Cancel all active timers
  for (final entry in r.activeTimers.entries) {
    for (final timer in entry.value) {
      timer.cancel();
    }
  }
  r.activeTimers.clear();

  if (r.dailyAffirmations && await areNotificationsEnabledByFrequency()) {
    final timeToTrigger = await goalNotifierStorage().read(
      key: StorageKeys.dailyAffirmationsTime,
    );
    const fallbackTime = '06:00';
    final effectiveTime =
        (timeToTrigger != null && timeToTrigger.trim().isNotEmpty)
            ? timeToTrigger
            : fallbackTime;
    await startDailyAffirmations(effectiveTime);
  }

  debugLog('All goal notifications and timers cancelled.');
}
