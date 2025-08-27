// lib/utils/notifier.dart

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class GoalNotifier {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Track active timers per goal
  static final Map<String, List<Timer>> _activeTimers = {};

  /// Initialize notifications plugin
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(InitializationSettings(android: androidSettings));

    _initialized = true;
    debugPrint('Notifications initialized.');
  }

  /// Schedule two notifications using delayed `show()`:
  ///   1) Heads-up after 30 seconds
  ///   2) Reminder 4 hours before deadline
  static Future<void> startGoalCheck(String goalName, int hoursToExpire) async {
    await initialize();

    debugPrint('$goalName is the name of the goal');

    final now = DateTime.now();
    final deadline = now.add(Duration(hours: hoursToExpire));
    final reminderTime = deadline.subtract(Duration(hours: 4));
    final initialDelay = Duration(seconds: 10);
    //final reminderDelay = reminderTime.difference(now);
    final reminderDelay = Duration(seconds: 45); // For testing TODO remove

    // Individual notification details
    final androidDetails = AndroidNotificationDetails(
      'goal_channel',
      'Goal Reminders',
      channelDescription: 'Notifications for upcoming goals',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: 'goal_group',
      setAsGroupSummary: false,
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    final timers = <Timer>[];

    // 1) Initial heads-up
    timers.add(Timer(initialDelay, () {
      _plugin.show(
        goalName.hashCode,
        'Goal Scheduled',
        'Your goal "$goalName" expires on ${_format(deadline)}.',
        platformDetails,
      );
      debugPrint('Initial notification shown.');
    }));

    // 2) Reminder — only if deadline is >4h away
    if (hoursToExpire > 4 && reminderDelay > Duration.zero) {
      timers.add(Timer(reminderDelay, () {
        _plugin.show(
          goalName.hashCode + 1,
          'Goal Reminder',
          'Reminder: "$goalName" is due in 4 hours!',
          platformDetails,
        );
        debugPrint('Reminder notification shown.');
      }));
    } else {
      debugPrint('Reminder skipped (deadline too close or past).');
    }

    // 3) Group summary notification (not cancellable per goal)
    final summaryDetails = AndroidNotificationDetails(
      'goal_channel',
      'Goal Reminders',
      channelDescription: 'Notifications for upcoming goals',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: 'goal_group',
      setAsGroupSummary: true,
    );
    final summaryPlatformDetails = NotificationDetails(android: summaryDetails);

    await _plugin.show(
      0,
      'Goal Updates',
      'You have active goal reminders.',
      summaryPlatformDetails,
    );


    _activeTimers[goalName] = timers;
  }

  /// Cancel notifications for a specific goal
  static Future<void> cancelGoalNotification(String goalName) async {
    debugPrint('$goalName is the name of the goal');

    await _plugin.cancel(goalName.hashCode);       // Initial
    await _plugin.cancel(goalName.hashCode + 1);   // Reminder

    if (_activeTimers.containsKey(goalName)) {
      for (final timer in _activeTimers[goalName]!) {
        timer.cancel();
      }
      _activeTimers.remove(goalName);
    }

    debugPrint('Notifications cancelled for goal: $goalName');
  }

  /// Request notification permission
  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      debugPrint('Notification permission not granted');
    }

    final isAllowed = await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();

    debugPrint('Notifications enabled: $isAllowed');
  }

  static String _format(DateTime dt) =>
      DateFormat('dd MMMM yyyy HH:mm').format(dt);
}
