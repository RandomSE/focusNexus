import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:timezone/timezone.dart' as tz;

import 'goal_notifier_action_window.dart' as action_window;
import 'goal_notifier_ai_encouragement.dart' as ai;
import 'goal_notifier_bindings.dart' as bindings;
import 'goal_notifier_cancellation.dart' as cancellation;
import 'goal_notifier_daily_affirmations.dart' as daily;
import 'goal_notifier_frequency.dart' as frequency;
import 'goal_notifier_goal_reminders.dart' as reminders;
import 'goal_notifier_ids.dart' as ids;
import 'goal_notifier_init.dart' as init;
import 'goal_notifier_permissions.dart' as permissions;
import 'goal_notifier_runtime.dart';
import 'goal_notifier_scheduling.dart' as scheduling;

class GoalNotifier {
  GoalNotifier._();

  /// Storage from [goalNotifierWiringProvider].
  static KeyValueStorage get storage => bindings.goalNotifierStorage();

  /// Called once per [ProviderScope] via [goalNotifierWiringProvider].
  static void bindStorage(KeyValueStorage storage) =>
      bindings.bindGoalNotifierStorage(storage);

  /// Test-only: restore defaults between tests.
  static void resetForTesting() => GoalNotifierRuntime.I.resetForTesting();

  /// Readable flags for unit tests (settings loaded from [storage]).
  static bool get isAiEncouragementEnabled => bindings.isAiEncouragementEnabled;

  static bool get isDailyAffirmationsEnabled =>
      bindings.isDailyAffirmationsEnabled;

  static Future<void> initialize() => init.initialize();

  static Future<void> refreshDailyAffirmationSchedules({
    bool forceReschedule = false,
  }) =>
      daily.refreshDailyAffirmationSchedules(forceReschedule: forceReschedule);

  static Future<void> checkAdditionalNotificationSettings() =>
      init.checkAdditionalNotificationSettings();

  static Future<void> checkAiEncouragement() => bindings.checkAiEncouragement();

  static Future<void> checkDailyAffirmations() =>
      bindings.checkDailyAffirmations();

  static Future<void> refreshSchedulesForFrequencyChange({
    required String oldFrequency,
    required String newFrequency,
  }) =>
      frequency.refreshSchedulesForFrequencyChange(
        oldFrequency: oldFrequency,
        newFrequency: newFrequency,
      );

  @visibleForTesting
  static void setDailyAffirmationsSchedulerForTesting(
    Future<void> Function(String time)? scheduler,
  ) =>
      frequency.setDailyAffirmationsSchedulerForTesting(scheduler);

  static Future<void> startGoalCheck(
    GoalSet goalSet,
    String notificationStyle,
    String notificationFrequency,
    int hoursToExpire,
  ) =>
      reminders.startGoalCheck(
        goalSet,
        notificationStyle,
        notificationFrequency,
        hoursToExpire,
      );

  static Future<void> scheduleActionWindowReminder({
    required GoalSet goal,
    required DateTime reminderAt,
    required String notificationStyle,
    required bool isStartReminder,
  }) =>
      action_window.scheduleActionWindowReminder(
        goal: goal,
        reminderAt: reminderAt,
        notificationStyle: notificationStyle,
        isStartReminder: isStartReminder,
      );

  @visibleForTesting
  static int dailyAffirmationNotificationIdForDay(int dayOffset) =>
      daily.dailyAffirmationNotificationIdForDay(dayOffset);

  static Future<void> startDailyAffirmations(String? timeToTrigger) =>
      daily.startDailyAffirmations(timeToTrigger);

  static Future<void> cancelGoalNotification(GoalSet goalSet) =>
      cancellation.cancelGoalNotification(goalSet);

  static Future<void> cancelAiEncouragementNotification(int goalId) =>
      cancellation.cancelAiEncouragementNotification(goalId);

  static Future<void> cancelDailyAffirmationsNotification() =>
      cancellation.cancelDailyAffirmationsNotification();

  static Future<void> cancelAllGoalNotifications() =>
      cancellation.cancelAllGoalNotifications();

  static Future<bool> areNotificationsEnabledByFrequency() =>
      permissions.areNotificationsEnabledByFrequency();

  static Future<void> requestNotificationPermission() =>
      permissions.requestNotificationPermission();

  static Future<bool> checkNotificationsPermissionsGranted() =>
      permissions.checkNotificationsPermissionsGranted();

  static Future<void> showInstantNotifications({
    required int id,
    required String title,
    required String body,
  }) =>
      scheduling.showInstantNotifications(id: id, title: title, body: body);

  static Future<void> scheduleReminder(
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
    String channelDescription,
  ) =>
      scheduling.scheduleReminder(
        id,
        title,
        body,
        scheduledTime,
        mode,
        summaryNotificationId,
        summaryTitle,
        summaryBody,
        groupKey,
        channelId,
        channelName,
        channelDescription,
      );

  @visibleForTesting
  static int summaryNotificationIdFor(int baseGroupId, DateTime triggerTime) =>
      scheduling.summaryNotificationIdFor(baseGroupId, triggerTime);

  static Future<void> scheduleSummaryNotification(
    DateTime triggerTime,
    AndroidScheduleMode mode,
    int id,
    String groupKey,
    String channelId,
    String channelName,
    String channelDescription,
    String title,
    String body,
  ) =>
      scheduling.scheduleSummaryNotification(
        triggerTime,
        mode,
        id,
        groupKey,
        channelId,
        channelName,
        channelDescription,
        title,
        body,
      );

  static Future<void> scheduleRepeatingGoalSummaryNotification(
    DateTime triggerTime,
    AndroidScheduleMode mode,
    String groupKey,
    String channelId,
    String channelName,
    String channelDescription,
    String title,
    String body,
  ) =>
      scheduling.scheduleRepeatingGoalSummaryNotification(
        triggerTime,
        mode,
        groupKey,
        channelId,
        channelName,
        channelDescription,
        title,
        body,
      );

  static Future<void> scheduleDailyAffirmations(
    tz.TZDateTime triggerTime,
    AndroidScheduleMode mode,
    String title,
    String body, {
    int? notificationId,
  }) =>
      scheduling.scheduleDailyAffirmations(
        triggerTime,
        mode,
        title,
        body,
        notificationId: notificationId,
      );

  static Future<AndroidScheduleMode> getScheduleMode() =>
      permissions.getScheduleMode();

  static int generateGoalId(String goalName) => ids.generateGoalId(goalName);

  static Duration getDurationFromSeconds(int seconds) =>
      ids.getDurationFromSeconds(seconds);

  static void setNow() => ids.setNow();

  static Future<void> openNotificationSettings() =>
      permissions.openNotificationSettings();

  static Future<String> getLocalTimezone() => permissions.getLocalTimezone();

  static int getScoreByTypeAndString(String type, String value) =>
      ai.getScoreByTypeAndString(type, value);

  static (int, List<String>, int) getEncouragementValue(GoalSet goalSet) =>
      ai.getEncouragementValue(goalSet);
}
