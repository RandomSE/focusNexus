import 'package:flutter/foundation.dart';

/// Platform-aware helpers for local notification scheduling limits.
abstract final class NotificationPlatform {
  NotificationPlatform._();

  /// iOS pending local notification hard cap.
  static const int iosPendingNotificationCap = 64;

  /// Affirmation horizon on iOS (leaves headroom for goals/reminders).
  static const int iosAffirmationHorizonDays = 40;

  /// Affirmation horizon on Android / other platforms.
  static const int defaultAffirmationHorizonDays = 90;

  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether Android group-summary notifications should be scheduled.
  static bool get supportsGroupSummaryNotifications => isAndroid;

  /// Horizon days for daily affirmations on the current (or overridden) platform.
  static int affirmationHorizonDays({bool? isIosOverride}) {
    final ios = isIosOverride ?? isIos;
    return ios ? iosAffirmationHorizonDays : defaultAffirmationHorizonDays;
  }

  /// True when notification permission alone is enough to enable notifications
  /// (exact alarm only affects Android schedule precision, not enablement).
  ///
  /// [isIosOverride] / [isAndroidOverride] are retained for call-site clarity in
  /// tests; both platforms treat notification permission as sufficient.
  static bool notificationPermissionSufficientWithoutExactAlarm({
    bool? isIosOverride,
    bool? isAndroidOverride,
  }) {
    // Named overrides kept for existing call sites; both platforms are sufficient.
    final _ = (isIosOverride, isAndroidOverride);
    return true;
  }

  /// User-facing copy when exact alarm is denied but notifications remain on.
  static const String exactAlarmDeniedUserMessage =
      'Reminders may run at approximate times without exact alarm permission.';
}
