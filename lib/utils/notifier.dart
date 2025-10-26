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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/classes/goal_set.dart';
import '../utils/text_utils.dart';
import 'common_utils.dart';

class GoalNotifier {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _platform = MethodChannel('flutter_native_timezone');
  static final _storage = const FlutterSecureStorage();

  // Track active timers per goal
  static final _encouragementThreshold = 6;
  static final Map<String, List<Timer>> _activeTimers = {};
  static final DateFormat _formatter = DateFormat('dd MMMM yyyy HH:mm');
  static var _now = tz.TZDateTime.now(tz.local);
  static var _mostRecentTimeGoal = DateTime.now().subtract(Duration(seconds: 10)); // Set in the past to ensure it's overwritten.
  static var _mostRecentTimeRepeatingGoal = DateTime.now().subtract(Duration(seconds: 10)); // Set in the past to ensure it's overwritten.
  static final _goalGroupId = 1;
  static final _goalRepeatingGroupId = 2;
  static final _aiEncouragementGroupId = 3;
  static final _dailyAffirmationsGroupId = 4;
  static bool _aiEncouragement = false;
  static bool _dailyAffirmations = false;
  static AndroidScheduleMode _scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle; // Fallback

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
        initializationSettings); // call to enable notifications

    _initialized = true;
    debugPrint('Notifications initialized.');
  }

  static Future<void> checkAdditionalNotificationSettings () async {
    await checkAiEncouragement();
    await checkDailyAffirmations();
    debugPrint('Notification additional settings confirmed. aiEncouragement: $_aiEncouragement, dailyAffirmations: $_dailyAffirmations');
  }

  static Future<void> checkAiEncouragement () async {
    String? aiEncouragementString = await _storage.read(key: 'aiEncouragement');
    _aiEncouragement = aiEncouragementString == 'true';

  }

  static Future<void> checkDailyAffirmations () async {
    String? dailyAffirmationsString = await _storage.read(key: 'dailyAffirmations');
    _dailyAffirmations = dailyAffirmationsString == 'true';
  }

  /// Schedule goal reminders.
  static Future<void> startGoalCheck(GoalSet goalSet, // pass in entire goalSet for any later additions to this method (e.g AI encouragement for tasks that need more energy to begin.)
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
    final twelveHourBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 12);
    final dayBeforeDeadline = CommonUtils.newTimeMinusHours(deadline, 24);

    // Shared reminder for Low, Medium & High frequency.
    if (fourHourBeforeDeadline.isAfter(_now)) {
      await scheduleReminder(goalId + 2, 'Goal Reminder', TextUtils.buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), fourHourBeforeDeadline, _scheduleMode, _goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
    }

    if (notificationFrequency == 'Medium' && dayBeforeDeadline.isAfter(_now)) {
      await scheduleReminder(goalId + 3, 'Goal Reminder', TextUtils.buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), dayBeforeDeadline, _scheduleMode, _goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
    }

    if (notificationFrequency == 'High') {
      if (oneHourBeforeDeadline.isAfter(_now)) {
        await scheduleReminder(goalId, 'Goal Reminder', TextUtils.buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), oneHourBeforeDeadline, _scheduleMode, _goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
      }
      
      if (twoHourBeforeDeadline.isAfter(_now)) {
        await scheduleReminder(goalId + 1, 'Goal Reminder', TextUtils.buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), twoHourBeforeDeadline, _scheduleMode, _goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
      }
      
      final totalDays = hoursToExpire ~/ 24;
      if (totalDays > 1) {
        for (int i = 1; i <= totalDays; i++) {
          final dailyTime = deadline.subtract(Duration(days: i));
          await scheduleReminder(goalId + 10 + i, 'Daily Goal Reminder', TextUtils.buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), dailyTime, _scheduleMode, _goalRepeatingGroupId, 'Daily Goal Reminders', 'Daily reminders for goals', 'daily_goal_group', 'Daily Goal Reminder', 'Daily Goal Reminders', 'Daily Reminders for goals');
        }
      }
      if (totalDays == 1 && hoursToExpire >24){
        await scheduleReminder(goalId + 3, 'Goal Reminder', TextUtils.buildFollowUpReminderMessage(goalName, goalId, notificationStyle, deadline), dayBeforeDeadline, _scheduleMode, _goalGroupId, 'Goal Reminders', 'Reminders for goals', 'goal_group', 'Goal Reminder', 'Goal Reminders', 'Reminders for goals');
      }
    }

    if (_aiEncouragement & (hoursToExpire > 24)) { // so it doesn't trigger unnecessarily if someone sets a deadline of say, 13 hours.
      final (score, reasons, biggest) = getEncouragementValue(goalSet);
      if (score >= _encouragementThreshold || biggest > 3) {
        // goalId + 4
        int timeScore = getScoreByTypeAndString('Time', goalSet.time.toString());
        int stepScore = getScoreByTypeAndString('Steps', goalSet.steps.toString());
        int complexityScore = getScoreByTypeAndString('Levels', goalSet.complexity);
        int effortScore = getScoreByTypeAndString('Levels', goalSet.effort);
        int motivationScore = getScoreByTypeAndString('Levels', goalSet.motivation);
        final message = TextUtils.buildEncouragementMessage(goalName, goalId, goalSet.deadline, reasons, score, biggest, timeScore, stepScore, complexityScore, effortScore, motivationScore, notificationStyle);
        await scheduleReminder(goalId + 4, 'AI encouragement', message, twelveHourBeforeDeadline, _scheduleMode, _aiEncouragementGroupId, 'AI encouragement', 'Encouragement for more intense goals', 'ai_encouragement_group', 'AI encouragement', 'AI encouragement', 'Encouragement for more intense goals');
      }
    }
  }

  static Future<void> startDailyAffirmations(String timeToTrigger) async {
    await initialize(); // ensure daily affirmations are enabled, and check scheduleMode
    final tz.TZDateTime? triggerTime = await CommonUtils.tzDateTimeFromHHmm(timeToTrigger);
    final String body = TextUtils.generateDailyAffirmationBody();


    if (triggerTime == null) {
      debugPrint('Invalid timeToTrigger: $timeToTrigger');
      return;
    }

    // build the body
    debugPrint('Started. Time to trigger: $triggerTime');

    scheduleDailyAffirmations(triggerTime, _scheduleMode, 'Daily Affirmations', body);
  }

  /// Cancel notifications for a specific goal. The group/summary notifications are not removed here, only by cancel all goals (a summary is only shown if there are at least 2 notifications in that group. So an empty summary is not an issue.)
  static Future<void> cancelGoalNotification(GoalSet goalSet) async {
    int goalId = goalSet.goalId;
    String goalName = goalSet.title;
    String deadline = goalSet.deadline;
    debugPrint('Cancelling notifications for goal: $goalName, goalID: $goalId');
    if (deadline != 'no deadline') { // when canceling goals without a deadline.
      final now = DateTime.now();
      final deadlineDate = _formatter.parse(deadline);
      final daysToExpire = deadlineDate
          .difference(now)
          .inDays;


      await _plugin.cancel(goalId); // 1-hour before - High
      await _plugin.cancel(goalId + 1); // 4-hours before - all
      await _plugin.cancel(goalId + 3); // 2-hours before - High

      if (daysToExpire > 0) {
        for (int i = 1; i <= daysToExpire; i++) {
          await _plugin.cancel(goalId + 10 + i);
        }
        await _plugin.cancel(goalId + 2); // 1 day before - medium, High
        await _plugin.cancel(goalId + 4); // 12-hours before, all -  AI encouragement
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
    await _plugin.cancel(goalId + 4); // 12-hours before, all -  AI encouragement
    debugPrint('AI encouragement for goal canceled due to step progress addition.');
  }

  static Future<void> cancelDailyAffirmationsNotification() async {
    await _plugin.cancel(_dailyAffirmationsGroupId);
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

    if(_dailyAffirmations) {
      final timeToTrigger = await _storage.read(key: 'dailyAffirmationsTime');
      await startDailyAffirmations(timeToTrigger!);
    }

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
      final status = await Permission.notification.status;
      final shouldShow = await Permission.notification.shouldShowRequestRationale;
      debugPrint('Status: $status. Should show: $shouldShow');
      debugPrint('Critical notification permissions not granted.');
      if (shouldShow) {
        return; // User denied notification - don't send request
      }
      else {
        await openNotificationSettings(); // User previously blocked notification popup, triggered again - Send to settings for request.
        return;
      }
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
    if (summaryNotificationId == _goalRepeatingGroupId) {
      await scheduleRepeatingGoalSummaryNotification(scheduledTime, mode, groupKey, channelId, channelName, channelDescription, summaryTitle, summaryBody);
      debugPrint('Daily reminder scheduled for $scheduledTime, goalId: $id');
    }
    else if (summaryNotificationId == _goalGroupId) {
      debugPrint('Reminder scheduled for $scheduledTime, goalId: $id');
      await scheduleSummaryNotification(scheduledTime, mode, summaryNotificationId, groupKey, channelId, channelName, channelDescription, summaryTitle, summaryBody);
    }
    else if (summaryNotificationId == _aiEncouragementGroupId) {
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
    debugPrint('Now: $_now. Trigger time: $triggerTime. Most recent time: $_mostRecentTimeGoal');
    if (triggerTime.isAfter(_mostRecentTimeGoal) &! _mostRecentTimeGoal.isBefore(_now)) { // triggerTime: passed in, e.g 10 seconds from now. mostRecentTimeGoal - 1 hour in the future.  if passed in time < mostRecent: set mostRecent to passed in time.
      debugPrint('A summary notification is already scheduled. No more will be scheduled currently.');
      return;
    }
    else if (_mostRecentTimeGoal.isAfter(triggerTime) || _mostRecentTimeGoal.isBefore(_now)) {
      _mostRecentTimeGoal = triggerTime;
      debugPrint('Updated summary trigger time to: $_mostRecentTimeGoal. Triggering summary at that time.');
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
    debugPrint('Now: $_now. Trigger time: $triggerTime. Most recent time: $_mostRecentTimeRepeatingGoal');
    if (triggerTime.isAfter(_mostRecentTimeRepeatingGoal) &! _mostRecentTimeRepeatingGoal.isBefore(_now)) {
      debugPrint('A repeating summary notification is already scheduled. No more will be scheduled currently.');
      return;
    }
    else if (_mostRecentTimeRepeatingGoal.isAfter(triggerTime) || _mostRecentTimeRepeatingGoal.isBefore(_now)) {
      _mostRecentTimeRepeatingGoal = triggerTime;
      debugPrint('Updated repeating summary trigger time to: $_mostRecentTimeRepeatingGoal. Triggering summary at that time.');
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
        _goalRepeatingGroupId,
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

  static Future<void> scheduleDailyAffirmations(tz.TZDateTime triggerTime, AndroidScheduleMode mode, String title, String body) async {
    AndroidNotificationDetails summaryDetails = AndroidNotificationDetails(
      'daily_affirmations_channel',
      'Daily Affirmations',
      channelDescription: 'Daily affirmations to improve your mood and stay motivated.',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: 'daily_affirmations', // doesn't need group summary since only 1 notification, done every day.
    );

    NotificationDetails summaryPlatformDetails = NotificationDetails(
      android: summaryDetails,
    );

    await _plugin.zonedSchedule(
      _dailyAffirmationsGroupId,
      title,
      body,
      triggerTime,
      summaryPlatformDetails,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
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
    int score = 0;

    if (type == 'Steps') {
      score = CommonUtils.scoreFromSteps(int.parse(value));
    }

    if (type == 'Time') {
      score = CommonUtils.scoreFromTime(int.parse(value));
    }

    else {
      score = CommonUtils.scoreFromLevel(value);
    }

    return score;
  }

  static (int, List<String>, int) getEncouragementValue(GoalSet goalSet) {
    final complexityScore = CommonUtils.scoreFromLevel(goalSet.complexity);
    final effortScore = CommonUtils.scoreFromLevel(goalSet.effort);
    final motivationScore = CommonUtils.scoreFromLevel(goalSet.motivation);
    final timeScore = CommonUtils.scoreFromTime(goalSet.time);
    final stepsScore = CommonUtils.scoreFromSteps(goalSet.steps);

    final totalScore = complexityScore + effortScore + motivationScore + timeScore + stepsScore;
    final biggestFactorScore = [
      complexityScore,
      effortScore,
      motivationScore,
      timeScore,
      stepsScore,
    ].reduce((a, b) => a > b ? a : b);

    final List<String> reasons = [];
    if (complexityScore > 0) reasons.add('This goal has a challenging complexity level.');
    if (effortScore > 0) reasons.add('It requires notable effort to complete.');
    if (motivationScore > 0) reasons.add('Staying motivated might be tough.');
    if (timeScore > 0) reasons.add('It spans a significant amount of time.');
    if (stepsScore > 0) reasons.add('It involves many steps to complete.');

    return (totalScore, reasons, biggestFactorScore);
  }
}
