import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Cross-platform notification layout for long goal/reminder copy.
///
/// Android uses BigTextStyle; iOS uses Darwin present flags.
abstract final class GoalNotificationAndroid {
  GoalNotificationAndroid._();

  /// Android status-bar / tray drawable (white silhouette on transparent).
  ///
  /// Must match `android/app/src/main/res/drawable-*dpi/ic_notification.png`.
  static const String androidStatusBarIcon = 'ic_notification';

  /// Collapsed shade preview length; full text lives in [BigTextStyleInformation].
  static const int collapsedPreviewMaxLength = 120;

  /// Single-line preview for the collapsed notification row.
  static String collapsedPreview(String fullText) {
    final normalized = fullText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return '';
    if (normalized.length <= collapsedPreviewMaxLength) {
      return normalized;
    }
    return '${normalized.substring(0, collapsedPreviewMaxLength - 1)}…';
  }

  static AndroidNotificationDetails androidDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String fullBody,
    String? groupKey,
    bool setAsGroupSummary = false,
  }) {
    final preview = collapsedPreview(fullBody);
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      icon: androidStatusBarIcon,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      groupKey: groupKey,
      setAsGroupSummary: setAsGroupSummary,
      styleInformation: BigTextStyleInformation(
        fullBody,
        contentTitle: title,
        summaryText: preview,
      ),
    );
  }

  /// Backward-compatible alias for [androidDetails].
  static AndroidNotificationDetails details({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String fullBody,
    String? groupKey,
    bool setAsGroupSummary = false,
  }) =>
      androidDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        title: title,
        fullBody: fullBody,
        groupKey: groupKey,
        setAsGroupSummary: setAsGroupSummary,
      );

  static DarwinNotificationDetails darwinDetails({
    String? threadIdentifier,
  }) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: threadIdentifier,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
  }

  static NotificationDetails platformDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String fullBody,
    String? groupKey,
    bool setAsGroupSummary = false,
  }) {
    return NotificationDetails(
      android: androidDetails(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        title: title,
        fullBody: fullBody,
        groupKey: groupKey,
        setAsGroupSummary: setAsGroupSummary,
      ),
      iOS: darwinDetails(threadIdentifier: groupKey),
    );
  }
}
