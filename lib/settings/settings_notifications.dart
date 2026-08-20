import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:focusNexus/utils/notifier.dart';

/// Settings-side orchestration for notification prefs + GoalNotifier side effects.
abstract final class SettingsNotifications {
  SettingsNotifications._();

  static Future<void> setDailyAffirmations(
    AppSettings settings,
    bool value,
  ) async {
    await settings.setDailyAffirmations(value);
    if (value) {
      await setDailyAffirmationsTime(settings, settings.dailyAffirmationsTime);
    } else {
      await GoalNotifier.cancelDailyAffirmationsNotification();
    }
  }

  static Future<void> setDailyAffirmationsTime(
    AppSettings settings,
    String time,
  ) async {
    await settings.setDailyAffirmationsTime(time);
    await GoalNotifier.startDailyAffirmations(time);
  }

  static Future<void> setOpenStreakReminders(
    AppSettings settings,
    bool value,
  ) async {
    await settings.setOpenStreakReminders(value);
    if (value) {
      await setOpenStreakRemindersTime(
        settings,
        settings.openStreakRemindersTime,
      );
    } else {
      await GoalNotifier.cancelOpenStreakReminder();
    }
  }

  static Future<void> setOpenStreakRemindersTime(
    AppSettings settings,
    String time,
  ) async {
    await settings.setOpenStreakRemindersTime(time);
    await GoalNotifier.startOpenStreakReminder(time);
  }

  static Future<void> updateFrequency(
    AppSettings settings, {
    required String oldFrequency,
    required String newFrequency,
  }) async {
    await settings.setNotificationFrequency(newFrequency);
    await GoalNotifier.applyFrequencyChange(
      oldFrequency: oldFrequency,
      newFrequency: newFrequency,
    );
  }

  static Future<void> setPauseGoals(AppSettings settings, bool value) async {
    await settings.setPauseGoals(value);
    if (value) {
      await GoalNotifier.cancelAllGoalNotifications();
    }
  }

  static bool showsNotificationControls(String frequency) =>
      NotificationPreferenceOptions.isEnabled(frequency);
}
