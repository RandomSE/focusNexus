// lib/utils/notifier.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoalNotifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  final _storage = const FlutterSecureStorage();

  // Track active timers per goal
  static final Map<String, List<Timer>> _activeTimers = {};

  /// Initialize notifications plugin
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(InitializationSettings(android: androidSettings));

    _initialized = true;
    debugPrint('Notifications initialized.');
  }

  /// Schedule two notifications using delayed `show()`:
  ///   1) Heads-up after 30 seconds
  ///   2) Reminder 4 hours before deadline
  static Future<void> startGoalCheck(
      String goalName,
      int hoursToExpire,
      String notificationStyle,
      String notificationFrequency, // 'Low', 'Medium', 'High' - ignoring no notifications as this wouldn't be called with that.
      ) async {
    await initialize();

    final now = DateTime.now();
    final deadline = now.add(Duration(hours: hoursToExpire));
    final timers = <Timer>[];

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

    // 1) Initial heads-up
    timers.add(
      Timer(const Duration(seconds: 10), () {
        _plugin.show(
          goalName.hashCode,
          'Goal Scheduled',
          buildInitialReminderMessage(goalName, notificationStyle, deadline),
          platformDetails,
        );
        debugPrint('Initial notification shown.');
      }),
    );

    // 2) Frequency-based reminders
    if (notificationFrequency == 'Low') {
      // 4h before
      final reminderTime = deadline.subtract(const Duration(hours: 4));
      final delay = reminderTime.difference(now);
      if (delay > Duration.zero) {
        timers.add(
          Timer(delay, () {
            _plugin.show(
              goalName.hashCode + 1,
              'Goal Reminder',
              buildFollowUpReminderMessage(goalName, 1, notificationStyle, deadline),
              platformDetails,
            );
            debugPrint('Low frequency reminder shown.');
          }),
        );
      }
    }

    if (notificationFrequency == 'Medium') {
      // 24h before + 4h before
      final dayBefore = deadline.subtract(const Duration(hours: 24));
      final fourBefore = deadline.subtract(const Duration(hours: 4));

      final dayDelay = dayBefore.difference(now);
      final fourDelay = fourBefore.difference(now);

      if (dayDelay > Duration.zero) {
        timers.add(
          Timer(dayDelay, () {
            _plugin.show(
              goalName.hashCode + 2,
              'Goal Reminder',
              buildFollowUpReminderMessage(goalName, 1, notificationStyle, deadline),
              platformDetails,
            );
            debugPrint('Medium frequency (24h) reminder shown.');
          }),
        );
      }

      if (fourDelay > Duration.zero) {
        timers.add(
          Timer(fourDelay, () {
            _plugin.show(
              goalName.hashCode + 3,
              'Goal Reminder',
              buildFollowUpReminderMessage(goalName, 2, notificationStyle, deadline),
              platformDetails,
            );
            debugPrint('Medium frequency (4h) reminder shown.');
          }),
        );
      }
    }

    if (notificationFrequency == 'High') {
      // Daily reminders at same hour as deadline + 4h + 2h before
      final deadlineHour = deadline.hour;
      final nowHour = now.hour;

      // Daily reminders until deadline
      for (int i = 1; i <= hoursToExpire ~/ 24; i++) {
        final dailyTime = now.add(Duration(days: i));
        final dailyReminder = DateTime(
          dailyTime.year,
          dailyTime.month,
          dailyTime.day,
          deadlineHour,
        );
        final delay = dailyReminder.difference(now);
        if (delay > Duration.zero) {
          timers.add(
            Timer(delay, () {
              _plugin.show(
                goalName.hashCode + 10 + i,
                'Goal Reminder',
                buildFollowUpReminderMessage(goalName, i, notificationStyle, deadline),
                platformDetails,
              );
              debugPrint('High frequency daily reminder #$i shown.');
            }),
          );
        }
      }

      // 4h and 2h before deadline
      final fourBefore = deadline.subtract(const Duration(hours: 4));
      final twoBefore = deadline.subtract(const Duration(hours: 2));

      final fourDelay = fourBefore.difference(now);
      final twoDelay = twoBefore.difference(now);

      if (fourDelay > Duration.zero) {
        timers.add(
          Timer(fourDelay, () {
            _plugin.show(
              goalName.hashCode + 100,
              'Goal Reminder',
              buildFollowUpReminderMessage(goalName, 99, notificationStyle, deadline),
              platformDetails,
            );
            debugPrint('High frequency (4h) reminder shown.');
          }),
        );
      }

      if (twoDelay > Duration.zero) {
        timers.add(
          Timer(twoDelay, () {
            _plugin.show(
              goalName.hashCode + 101,
              'Goal Reminder',
              buildFollowUpReminderMessage(goalName, 100, notificationStyle, deadline),
              platformDetails,
            );
            debugPrint('High frequency (2h) reminder shown.');
          }),
        );
      }
    }

    // 3) Group summary
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

    await _plugin.cancel(goalName.hashCode); // Initial
    await _plugin.cancel(goalName.hashCode + 1); // Reminder

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

    final isAllowed =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();

    debugPrint('Notifications enabled: $isAllowed');
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
          'Alrighty, "$goalName" is live. You’ve got time $formattedDeadline’s the mark.',
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
      int reminderNumber,
      String notificationStyle,
      DateTime deadline,
      ) {
    final formattedDeadline = _format(deadline);

    if (notificationStyle == 'Minimal') {
      return 'Reminder: "$goalName" is due in 4 hours.';
    }

    if (notificationStyle == 'Vibrant') {
      final messages = [
        'Reminder #$reminderNumber: "$goalName" is closing in. Deadline is $formattedDeadline.',
        'Heads up. "$goalName" wraps up by $formattedDeadline.',
        'Reminder #$reminderNumber: "$goalName" is almost there. Due $formattedDeadline.',
        '"$goalName" is reaching its finish line. Deadline is $formattedDeadline.',
        'Quick check-in. "$goalName" ends $formattedDeadline.',
        'Reminder #$reminderNumber: "$goalName" is on the final stretch. Deadline is $formattedDeadline.',
        '"$goalName" is counting down. Due $formattedDeadline.',
        'Time’s ticking. "$goalName" closes $formattedDeadline.',
        'Reminder #$reminderNumber: "$goalName" is nearly done. Deadline is $formattedDeadline.',
        'Just a flash reminder. "$goalName" finishes $formattedDeadline.',
      ];
      return messages[_randomIndex(messages.length)];
    }

    if (notificationStyle == 'Animated') {
      final messages = [
        'Hey again. "$goalName" is still hanging out. Deadline is $formattedDeadline.',
        'Just checking in. "$goalName" is due $formattedDeadline.',
        'Reminder #$reminderNumber. "$goalName" is inching closer to $formattedDeadline.',
        'Still time. "$goalName" wraps up $formattedDeadline.',
        'Friendly ping. "$goalName" is due $formattedDeadline.',
        'You’re doing great. "$goalName" finishes $formattedDeadline.',
        'Reminder #$reminderNumber. "$goalName" is quietly approaching $formattedDeadline.',
        'Just keeping you posted. "$goalName" ends $formattedDeadline.',
        'Almost there. "$goalName" is due $formattedDeadline.',
        'Reminder vibes. "$goalName" deadline is $formattedDeadline.',
      ];
      return messages[_randomIndex(messages.length)];
    }

    // Fallback
    return 'Reminder: "$goalName" is due $formattedDeadline.';
  }


  static int _randomIndex(int length) {
    final random = Random();
    return random.nextInt(length);
  }
}
