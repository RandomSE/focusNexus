import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/debug_log.dart';

import '../theme_styles.dart';
import 'goal_notifier_bindings.dart';
import 'goal_notifier_daily_affirmations.dart';
import 'goal_notifier_runtime.dart';

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
  final wasEnabled = ThemeStyles.notificationsEnabledForFrequency(
    normalizedOld,
  );
  final isEnabled = ThemeStyles.notificationsEnabledForFrequency(
    normalizedNew,
  );
  if (wasEnabled || !isEnabled) {
    return;
  }

  await checkDailyAffirmations();
  if (!r.dailyAffirmations) {
    debugLog(
      'Skipped daily affirmations refresh after frequency re-enable: setting disabled.',
    );
    return;
  }

  final storedTime = await goalNotifierStorage().read(
    key: StorageKeys.dailyAffirmationsTime,
  );
  final normalizedTime = (storedTime ?? '').trim();
  final effectiveTime = normalizedTime.isEmpty ? '06:00' : normalizedTime;
  await _scheduleDailyAffirmationsAfterFrequencyEnable(effectiveTime);
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
