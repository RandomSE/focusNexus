import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/debug_log.dart';

import '../theme_styles.dart';
import 'goal_notifier_bindings.dart';
import 'goal_notifier_runtime.dart';

Future<bool> areNotificationsEnabledByFrequency() async {
  final frequencyRaw = await goalNotifierStorage().read(
    key: StorageKeys.notificationFrequency,
  );
  final frequency = (frequencyRaw ?? '').trim();
  return ThemeStyles.notificationsEnabledForFrequency(frequency);
}

/// Request notification permission
Future<void> requestNotificationPermission() async {
  final r = GoalNotifierRuntime.I;
  // Request POST_NOTIFICATIONS (Android 13+)
  final statusNotification = await Permission.notification.request();

  // Request SCHEDULE_EXACT_ALARM (Android 12+)
  final statusExactAlarm = await Permission.scheduleExactAlarm.request();

  // Check if any critical permission is denied
  if (!statusNotification.isGranted || !statusExactAlarm.isGranted) {
    final status = await Permission.notification.status;
    final shouldShow =
        await Permission.notification.shouldShowRequestRationale;
    debugLog('Status: $status. Should show: $shouldShow');
    debugLog('Critical notification permissions not granted.');
    if (shouldShow) {
      return; // User denied notification - don't send request
    } else {
      await openNotificationSettings(); // User previously blocked notification popup, triggered again - Send to settings for request.
      return;
    }
  }

  // Check if notifications are enabled in system settings
  final isAllowed =
      await r.plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();

  if (isAllowed == false) {
    debugLog('Notifications are disabled in system settings.');
    await openNotificationSettings();
  } else {
    debugLog('Notifications fully enabled.');
  }
}

bool get _runningInFlutterTest =>
    WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');

Future<bool> checkNotificationsPermissionsGranted() async {
  if (_runningInFlutterTest) {
    return false;
  }
  final statusNotification = await Permission.notification.status;
  final statusExactAlarm = await Permission.scheduleExactAlarm.status;
  if (statusNotification.isGranted && statusExactAlarm.isGranted) {
    return true;
  } else {
    return false;
  }
}

Future<AndroidScheduleMode> getScheduleMode() async {
  final status = await Permission.scheduleExactAlarm.status;

  if (status.isGranted) {
    debugLog('Exact alarm permission granted.');
    return AndroidScheduleMode.exactAllowWhileIdle;
  } else {
    debugLog('Exact alarm permission not granted. Using inexact mode.');
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }
}

Future<void> openNotificationSettings() async {
  try {
    await GoalNotifierRuntime.platform.invokeMethod('openNotificationSettings');
  } catch (e) {
    debugLog('Error opening notification settings: $e');
  }
}

Future<String> getLocalTimezone() async {
  try {
    final timezone = await GoalNotifierRuntime.platform.invokeMethod<String>(
      'getLocalTimezone',
    );
    return timezone ?? 'America/Chicago';
  } catch (e) {
    return 'America/Chicago';
  }
}
