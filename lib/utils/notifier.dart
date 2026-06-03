// lib/utils/notifier.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:focusNexus/services/storage/flutter_secure_key_value_storage.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../models/classes/goal_set.dart';
import '../utils/text_utils.dart';
import 'affirmation_selector.dart';
import 'common_utils.dart';
import 'goal_notification_android.dart';
import 'notification_schedule_utils.dart';
import 'theme_styles.dart';

class GoalNotifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _platform = MethodChannel('flutter_native_timezone');
  static KeyValueStorage storage = const FlutterSecureKeyValueStorage();

  /// Test-only: restore defaults between tests.
  static void resetForTesting() {
    storage = const FlutterSecureKeyValueStorage();
    _initialized = false;
    _aiEncouragement = false;
    _dailyAffirmations = false;
    _dailyAffirmationsSchedulerForTesting = null;
    _activeTimers.clear();
  }

  // Track active timers per goal
  static final _encouragementThreshold = 6;
  static const _aiEncouragementSlotOffsets = [4, 50, 51, 52];
  static final Map<String, List<Timer>> _activeTimers = {};
  static final DateFormat _formatter = DateFormat('dd MMMM yyyy HH:mm');
  static var _now = tz.TZDateTime.now(tz.local);
  static final _goalGroupId = 1;
  static final _goalRepeatingGroupId = 2;
  static final _aiEncouragementGroupId = 3;
  static final _dailyAffirmationsGroupId = 4;

  /// Legacy repeating id; kept for cancel compatibility.
  static const _dailyAffirmationsScheduleBaseId = 500000;
  static int get _dailyAffirmationsHorizonDays =>
      NotificationScheduleUtils.affirmationHorizonDays;
  static bool _aiEncouragement = false;
  static bool _dailyAffirmations = false;
  static Future<void> Function(String time)?
  _dailyAffirmationsSchedulerForTesting;
  static AndroidScheduleMode _scheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle; // Fallback

  /// Readable flags for unit tests (settings loaded from [storage]).
  static bool get isAiEncouragementEnabled => _aiEncouragement;
  static bool get isDailyAffirmationsEnabled => _dailyAffirmations;

  /// Initialize notifications plugin
  static Future<void> initialize() async {
    await checkAdditionalNotificationSettings(); // Check each time. if they change settings, should apply before any notifications are sent / not sent
    if (_initialized) return;

    initializeTimeZones();
    _scheduleMode = await getScheduleMode();

    try {
      final String currentTimeZone = await getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugPrint('Timezone set to $currentTimeZone');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('America/Chicago')); // fallback
      debugPrint(
        'Unable to get timezone. Set to America/Chicago (notifications will be scheduled at  unexpected times.)',
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initializationSettings,
    ); // call to enable notifications

    _initialized = true;
    debugPrint('Notifications initialized.');
    await refreshDailyAffirmationSchedules();
  }

  /// Extends or rebuilds daily affirmation schedules when runway is low.
  static Future<void> refreshDailyAffirmationSchedules({
    bool forceReschedule = false,
  }) async {
    if (!_dailyAffirmations || !await areNotificationsEnabledByFrequency()) {
      return;
    }

    final storedTime = await storage.read(
      key: StorageKeys.dailyAffirmationsTime,
    );
    final effectiveTime = NotificationScheduleUtils.normalizeHHmm(storedTime);
    final scheduledUntilRaw = await storage.read(
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

  static Future<void> checkAdditionalNotificationSettings() async {
    await checkAiEncouragement();
    await checkDailyAffirmations();
    debugPrint(
      'Notification additional settings confirmed. aiEncouragement: $_aiEncouragement, dailyAffirmations: $_dailyAffirmations',
    );
  }

  static Future<void> checkAiEncouragement() async {
    String? aiEncouragementString = await storage.read(key: 'aiEncouragement');
    _aiEncouragement = aiEncouragementString == 'true';
  }

  static Future<void> checkDailyAffirmations() async {
    String? dailyAffirmationsString = await storage.read(
      key: 'dailyAffirmations',
    );
    _dailyAffirmations = dailyAffirmationsString == 'true';
  }

  /// Re-applies schedules affected by a frequency transition.
  ///
  /// When frequency moves from disabled (`No notifications`) to an enabled
  /// value, daily affirmations must be restored if that setting is enabled.
  static Future<void> refreshSchedulesForFrequencyChange({
    required String oldFrequency,
    required String newFrequency,
  }) async {
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
    if (!_dailyAffirmations) {
      debugPrint(
        'Skipped daily affirmations refresh after frequency re-enable: setting disabled.',
      );
      return;
    }

    final storedTime = await storage.read(
      key: StorageKeys.dailyAffirmationsTime,
    );
    final normalizedTime = (storedTime ?? '').trim();
    final effectiveTime = normalizedTime.isEmpty ? '06:00' : normalizedTime;
    await _scheduleDailyAffirmationsAfterFrequencyEnable(effectiveTime);
  }

  static Future<void> _scheduleDailyAffirmationsAfterFrequencyEnable(
    String time,
  ) async {
    final scheduler = _dailyAffirmationsSchedulerForTesting;
    if (scheduler != null) {
      await scheduler(time);
      return;
    }
    await startDailyAffirmations(time);
  }

  @visibleForTesting
  static void setDailyAffirmationsSchedulerForTesting(
    Future<void> Function(String time)? scheduler,
  ) {
    _dailyAffirmationsSchedulerForTesting = scheduler;
  }

  /// Schedule goal reminders.
  static Future<void> startGoalCheck(
    GoalSet
    goalSet, // pass in entire goalSet for any later additions to this method (e.g AI encouragement for tasks that need more energy to begin.)
    String notificationStyle,
    String notificationFrequency,
    int hoursToExpire,
  ) async {
    String goalName = goalSet.title;
    int goalId = goalSet.goalId;
    _now = tz.TZDateTime.now(tz.local);
    final deadline = _now.add(Duration(hours: hoursToExpire));
    final oneHourBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 1);
    final twoHourBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 2);
    final fourHourBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 4);
    final dayBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 24);

    // Shared reminder for Low, Medium & High frequency.
    if (fourHourBeforeDeadline.isAfter(_now)) {
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
        _scheduleMode,
        _goalGroupId,
        'Goal Reminders',
        'Reminders for goals',
        'goal_group',
        'Goal Reminder',
        'Goal Reminders',
        'Reminders for goals',
      );
    }

    if (notificationFrequency == 'Medium' && dayBeforeDeadline.isAfter(_now)) {
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
        _scheduleMode,
        _goalGroupId,
        'Goal Reminders',
        'Reminders for goals',
        'goal_group',
        'Goal Reminder',
        'Goal Reminders',
        'Reminders for goals',
      );
    }

    if (notificationFrequency == 'High') {
      if (oneHourBeforeDeadline.isAfter(_now)) {
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
          _scheduleMode,
          _goalGroupId,
          'Goal Reminders',
          'Reminders for goals',
          'goal_group',
          'Goal Reminder',
          'Goal Reminders',
          'Reminders for goals',
        );
      }

      if (twoHourBeforeDeadline.isAfter(_now)) {
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
          _scheduleMode,
          _goalGroupId,
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
          if (!dailyTime.isAfter(_now)) continue;
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
            _scheduleMode,
            _goalRepeatingGroupId,
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
          dayBeforeDeadline.isAfter(_now)) {
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
          _scheduleMode,
          _goalGroupId,
          'Goal Reminders',
          'Reminders for goals',
          'goal_group',
          'Goal Reminder',
          'Goal Reminders',
          'Reminders for goals',
        );
      }
    }

    if (_aiEncouragement && hoursToExpire > 6) {
      await _scheduleAiEncouragementSuite(
        goalSet: goalSet,
        goalName: goalName,
        goalId: goalId,
        notificationStyle: notificationStyle,
        now: _now,
        deadline: deadline,
        hoursToExpire: hoursToExpire,
      );
    }
  }

  /// Check-ins for demanding goals: early nudge, midpoint, and pre-deadline support.
  static Future<void> _scheduleAiEncouragementSuite({
    required GoalSet goalSet,
    required String goalName,
    required int goalId,
    required String notificationStyle,
    required tz.TZDateTime now,
    required tz.TZDateTime deadline,
    required int hoursToExpire,
  }) async {
    final (score, reasons, biggest) = getEncouragementValue(goalSet);
    if (score < _encouragementThreshold && biggest <= 3) {
      return;
    }

    final timeScore = getScoreByTypeAndString('Time', goalSet.time.toString());
    final stepScore = getScoreByTypeAndString(
      'Steps',
      goalSet.steps.toString(),
    );
    final complexityScore = getScoreByTypeAndString(
      'Levels',
      goalSet.complexity,
    );
    final effortScore = getScoreByTypeAndString('Levels', goalSet.effort);
    final motivationScore = getScoreByTypeAndString(
      'Levels',
      goalSet.motivation,
    );

    final triggers = <DateTime>{
      now.add(const Duration(hours: 2)),
      now.add(Duration(hours: hoursToExpire ~/ 2)),
      deadline.subtract(const Duration(hours: 12)),
    }..removeWhere((time) => !time.isAfter(now) || !time.isBefore(deadline));

    final sortedTriggers = <DateTime>[];
    for (final candidate in (triggers.toList()..sort())) {
      if (sortedTriggers.isEmpty ||
          candidate.difference(sortedTriggers.last).inMinutes.abs() >= 30) {
        sortedTriggers.add(candidate);
      }
    }

    for (var i = 0; i < sortedTriggers.length && i < 3; i++) {
      final trigger = sortedTriggers[i];
      final message = TextUtils.buildEncouragementMessage(
        goalName,
        goalId,
        goalSet.deadline,
        reasons,
        score,
        biggest,
        timeScore,
        stepScore,
        complexityScore,
        effortScore,
        motivationScore,
        notificationStyle,
        phase: i,
      );
      await scheduleReminder(
        goalId + _aiEncouragementSlotOffsets[i],
        'AI encouragement',
        message,
        trigger,
        _scheduleMode,
        _aiEncouragementGroupId,
        'AI encouragement',
        'Encouragement for more intense goals',
        'ai_encouragement_group',
        'AI encouragement',
        'AI encouragement',
        'Encouragement for more intense goals',
      );
    }
  }

  @visibleForTesting
  static int dailyAffirmationNotificationIdForDay(int dayOffset) =>
      _dailyAffirmationsScheduleBaseId + dayOffset;

  static Future<void> startDailyAffirmations(String? timeToTrigger) async {
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

    final styleRaw = await storage.read(key: StorageKeys.notificationStyle);
    final notificationStyle =
        (styleRaw ?? 'Minimal').trim().isEmpty ? 'Minimal' : styleRaw!.trim();

    await cancelDailyAffirmationsNotification();

    final triggers = NotificationScheduleUtils.dailyTriggersFrom(
      firstTrigger: firstTrigger,
      days: _dailyAffirmationsHorizonDays,
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
        _scheduleMode,
        'Daily Affirmations',
        body,
        notificationId: dailyAffirmationNotificationIdForDay(day),
      );
      scheduledCount++;
    }

    if (scheduledCount > 0) {
      final lastDay = triggers.last;
      await storage.write(
        key: StorageKeys.dailyAffirmationsScheduledUntil,
        value: NotificationScheduleUtils.formatDateKey(
          DateTime(lastDay.year, lastDay.month, lastDay.day),
        ),
      );
    }

    debugPrint('Scheduled $scheduledCount daily affirmation notifications.');
  }

  /// Cancel notifications for a specific goal. The group/summary notifications are not removed here, only by cancel all goals (a summary is only shown if there are at least 2 notifications in that group. So an empty summary is not an issue.)
  static Future<void> cancelGoalNotification(GoalSet goalSet) async {
    int goalId = goalSet.goalId;
    String goalName = goalSet.title;
    String deadline = goalSet.deadline;
    debugPrint('Cancelling notifications for goal: $goalName, goalID: $goalId');
    if (deadline != 'no deadline') {
      // when canceling goals without a deadline.
      final now = DateTime.now();
      final deadlineDate = _formatter.parse(deadline);
      final daysToExpire = deadlineDate.difference(now).inDays;

      await _plugin.cancel(goalId); // 1-hour before - High
      await _plugin.cancel(goalId + 1); // 4-hours before - all
      await _plugin.cancel(goalId + 3); // 2-hours before - High

      if (daysToExpire > 0) {
        for (int i = 1; i <= daysToExpire; i++) {
          await _plugin.cancel(goalId + 10 + i);
        }
        await _plugin.cancel(goalId + 2); // 1 day before - medium, High
        for (final offset in _aiEncouragementSlotOffsets) {
          await _plugin.cancel(goalId + offset);
        }
      }
    }

    // Cancel any active timers
    if (_activeTimers.containsKey(goalName)) {
      for (final timer in _activeTimers[goalName]!) {
        timer.cancel();
      }
      _activeTimers.remove(goalName);
    }

    debugPrint('Notifications cancelled for goal: $goalName');
  }

  static Future<void> cancelAiEncouragementNotification(int goalId) async {
    for (final offset in _aiEncouragementSlotOffsets) {
      await _plugin.cancel(goalId + offset);
    }
    debugPrint(
      'AI encouragement for goal canceled due to step progress addition.',
    );
  }

  static Future<void> cancelDailyAffirmationsNotification() async {
    final cancelOps = <Future<void>>[
      _plugin.cancel(_dailyAffirmationsGroupId),
      for (var day = 0; day < _dailyAffirmationsHorizonDays; day++)
        _plugin.cancel(dailyAffirmationNotificationIdForDay(day)),
    ];
    await Future.wait(cancelOps);
    await storage.delete(key: StorageKeys.dailyAffirmationsScheduledUntil);
    debugPrint('Daily affirmations canceled.');
  }

  /// Cancel all notifications and timers indiscriminately
  static Future<void> cancelAllGoalNotifications() async {
    debugPrint('Cancelling all goal-related notifications and timers…');

    // Cancel all scheduled notifications
    await _plugin.cancelAll();

    // Cancel all active timers
    for (final entry in _activeTimers.entries) {
      for (final timer in entry.value) {
        timer.cancel();
      }
    }
    _activeTimers.clear();

    if (_dailyAffirmations && await areNotificationsEnabledByFrequency()) {
      final timeToTrigger = await storage.read(
        key: StorageKeys.dailyAffirmationsTime,
      );
      final fallbackTime = '06:00';
      final effectiveTime =
          (timeToTrigger != null && timeToTrigger.trim().isNotEmpty)
              ? timeToTrigger
              : fallbackTime;
      await startDailyAffirmations(effectiveTime);
    }

    debugPrint('All goal notifications and timers cancelled.');
  }

  static Future<bool> areNotificationsEnabledByFrequency() async {
    final frequencyRaw = await storage.read(
      key: StorageKeys.notificationFrequency,
    );
    final frequency = (frequencyRaw ?? '').trim();
    return ThemeStyles.notificationsEnabledForFrequency(frequency);
  }

  /// Request notification permission
  static Future<void> requestNotificationPermission() async {
    // Request POST_NOTIFICATIONS (Android 13+)
    final statusNotification = await Permission.notification.request();

    // Request SCHEDULE_EXACT_ALARM (Android 12+)
    final statusExactAlarm = await Permission.scheduleExactAlarm.request();

    // Check if any critical permission is denied
    if (!statusNotification.isGranted || !statusExactAlarm.isGranted) {
      final status = await Permission.notification.status;
      final shouldShow =
          await Permission.notification.shouldShowRequestRationale;
      debugPrint('Status: $status. Should show: $shouldShow');
      debugPrint('Critical notification permissions not granted.');
      if (shouldShow) {
        return; // User denied notification - don't send request
      } else {
        await openNotificationSettings(); // User previously blocked notification popup, triggered again - Send to settings for request.
        return;
      }
    }

    // Check if notifications are enabled in system settings
    final isAllowed =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();

    if (isAllowed == false) {
      debugPrint('Notifications are disabled in system settings.');
      await openNotificationSettings();
    } else {
      debugPrint('Notifications fully enabled.');
    }
  }

  static Future<bool> checkNotificationsPermissionsGranted() async {
    final statusNotification = await Permission.notification.status;
    final statusExactAlarm = await Permission.scheduleExactAlarm.status;
    if (statusNotification.isGranted && statusExactAlarm.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> showInstantNotifications({
    required int id,
    required String title,
    required String body,
  }) async {
    final preview = GoalNotificationAndroid.collapsedPreview(body);
    await _plugin.show(
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
  ) async {
    if (summaryNotificationId == _goalRepeatingGroupId) {
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
    } else if (summaryNotificationId == _goalGroupId) {
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
    } else if (summaryNotificationId == _aiEncouragementGroupId) {
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
    await _plugin.zonedSchedule(
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
    );
  }

  @visibleForTesting
  static int summaryNotificationIdFor(int baseGroupId, DateTime triggerTime) {
    final minuteBucket = triggerTime.millisecondsSinceEpoch ~/ 60000;
    return baseGroupId * 100000 + (minuteBucket % 99999);
  }

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
  ) async {
    setNow();
    if (!triggerTime.isAfter(_now)) {
      return;
    }

    final summaryId = summaryNotificationIdFor(id, triggerTime);
    final preview = GoalNotificationAndroid.collapsedPreview(body);

    await _plugin.zonedSchedule(
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

  static Future<void> scheduleRepeatingGoalSummaryNotification(
    DateTime triggerTime,
    AndroidScheduleMode mode,
    String groupKey,
    String channelId,
    String channelName,
    String channelDescription,
    String title,
    String body,
  ) async {
    setNow();
    if (!triggerTime.isAfter(_now)) {
      return;
    }

    final summaryId = summaryNotificationIdFor(
      _goalRepeatingGroupId,
      triggerTime,
    );
    final preview = GoalNotificationAndroid.collapsedPreview(body);

    await _plugin.zonedSchedule(
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

  static Future<void> scheduleDailyAffirmations(
    tz.TZDateTime triggerTime,
    AndroidScheduleMode mode,
    String title,
    String body, {
    int? notificationId,
  }) async {
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

    await _plugin.zonedSchedule(
      notificationId ?? _dailyAffirmationsGroupId,
      title,
      preview,
      triggerTime,
      platformDetails,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<AndroidScheduleMode> getScheduleMode() async {
    final status = await Permission.scheduleExactAlarm.status;

    if (status.isGranted) {
      debugPrint('Exact alarm permission granted.');
      return AndroidScheduleMode.exactAllowWhileIdle;
    } else {
      debugPrint('Exact alarm permission not granted. Using inexact mode.');
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  static int generateGoalId(String goalName) {
    final random = Random();
    final randomPart = random.nextInt(100000);
    final hashPart = goalName.hashCode.abs();

    // Combine safely within 32-bit int range
    final combined = (hashPart % 1000000) * 100000 + randomPart;
    return combined & 0x7FFFFFFF;
  }

  static Duration getDurationFromSeconds(int seconds) {
    return Duration(seconds: seconds);
  }

  static void setNow() {
    _now = tz.TZDateTime.now(tz.local);
  }

  static Future<void> openNotificationSettings() async {
    try {
      await _platform.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }

  static Future<String> getLocalTimezone() async {
    try {
      final timezone = await _platform.invokeMethod<String>('getLocalTimezone');
      return timezone ?? 'America/Chicago';
    } catch (e) {
      return 'America/Chicago';
    }
  }

  static int getScoreByTypeAndString(String type, String value) {
    if (type == 'Steps') {
      return CommonUtils.scoreFromSteps(int.parse(value));
    }
    if (type == 'Time') {
      return CommonUtils.scoreFromTime(int.parse(value));
    }
    return CommonUtils.scoreFromLevel(value);
  }

  static (int, List<String>, int) getEncouragementValue(GoalSet goalSet) {
    final complexityScore = CommonUtils.scoreFromLevel(goalSet.complexity);
    final effortScore = CommonUtils.scoreFromLevel(goalSet.effort);
    final motivationScore = CommonUtils.scoreFromLevel(goalSet.motivation);
    final timeScore = CommonUtils.scoreFromTime(goalSet.time);
    final stepsScore = CommonUtils.scoreFromSteps(goalSet.steps);

    final totalScore =
        complexityScore +
        effortScore +
        motivationScore +
        timeScore +
        stepsScore;
    final biggestFactorScore = [
      complexityScore,
      effortScore,
      motivationScore,
      timeScore,
      stepsScore,
    ].reduce((a, b) => a > b ? a : b);

    final List<String> reasons = [];
    if (complexityScore > 0) {
      reasons.add('This goal has a challenging complexity level.');
    }
    if (effortScore > 0) {
      reasons.add('It requires notable effort to complete.');
    }
    if (motivationScore > 0) {
      reasons.add('Staying motivated might be tough.');
    }
    if (timeScore > 0) {
      reasons.add('It spans a significant amount of time.');
    }
    if (stepsScore > 0) {
      reasons.add('It involves many steps to complete.');
    }

    return (totalScore, reasons, biggestFactorScore);
  }
}
