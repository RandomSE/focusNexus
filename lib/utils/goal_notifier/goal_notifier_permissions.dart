import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/utils/notification_platform.dart';

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

/// Request notification permission (platform-aware).
Future<void> requestNotificationPermission() async {
  if (NotificationPlatform.isIos) {
    await _requestIosNotificationPermission();
    return;
  }
  await _requestAndroidNotificationPermission();
}

Future<void> _requestAndroidNotificationPermission() async {
  final r = GoalNotifierRuntime.I;
  final statusNotification = await Permission.notification.request();
  // Exact alarm is optional: denial only affects schedule precision.
  final statusExactAlarm = await Permission.scheduleExactAlarm.request();

  if (!statusNotification.isGranted) {
    final status = await Permission.notification.status;
    final shouldShow =
        await Permission.notification.shouldShowRequestRationale;
    debugLog('Status: $status. Should show: $shouldShow');
    debugLog('Notification permission not granted.');
    if (shouldShow) {
      return;
    } else {
      await openNotificationSettings();
      return;
    }
  }

  if (!statusExactAlarm.isGranted) {
    debugLog(
      'Exact alarm permission not granted. Notifications enabled; '
      'schedule mode will use inexact fallback.',
    );
  }

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

Future<void> _requestIosNotificationPermission() async {
  final r = GoalNotifierRuntime.I;
  final statusNotification = await Permission.notification.request();
  final iosPlugin =
      r.plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
  final pluginGranted = await iosPlugin?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );

  final granted =
      statusNotification.isGranted || (pluginGranted ?? false);
  if (!granted) {
    final shouldShow =
        await Permission.notification.shouldShowRequestRationale;
    debugLog(
      'iOS notification permission not granted. shouldShow=$shouldShow',
    );
    if (!shouldShow) {
      await openNotificationSettings();
    }
    return;
  }
  debugLog('iOS notifications enabled.');
}

bool get _runningInFlutterTest =>
    WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');

/// Whether the user may enable local notifications (notification permission).
/// Exact-alarm grant is not required; see [getScheduleMode].
Future<bool> checkNotificationsPermissionsGranted() async {
  if (_runningInFlutterTest) {
    return false;
  }
  final statusNotification = await Permission.notification.status;
  return statusNotification.isGranted;
}

/// Android exact-alarm status. Non-Android returns true (N/A).
Future<bool> checkExactAlarmPermissionGranted() async {
  if (_runningInFlutterTest) {
    return false;
  }
  if (!NotificationPlatform.isAndroid) {
    return true;
  }
  final status = await Permission.scheduleExactAlarm.status;
  return status.isGranted;
}

Future<AndroidScheduleMode> getScheduleMode() async {
  if (!NotificationPlatform.isAndroid) {
    // iOS / other: exact-alarm modes are Android-only; plugin ignores on Darwin.
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

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
    // Fallback for platforms without the native bridge.
    try {
      await openAppSettings();
    } catch (fallbackError) {
      debugLog('Fallback openAppSettings failed: $fallbackError');
    }
  }
}

/// Opens the system exact-alarm settings screen when available.
Future<void> openExactAlarmSettings() async {
  try {
    await GoalNotifierRuntime.platform.invokeMethod('openExactAlarmSettings');
  } catch (e) {
    debugLog('Error opening exact alarm settings: $e');
    try {
      await openAppSettings();
    } catch (fallbackError) {
      debugLog('Fallback openAppSettings failed: $fallbackError');
    }
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
