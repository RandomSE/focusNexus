import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:focusNexus/services/storage/storage_keys.dart';

import '../affirmation_selector.dart';
import '../notification_schedule_utils.dart';
import 'goal_notifier_bindings.dart';
import 'goal_notifier_cancellation.dart';
import 'goal_notifier_init.dart';
import 'goal_notifier_permissions.dart';
import 'goal_notifier_runtime.dart';
import 'goal_notifier_scheduling.dart';

/// Extends or rebuilds daily affirmation schedules when runway is low.
Future<void> refreshDailyAffirmationSchedules({
  bool forceReschedule = false,
}) async {
  final r = GoalNotifierRuntime.I;
  if (!r.dailyAffirmations || !await areNotificationsEnabledByFrequency()) {
    return;
  }

  final storedTime = await goalNotifierStorage().read(
    key: StorageKeys.dailyAffirmationsTime,
  );
  final effectiveTime = NotificationScheduleUtils.normalizeHHmm(storedTime);
  final scheduledUntilRaw = await goalNotifierStorage().read(
    key: StorageKeys.dailyAffirmationsScheduledUntil,
  );
  final scheduledUntil = NotificationScheduleUtils.parseDateKey(
    scheduledUntilRaw,
  );
  final now = tz.TZDateTime.now(tz.local);

  final needsRefresh =
      forceReschedule ||
      NotificationScheduleUtils.shouldRefreshAffirmationSchedule(
        scheduledUntil: scheduledUntil,
        now: DateTime(now.year, now.month, now.day),
      );

  if (!needsRefresh) {
    debugPrint('Daily affirmations schedule still has sufficient runway.');
    return;
  }

  await startDailyAffirmations(effectiveTime);
}

int dailyAffirmationNotificationIdForDay(int dayOffset) =>
    GoalNotifierRuntime.dailyAffirmationsScheduleBaseId + dayOffset;

Future<void> startDailyAffirmations(String? timeToTrigger) async {
  final r = GoalNotifierRuntime.I;
  if (!await areNotificationsEnabledByFrequency()) {
    debugPrint(
      'Skipping daily affirmations scheduling because notifications are disabled by frequency.',
    );
    return;
  }

  await initialize(); // ensure plugin + timezone are ready
  final effectiveTime = NotificationScheduleUtils.normalizeHHmm(
    timeToTrigger,
  );
  final firstTrigger = NotificationScheduleUtils.nextTriggerFromHHmm(
    effectiveTime,
  );

  if (firstTrigger == null) {
    debugPrint('Invalid timeToTrigger: $timeToTrigger');
    return;
  }

  final styleRaw = await goalNotifierStorage().read(
    key: StorageKeys.notificationStyle,
  );
  final notificationStyle =
      (styleRaw ?? 'Minimal').trim().isEmpty ? 'Minimal' : styleRaw!.trim();

  await cancelDailyAffirmationsNotification();

  final triggers = NotificationScheduleUtils.dailyTriggersFrom(
    firstTrigger: firstTrigger,
    days: r.dailyAffirmationsHorizonDays,
  );

  debugPrint(
    'Scheduling ${triggers.length} daily affirmations from $firstTrigger ($effectiveTime).',
  );

  var scheduledCount = 0;
  for (var day = 0; day < triggers.length; day++) {
    final trigger = triggers[day];
    if (!trigger.isAfter(tz.TZDateTime.now(tz.local))) {
      continue;
    }
    final body = AffirmationSelector.forDate(
      trigger,
      notificationStyle: notificationStyle,
    );
    await scheduleDailyAffirmations(
      trigger,
      r.scheduleMode,
      'Daily Affirmations',
      body,
      notificationId: dailyAffirmationNotificationIdForDay(day),
    );
    scheduledCount++;
  }

  if (scheduledCount > 0) {
    final lastDay = triggers.last;
    await goalNotifierStorage().write(
      key: StorageKeys.dailyAffirmationsScheduledUntil,
      value: NotificationScheduleUtils.formatDateKey(
        DateTime(lastDay.year, lastDay.month, lastDay.day),
      ),
    );
  }

  debugPrint('Scheduled $scheduledCount daily affirmation notifications.');
}
