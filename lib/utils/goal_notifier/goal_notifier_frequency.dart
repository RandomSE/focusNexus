import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:focusNexus/utils/debug_log.dart';

import 'goal_notifier_bindings.dart';
import 'goal_notifier_cancellation.dart';
import 'goal_notifier_daily_affirmations.dart';
import 'goal_notifier_open_streak_reminder.dart';
import 'goal_notifier_permissions.dart';
import 'goal_notifier_runtime.dart';

/// Applies permission / cancel side effects, then restores schedules on re-enable.
Future<void> applyFrequencyChange({
  required String oldFrequency,
  required String newFrequency,
}) async {
  final normalizedOld = oldFrequency.trim();
  final normalizedNew = newFrequency.trim();
  final wasEnabled = NotificationPreferenceOptions.isEnabled(normalizedOld);
  final isEnabled = NotificationPreferenceOptions.isEnabled(normalizedNew);

  if (!wasEnabled && isEnabled) {
    await requestNotificationPermission();
  }
  if (wasEnabled && !isEnabled) {
    await cancelAllGoalNotifications();
  }
  await refreshSchedulesForFrequencyChange(
    oldFrequency: normalizedOld,
    newFrequency: normalizedNew,
  );
}

/// Re-applies schedules affected by a frequency transition.
///
/// When frequency moves from disabled (`No notifications`) to an enabled
/// value, daily affirmations must be restored if that setting is enabled.
Future<void> refreshSchedulesForFrequencyChange({
  required String oldFrequency,
  required String newFrequency,
}) async {
  final r = GoalNotifierRuntime.I;
  final normalizedOld = oldFrequency.trim();
  final normalizedNew = newFrequency.trim();
  final wasEnabled = NotificationPreferenceOptions.isEnabled(normalizedOld);
  final isEnabled = NotificationPreferenceOptions.isEnabled(normalizedNew);
  if (wasEnabled || !isEnabled) {
    return;
  }

  await checkDailyAffirmations();
  if (r.dailyAffirmations) {
    final storedTime = await goalNotifierStorage().read(
      key: StorageKeys.dailyAffirmationsTime,
    );
    final normalizedTime = (storedTime ?? '').trim();
    final effectiveTime = normalizedTime.isEmpty ? '06:00' : normalizedTime;
    await _scheduleDailyAffirmationsAfterFrequencyEnable(effectiveTime);
  } else {
    debugLog(
      'Skipped daily affirmations refresh after frequency re-enable: setting disabled.',
    );
  }

  await checkOpenStreakReminders();
  if (r.openStreakReminders) {
    final storedTime = await goalNotifierStorage().read(
      key: StorageKeys.openStreakRemindersTime,
    );
    final time = (storedTime ?? '').trim().isEmpty ? '20:00' : storedTime!.trim();
    await startOpenStreakReminder(time);
  }
}

Future<void> _scheduleDailyAffirmationsAfterFrequencyEnable(
  String time,
) async {
  final r = GoalNotifierRuntime.I;
  final scheduler = r.dailyAffirmationsSchedulerForTesting;
  if (scheduler != null) {
    await scheduler(time);
    return;
  }
  await startDailyAffirmations(time);
}

void setDailyAffirmationsSchedulerForTesting(
  Future<void> Function(String time)? scheduler,
) {
  GoalNotifierRuntime.I.dailyAffirmationsSchedulerForTesting = scheduler;
}
