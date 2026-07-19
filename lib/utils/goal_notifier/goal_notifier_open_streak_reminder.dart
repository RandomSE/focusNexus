import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/notification_schedule_utils.dart';

import 'goal_notifier_bindings.dart';
import 'goal_notifier_init.dart';
import 'goal_notifier_permissions.dart';
import 'goal_notifier_runtime.dart';
import 'goal_notifier_scheduling.dart';

/// Fixed notification id above affirmation band (500000-500089).
const openStreakReminderNotificationId =
    GoalNotifierRuntime.openStreakReminderNotificationId;

Future<void> cancelOpenStreakReminder() async {
  final r = GoalNotifierRuntime.I;
  await r.plugin.cancel(openStreakReminderNotificationId);
  debugLog('Open streak reminder canceled.');
}

/// Schedules one next local-notification at [timeToTrigger] (HH:mm).
Future<void> startOpenStreakReminder(String? timeToTrigger) async {
  if (!await areNotificationsEnabledByFrequency()) {
    debugLog(
      'Skipping open streak reminder because notifications are disabled by frequency.',
    );
    return;
  }

  await initialize();
  final storedFlag = await goalNotifierStorage().read(
    key: StorageKeys.openStreakReminders,
  );
  if (storedFlag != 'true') {
    debugLog('Open streak reminders toggle is off; not scheduling.');
    return;
  }

  final effectiveTime = NotificationScheduleUtils.normalizeHHmm(
    timeToTrigger ??
        await goalNotifierStorage().read(
          key: StorageKeys.openStreakRemindersTime,
        ),
  );
  final trigger = NotificationScheduleUtils.nextTriggerFromHHmm(effectiveTime);
  if (trigger == null) {
    debugLog('Invalid open streak reminder time: $timeToTrigger');
    return;
  }

  final streakRaw = await goalNotifierStorage().read(
    key: StorageKeys.consecutiveDaysAppOpened,
  );
  final streak = int.tryParse(streakRaw ?? '') ?? 0;
  final body = streak > 0
      ? 'Your open streak is day $streak. Open the app tomorrow to keep it going.'
      : 'Open FocusNexus tomorrow to start your daily open streak bonus.';

  await cancelOpenStreakReminder();
  await scheduleOpenStreakReminder(
    trigger,
    GoalNotifierRuntime.I.scheduleMode,
    'Keep your open streak',
    body,
  );
  debugLog('Open streak reminder scheduled for $trigger.');
}
