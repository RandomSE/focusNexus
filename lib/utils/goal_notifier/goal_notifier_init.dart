import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:focusNexus/utils/debug_log.dart';

import 'package:focusNexus/goals/goals_notification_navigation.dart';
import 'goal_notifier_bindings.dart';
import 'goal_notifier_daily_affirmations.dart';
import 'goal_notifier_permissions.dart';
import 'goal_notifier_runtime.dart';

@pragma('vm:entry-point')
void onNotificationTapBackground(NotificationResponse response) {
  handleGoalsNotificationPayload(response.payload);
}

/// Initialize notifications plugin
Future<void> initialize() async {
  final r = GoalNotifierRuntime.I;
  await checkAdditionalNotificationSettings();
  if (r.initialized) return;

  initializeTimeZones();
  r.scheduleMode = await getScheduleMode();

  try {
    final String currentTimeZone = await getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    debugLog('Timezone set to $currentTimeZone');
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('America/Chicago'));
    debugLog(
      'Unable to get timezone. Set to America/Chicago (notifications will be scheduled at  unexpected times.)',
    );
  }

  const androidSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const initializationSettings = InitializationSettings(
    android: androidSettings,
  );
  await r.plugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      handleGoalsNotificationPayload(response.payload);
      openGoalsFromPendingNotification();
    },
    onDidReceiveBackgroundNotificationResponse: onNotificationTapBackground,
  );

  final launchDetails = await r.plugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    handleGoalsNotificationPayload(launchDetails!.notificationResponse?.payload);
  }

  r.initialized = true;
  debugLog('Notifications initialized.');
  await refreshDailyAffirmationSchedules();
}

Future<void> checkAdditionalNotificationSettings() async {
  final r = GoalNotifierRuntime.I;
  await checkAiEncouragement();
  await checkDailyAffirmations();
  debugLog(
    'Notification additional settings confirmed. aiEncouragement: ${r.aiEncouragement}, dailyAffirmations: ${r.dailyAffirmations}',
  );
}
