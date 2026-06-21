import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../goal_notification_android.dart';
import 'goal_notifier_ids.dart';
import 'goal_notifier_runtime.dart';

Future<void> showInstantNotifications({
  required int id,
  required String title,
  required String body,
}) async {
  final r = GoalNotifierRuntime.I;
  final preview = GoalNotificationAndroid.collapsedPreview(body);
  await r.plugin.show(
    id,
    title,
    preview,
    GoalNotificationAndroid.platformDetails(
      channelId: 'instant_notification_channel',
      channelName: 'Instant Notifications',
      channelDescription: 'Instant Notification channel',
      title: title,
      fullBody: body,
    ),
  );
}

Future<void> scheduleReminder(
  int id,
  String title,
  String body,
  DateTime scheduledTime,
  AndroidScheduleMode mode,
  int summaryNotificationId,
  String summaryTitle,
  String summaryBody,
  String groupKey,
  String channelId,
  String channelName,
  String channelDescription, {
  String? payload,
}) async {
  final r = GoalNotifierRuntime.I;
  if (summaryNotificationId == r.goalRepeatingGroupId) {
    await scheduleRepeatingGoalSummaryNotification(
      scheduledTime,
      mode,
      groupKey,
      channelId,
      channelName,
      channelDescription,
      summaryTitle,
      summaryBody,
    );
    debugPrint('Daily reminder scheduled for $scheduledTime, goalId: $id');
  } else if (summaryNotificationId == r.goalGroupId) {
    debugPrint('Reminder scheduled for $scheduledTime, goalId: $id');
    await scheduleSummaryNotification(
      scheduledTime,
      mode,
      summaryNotificationId,
      groupKey,
      channelId,
      channelName,
      channelDescription,
      summaryTitle,
      summaryBody,
    );
  } else if (summaryNotificationId == r.aiEncouragementGroupId) {
    await scheduleSummaryNotification(
      scheduledTime,
      mode,
      summaryNotificationId,
      groupKey,
      channelId,
      channelName,
      channelDescription,
      summaryTitle,
      summaryBody,
    );
  }

  final trigger = tz.TZDateTime.from(scheduledTime, tz.local);
  if (!trigger.isAfter(tz.TZDateTime.now(tz.local))) {
    debugPrint(
      'Skipping reminder id=$id: scheduled time $trigger is not in the future.',
    );
    return;
  }

  final preview = GoalNotificationAndroid.collapsedPreview(body);
  await r.plugin.zonedSchedule(
    id,
    title,
    preview,
    trigger,
    GoalNotificationAndroid.platformDetails(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      title: title,
      fullBody: body,
      groupKey: groupKey,
    ),
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: mode,
    payload: payload,
  );
}

int summaryNotificationIdFor(int baseGroupId, DateTime triggerTime) {
  final minuteBucket = triggerTime.millisecondsSinceEpoch ~/ 60000;
  return baseGroupId * 100000 + (minuteBucket % 99999);
}

Future<void> scheduleSummaryNotification(
  DateTime triggerTime,
  AndroidScheduleMode mode,
  int id,
  String groupKey,
  String channelId,
  String channelName,
  String channelDescription,
  String title,
  String body,
) async {
  final r = GoalNotifierRuntime.I;
  setNow();
  if (!triggerTime.isAfter(r.now)) {
    return;
  }

  final summaryId = summaryNotificationIdFor(id, triggerTime);
  final preview = GoalNotificationAndroid.collapsedPreview(body);

  await r.plugin.zonedSchedule(
    summaryId,
    title,
    preview,
    tz.TZDateTime.from(triggerTime, tz.local),
    GoalNotificationAndroid.platformDetails(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      title: title,
      fullBody: body,
      groupKey: groupKey,
      setAsGroupSummary: true,
    ),
    androidScheduleMode: mode,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
  debugPrint(
    'Group summary scheduled at $triggerTime (id: $summaryId, group: $groupKey).',
  );
}

Future<void> scheduleRepeatingGoalSummaryNotification(
  DateTime triggerTime,
  AndroidScheduleMode mode,
  String groupKey,
  String channelId,
  String channelName,
  String channelDescription,
  String title,
  String body,
) async {
  final r = GoalNotifierRuntime.I;
  setNow();
  if (!triggerTime.isAfter(r.now)) {
    return;
  }

  final summaryId = summaryNotificationIdFor(
    r.goalRepeatingGroupId,
    triggerTime,
  );
  final preview = GoalNotificationAndroid.collapsedPreview(body);

  await r.plugin.zonedSchedule(
    summaryId,
    title,
    preview,
    tz.TZDateTime.from(triggerTime, tz.local),
    GoalNotificationAndroid.platformDetails(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      title: title,
      fullBody: body,
      groupKey: groupKey,
      setAsGroupSummary: true,
    ),
    androidScheduleMode: mode,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
  debugPrint(
    'Repeating group summary scheduled at $triggerTime (id: $summaryId).',
  );
}

Future<void> scheduleDailyAffirmations(
  tz.TZDateTime triggerTime,
  AndroidScheduleMode mode,
  String title,
  String body, {
  int? notificationId,
}) async {
  final r = GoalNotifierRuntime.I;
  final preview = GoalNotificationAndroid.collapsedPreview(body);
  final platformDetails = GoalNotificationAndroid.platformDetails(
    channelId: 'daily_affirmations_channel',
    channelName: 'Daily Affirmations',
    channelDescription:
        'Daily affirmations to improve your mood and stay motivated.',
    title: title,
    fullBody: body,
    groupKey: 'daily_affirmations',
  );

  await r.plugin.zonedSchedule(
    notificationId ?? r.dailyAffirmationsGroupId,
    title,
    preview,
    triggerTime,
    platformDetails,
    androidScheduleMode: mode,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
