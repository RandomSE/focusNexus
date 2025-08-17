// lib/utils/notifier.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class GoalNotifier {
  static const MethodChannel _tzChannel =
  MethodChannel('flutter_native_timezone');

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize notifications plugin & timezone data.
  static Future<void> initialize() async {
    if (_initialized) return;

    // 1) Flutter Local Notifications init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      InitializationSettings(android: androidSettings),
    );

    // 2) Timezone init via your MainActivity channel
    tz.initializeTimeZones();
    final String localZone =
        await _tzChannel.invokeMethod<String>('getLocalTimezone')
            ?? tz.local.name;
    tz.setLocalLocation(tz.getLocation(localZone));

    _initialized = true;
  }

  /// Schedule two one-shot notifications:
  ///   1) Heads-up shortly after setup
  ///   2) Reminder 4 hours before deadline
  static Future<void> startGoalCheck(
      String goalName,
      int daysToExpire,
      ) async {
    await initialize();

    final now = DateTime.now();
    final deadline = now.add(Duration(days: daysToExpire));
    final reminderDateTime = deadline.subtract(Duration(hours: 4));
    final initialDateTime = now.add(Duration(seconds: 5));

    final formattedDeadline =
    DateFormat('dd MMMM yyyy HH:mm').format(deadline);

    const androidDetails = AndroidNotificationDetails(
      'goal_channel',
      'Goal Reminders',
      channelDescription: 'Notifications for upcoming goals',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    tz.TZDateTime _toTZ(DateTime dt) => tz.TZDateTime.from(dt, tz.local);

    // 1) Initial heads-up
    try {
      await _plugin.zonedSchedule(
        goalName.hashCode,
        'Goal Scheduled',
        'Your goal "$goalName" expires on $formattedDeadline.',
        _toTZ(initialDateTime),
        platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.wallClockTime,
      );
    } catch (e) {
      debugPrint('Notification scheduling failed: $e');
    }


    // 2) Four-hour reminder
    await _plugin.zonedSchedule(
      goalName.hashCode + 1,
      'Goal Reminder',
      'Reminder: "$goalName" is due in 4 hours!',
      _toTZ(reminderDateTime),
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
    );
  }
}
