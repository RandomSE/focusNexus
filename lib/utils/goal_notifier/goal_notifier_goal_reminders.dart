import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:timezone/timezone.dart' as tz;

import '../common_utils.dart';
import '../notification_schedule_utils.dart';
import '../text_utils.dart';
import 'goal_notifier_ai_encouragement.dart';
import 'goal_notifier_runtime.dart';
import 'goal_notifier_scheduling.dart';

/// Schedule goal reminders.
Future<void> startGoalCheck(
  GoalSet
  goalSet, // pass in entire goalSet for any later additions to this method (e.g AI encouragement for tasks that need more energy to begin.)
  String notificationStyle,
  String notificationFrequency,
  int hoursToExpire,
) async {
  final r = GoalNotifierRuntime.I;
  String goalName = goalSet.title;
  int goalId = goalSet.goalId;
  r.now = tz.TZDateTime.now(tz.local);
  final deadline = r.now.add(Duration(hours: hoursToExpire));
  final oneHourBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 1);
  final twoHourBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 2);
  final fourHourBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 4);
  final dayBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 24);

  // Shared reminder for Low, Medium & High frequency.
  if (fourHourBeforeDeadline.isAfter(r.now)) {
    await scheduleReminder(
      goalId + 2,
      'Goal Reminder',
      TextUtils.buildFollowUpReminderMessage(
        goalName,
        goalId,
        notificationStyle,
        deadline,
      ),
      fourHourBeforeDeadline,
      r.scheduleMode,
      r.goalGroupId,
      'Goal Reminders',
      'Reminders for goals',
      'goal_group',
      'Goal Reminder',
      'Goal Reminders',
      'Reminders for goals',
    );
  }

  if (notificationFrequency == 'Medium' && dayBeforeDeadline.isAfter(r.now)) {
    await scheduleReminder(
      goalId + 3,
      'Goal Reminder',
      TextUtils.buildFollowUpReminderMessage(
        goalName,
        goalId,
        notificationStyle,
        deadline,
      ),
      dayBeforeDeadline,
      r.scheduleMode,
      r.goalGroupId,
      'Goal Reminders',
      'Reminders for goals',
      'goal_group',
      'Goal Reminder',
      'Goal Reminders',
      'Reminders for goals',
    );
  }

  if (notificationFrequency == 'High') {
    if (oneHourBeforeDeadline.isAfter(r.now)) {
      await scheduleReminder(
        goalId,
        'Goal Reminder',
        TextUtils.buildFollowUpReminderMessage(
          goalName,
          goalId,
          notificationStyle,
          deadline,
        ),
        oneHourBeforeDeadline,
        r.scheduleMode,
        r.goalGroupId,
        'Goal Reminders',
        'Reminders for goals',
        'goal_group',
        'Goal Reminder',
        'Goal Reminders',
        'Reminders for goals',
      );
    }

    if (twoHourBeforeDeadline.isAfter(r.now)) {
      await scheduleReminder(
        goalId + 1,
        'Goal Reminder',
        TextUtils.buildFollowUpReminderMessage(
          goalName,
          goalId,
          notificationStyle,
          deadline,
        ),
        twoHourBeforeDeadline,
        r.scheduleMode,
        r.goalGroupId,
        'Goal Reminders',
        'Reminders for goals',
        'goal_group',
        'Goal Reminder',
        'Goal Reminders',
        'Reminders for goals',
      );
    }

    final totalDays = hoursToExpire ~/ 24;
    final dailyOffsets =
        NotificationScheduleUtils.highFrequencyDailyReminderDayOffsets(
          hoursToExpire,
        );
    if (dailyOffsets.isNotEmpty) {
      for (final i in dailyOffsets) {
        final dailyTime = deadline.subtract(Duration(days: i));
        if (!dailyTime.isAfter(r.now)) continue;
        await scheduleReminder(
          goalId + 10 + i,
          'Daily Goal Reminder',
          TextUtils.buildFollowUpReminderMessage(
            goalName,
            goalId,
            notificationStyle,
            deadline,
          ),
          dailyTime,
          r.scheduleMode,
          r.goalRepeatingGroupId,
          'Daily Goal Reminders',
          'Daily reminders for goals',
          'daily_goal_group',
          'Daily Goal Reminder',
          'Daily Goal Reminders',
          'Daily Reminders for goals',
        );
      }
    }
    if (totalDays == 1 &&
        hoursToExpire > 24 &&
        dayBeforeDeadline.isAfter(r.now)) {
      await scheduleReminder(
        goalId + 3,
        'Goal Reminder',
        TextUtils.buildFollowUpReminderMessage(
          goalName,
          goalId,
          notificationStyle,
          deadline,
        ),
        dayBeforeDeadline,
        r.scheduleMode,
        r.goalGroupId,
        'Goal Reminders',
        'Reminders for goals',
        'goal_group',
        'Goal Reminder',
        'Goal Reminders',
        'Reminders for goals',
      );
    }
  }

  if (r.aiEncouragement && hoursToExpire > 6) {
    await scheduleAiEncouragementSuite(
      goalSet: goalSet,
      goalName: goalName,
      goalId: goalId,
      notificationStyle: notificationStyle,
      now: r.now,
      deadline: deadline,
      hoursToExpire: hoursToExpire,
    );
  }
}
