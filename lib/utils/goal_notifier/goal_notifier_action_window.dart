import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/text_utils.dart';

import 'goal_notifier_runtime.dart';
import 'goal_notifier_scheduling.dart';

/// Schedules a single action-window reminder (start or end-1h).
Future<void> scheduleActionWindowReminder({
  required GoalSet goal,
  required DateTime reminderAt,
  required String notificationStyle,
  required bool isStartReminder,
}) async {
  final r = GoalNotifierRuntime.I;
  final goalId = goal.goalId;
  final notificationId = goalId +
      (isStartReminder
          ? actionWindowStartNotificationOffset
          : actionWindowEndReminderNotificationOffset);

  final body = TextUtils.buildActionWindowReminderMessage(
    goal.title,
    goalId,
    notificationStyle,
    reminderAt,
    isStart: isStartReminder,
  );

  await scheduleReminder(
    notificationId,
    'Time-window goal',
    body,
    reminderAt,
    r.scheduleMode,
    r.goalGroupId,
    'Time-window goals',
    'Reminders for time-window goals',
    'time_window_goal_group',
    'Time-window goal',
    'Time-window goals',
    'Reminders for time-window goals',
    payload: 'goals:$goalId',
  );
}
