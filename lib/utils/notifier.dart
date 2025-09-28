// lib/utils/notifier.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' as tz;

class GoalNotifier {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const platform = MethodChannel('flutter_native_timezone');

  // Track active timers per goal
  static final Map<String, List<Timer>> _activeTimers = {};
  static final DateFormat formatter = DateFormat('dd MMMM yyyy HH:mm');
  static var now = tz.TZDateTime.now(tz.local);
  static var mostRecentTimeGoal = DateTime.now().subtract(Duration(seconds: 10)); // Set in the past to ensure it's overwritten.
  static var mostRecentTimeRepeatingGoal = DateTime.now().subtract(Duration(seconds: 10)); // Set in the past to ensure it's overwritten.
  static final goalGroupId = 1;
  static final goalRepeatingGroupId = 2;
  static AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle; // Fallback

  /// Initialize notifications plugin
  static Future<void> initialize() async {
    if (_initialized) return;

    initializeTimeZones();
    scheduleMode = await getScheduleMode();

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
        initializationSettings); // call to enable notifications

    _initialized = true;
    debugPrint('Notifications initialized.');
  }

  /// Schedule goal reminders.
  static Future<void> startGoalCheck(String goalName,
      int hoursToExpire,
      int goalId,
      String notificationStyle,
      String notificationFrequency,
      // 'Low', 'Medium', 'High' - No notifications not factored in here as checked separately.
      ) async {

    now = tz.TZDateTime.now(tz.local);
    final deadline = now.add(Duration(hours: hoursToExpire));
    final oneHourBeforeDeadline = deadline.subtract(const Duration(hours: 1));
    final twoHourBeforeDeadline = deadline.subtract(const Duration(hours: 2));
    final fourHourBeforeDeadline = deadline.subtract(const Duration(hours: 4));
    final dayBeforeDeadline = deadline.subtract(const Duration(hours: 24));


    debugPrint('Notification frequency: $notificationFrequency');

    // Shared reminder for Low, Medium & High frequency.
    if (fourHourBeforeDeadline.isAfter(now)) {
      await scheduleReminder(goalId + 2, 'Goal Reminder', buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), fourHourBeforeDeadline, scheduleMode, goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
    }

    if (notificationFrequency == 'Medium' && dayBeforeDeadline.isAfter(now)) {
      await scheduleReminder(goalId + 3, 'Goal Reminder', buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), dayBeforeDeadline, scheduleMode, goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
    }

    if (notificationFrequency == 'High') {
      if (oneHourBeforeDeadline.isAfter(now)) {
        await scheduleReminder(goalId, 'Goal Reminder', buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), oneHourBeforeDeadline, scheduleMode, goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
      }
      
      if (twoHourBeforeDeadline.isAfter(now)) {
        await scheduleReminder(goalId + 1, 'Goal Reminder', buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), twoHourBeforeDeadline, scheduleMode, goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
      }
      
      final totalDays = hoursToExpire ~/ 24;
      if (totalDays > 1) {
        for (int i = 1; i <= totalDays; i++) {
          final dailyTime = deadline.subtract(Duration(days: i));
          await scheduleReminder(goalId + 3 + i, 'Daily Goal Reminder', buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), dailyTime, scheduleMode, goalRepeatingGroupId, 'Daily Goal Reminders', 'Daily reminders for goals', 'daily_goal_group', 'Daily Goal Reminder', 'Daily Goal Reminders', 'Daily Reminders for goals');
        }
      }
      if (totalDays == 1 && hoursToExpire >24){
        await scheduleReminder(goalId + 3, 'Goal Reminder', buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), dayBeforeDeadline, scheduleMode, goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
      }
    }
  }

  /// Cancel notifications for a specific goal
  static Future<void> cancelGoalNotification(int goalId, String goalName,
      String deadline) async {
    debugPrint('Cancelling notifications for goal: $goalName, goalID: $goalId');
    final now = DateTime.now();

    await _plugin.cancel(goalId); // 1-hour before - High
    await _plugin.cancel(goalId + 1); // 4-hour before - all
    await _plugin.cancel(goalId + 2); // 1 day before - medium, High
    await _plugin.cancel(goalId + 3); // 2-hours before - High

    final deadlineDate = formatter.parse(deadline);
    final daysToExpire = deadlineDate
        .difference(now)
        .inDays;

    if (daysToExpire > 0) {
      await _plugin.cancel(1); // group for all the daily notifications (High)
      for (int i = 1; i <= daysToExpire; i++) {
        await _plugin.cancel(goalId + 3 + i);
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

    debugPrint('All goal notifications and timers cancelled.');
  }


  /// Request notification permission
  static Future<void> requestNotificationPermission() async {
    // Request POST_NOTIFICATIONS (Android 13+)
    final statusNotification = await Permission.notification.request();

    // Request SCHEDULE_EXACT_ALARM (Android 12+)
    final statusExactAlarm = await Permission.scheduleExactAlarm.request();

    // Check if any critical permission is denied
    if (!statusNotification.isGranted || !statusExactAlarm.isGranted) {
      debugPrint('Critical notification permissions not granted.');
      return;
    }

    // Check if notifications are enabled in system settings
    final isAllowed = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
    }
    else {
      return false;
    }
  }


  static String _format(DateTime dt) =>
      DateFormat('dd MMMM yyyy HH:mm').format(dt);

  static String buildInitialReminderMessage(
    String goalName,
    String notificationStyle,
    DateTime deadline,
  ) {
    final formattedDeadline = _format(deadline);

    switch (notificationStyle) {
      case 'Vibrant':
        final messages = [
          '🔥 You’ve sparked something! "$goalName" is set for $formattedDeadline.',
          '🎯 Goal locked in: "$goalName" - due by $formattedDeadline.',
          '🌟 Bright beginning! "$goalName" is on track for $formattedDeadline.',
          '📆 Just added: "$goalName" - deadline is $formattedDeadline.',
          '🚀 Ready for lift-off: "$goalName" lands on $formattedDeadline.',
          '💡 Fresh start! "$goalName" is scheduled for $formattedDeadline.',
          '🎉 You’re on your way - "$goalName" wraps up by $formattedDeadline.',
          '📣 New goal alert: "$goalName" ends $formattedDeadline.',
          '⚡ Kickoff complete! "$goalName" is due $formattedDeadline.',
          '🌈 Let the journey begin - "$goalName" finishes by $formattedDeadline.',
        ];
        return messages[_randomIndex(messages.length)];

      case 'Animated':
        final messages = [
          'Just letting you know, "$goalName" is all set. Deadline’s $formattedDeadline.',
          '"$goalName" is officially on the books. Due by $formattedDeadline.',
          'Cool, "$goalName" is in motion. You’ve got until $formattedDeadline.',
          'Hey, "$goalName" was created. Deadline’s $formattedDeadline, just FYI.',
          'Alright, "$goalName" is live. You’ve got time $formattedDeadline’s the mark.',
          'No rush, just a heads-up. "$goalName" is due $formattedDeadline.',
          'You’ve added "$goalName". Deadline’s $formattedDeadline, in case you’re wondering.',
          'Nice, "$goalName" is saved. It wraps up on $formattedDeadline.',
          'Goal noted: "$goalName". Deadline’s $formattedDeadline, all chill.',
          'Just a quiet ping "$goalName" is set with a deadline of $formattedDeadline.',
        ];
        return messages[_randomIndex(messages.length)];

      case 'Minimal':
      default:
        return 'Your goal "$goalName" expires on $formattedDeadline.';
    }
  }

  static String buildFollowUpReminderMessage(
    String goalName,
    int goalId,
    String notificationStyle,
    DateTime deadline,
  ) {
    final formattedDeadline = _format(deadline);

    if (notificationStyle == 'Minimal') {
      return '"$goalName / Id: $goalId" is due $formattedDeadline.';
    }

    if (notificationStyle == 'Vibrant') {
      final messages = [
        'Reminder - "$goalName / Id: $goalId" is closing in. Deadline is $formattedDeadline.',
        'Heads up. "$goalName / Id: $goalId" wraps up by $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is almost there. Due $formattedDeadline.',
        '"$goalName / Id: $goalId" is reaching its finish line. Deadline is $formattedDeadline.',
        'Quick check-in. "$goalName / Id: $goalId" ends $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is on the final stretch. Deadline is $formattedDeadline.',
        '"$goalName / Id: $goalId" is counting down. Due $formattedDeadline.',
        'Time’s ticking. "$goalName" closes $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is nearly done. Deadline is $formattedDeadline.',
        'Just a flash reminder. "$goalName / Id: $goalId" finishes $formattedDeadline.',
      ];
      return messages[_randomIndex(messages.length)];
    }

    if (notificationStyle == 'Animated') {
      final messages = [
        'Hey again. "$goalName / Id: $goalId" is still hanging out. Deadline is $formattedDeadline.',
        'Just checking in. "$goalName / Id: $goalId" is due $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is inching closer to $formattedDeadline.',
        'Still time. "$goalName / Id: $goalId" wraps up $formattedDeadline.',
        'Friendly ping. "$goalName / Id: $goalId" is due $formattedDeadline.',
        'You’re doing great. "$goalName / Id: $goalId" finishes $formattedDeadline.',
        'Reminder - "$goalName / Id: $goalId" is quietly approaching $formattedDeadline.',
        'Just keeping you posted. "$goalName / Id: $goalId" ends $formattedDeadline.',
        'Almost there. "$goalName / Id: $goalId" is due $formattedDeadline.',
        'Reminder vibes. "$goalName / Id: $goalId" deadline is $formattedDeadline.',
      ];
      return messages[_randomIndex(messages.length)];
    }

    // Fallback
    return 'Reminder: "$goalName / Id: $goalId" is due $formattedDeadline.';
  }

  static Future<void> showInstantNotifications({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notification_channel',
          'Instant Notifications',
          channelDescription: 'Instant Notification channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleReminder(int id, String title, String body, DateTime scheduledTime, AndroidScheduleMode mode, int summaryNotificationId, String summaryTitle,
     String summaryBody, String groupKey, String channelId, String channelName, String channelDescription) async {
    if (summaryNotificationId == 2) {
      await scheduleRepeatingGoalSummaryNotification(scheduledTime, mode, groupKey, channelId, channelName, channelDescription, summaryTitle, summaryBody);
      debugPrint('Daily reminder scheduled for $scheduledTime, goalId: $id');
    }
    else {
      debugPrint('Reminder scheduled for $scheduledTime, goalId: $id');
      await scheduleSummaryNotification(scheduledTime, mode, summaryNotificationId, groupKey, channelId, channelName, channelDescription, summaryTitle, summaryBody);
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: false,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: mode,
    );
  }

  static Future<void> scheduleSummaryNotification(DateTime triggerTime, AndroidScheduleMode mode, int id, String groupKey, String channelId, String channelName, String channelDescription, String title, String body) async {
    setNow();
    debugPrint('Now: $now. Trigger time: $triggerTime. Most recent time: $mostRecentTimeGoal');
    if (triggerTime.isAfter(mostRecentTimeGoal) &! mostRecentTimeGoal.isBefore(now)) { // triggerTime: passed in, e.g 10 seconds from now. mostRecentTimeGoal - 1 hour in the future.  if passed in time < mostRecent: set mostRecent to passed in time.
      debugPrint('A summary notification is already scheduled. No more will be scheduled currently.');
      return;
    }
    else if (mostRecentTimeGoal.isAfter(triggerTime) || mostRecentTimeGoal.isBefore(now)) {
      mostRecentTimeGoal = triggerTime;
      debugPrint('Updated summary trigger time to: $mostRecentTimeGoal. Triggering summary at that time.');
      AndroidNotificationDetails summaryDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: true,
      );

      NotificationDetails summaryPlatformDetails = NotificationDetails(
        android: summaryDetails,
      );

      debugPrint(summaryDetails.toString());

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(triggerTime, tz.local),
        summaryPlatformDetails,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('summary notification sent.');
    }
  }

  static Future<void> scheduleRepeatingGoalSummaryNotification(DateTime triggerTime, AndroidScheduleMode mode, String groupKey, String channelId, String channelName, String channelDescription, String title, String body) async {
    setNow();
    debugPrint('Now: $now. Trigger time: $triggerTime. Most recent time: $mostRecentTimeRepeatingGoal');
    if (triggerTime.isAfter(mostRecentTimeRepeatingGoal) &! mostRecentTimeRepeatingGoal.isBefore(now)) {
      debugPrint('A repeating summary notification is already scheduled. No more will be scheduled currently.');
      return;
    }
    else if (mostRecentTimeRepeatingGoal.isAfter(triggerTime) || mostRecentTimeRepeatingGoal.isBefore(now)) {
      mostRecentTimeRepeatingGoal = triggerTime;
      debugPrint('Updated repeating summary trigger time to: $mostRecentTimeRepeatingGoal. Triggering summary at that time.');
      AndroidNotificationDetails summaryDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: true,
      );

      NotificationDetails summaryPlatformDetails = NotificationDetails(
        android: summaryDetails,
      );

      await _plugin.zonedSchedule(
        goalRepeatingGroupId,
        title,
        body,
        tz.TZDateTime.from(triggerTime, tz.local),
        summaryPlatformDetails,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('summary notification sent.');
    }
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

  static int _randomIndex(int length) {
    final random = Random();
    return random.nextInt(length);
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
    now = tz.TZDateTime.now(tz.local);
  }

  static Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }

  static Future<String> getLocalTimezone() async {
    try {
      final timezone = await platform.invokeMethod<String>('getLocalTimezone');
      return timezone ?? 'America/Chicago';
    } catch (e) {
      return 'America/Chicago';
    }
  }
}
