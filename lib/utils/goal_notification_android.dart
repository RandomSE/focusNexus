import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification layout for long goal/reminder copy (BigTextStyle).
abstract final class GoalNotificationAndroid {
  GoalNotificationAndroid._();

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

  static AndroidNotificationDetails details({
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
      android: details(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        title: title,
        fullBody: fullBody,
        groupKey: groupKey,
        setAsGroupSummary: setAsGroupSummary,
      ),
    );
  }
}
