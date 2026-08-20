import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/goal_notification_android.dart';

void main() {
  group('GoalNotificationAndroid.collapsedPreview', () {
    test('returns short text unchanged', () {
      const text = 'Goal "Walk" is due soon.';
      expect(GoalNotificationAndroid.collapsedPreview(text), text);
    });

    test('collapses whitespace and truncates long text', () {
      final long = 'Line one.\n\nLine two. ${'x' * 200}';
      final preview = GoalNotificationAndroid.collapsedPreview(long);
      expect(preview.length, lessThanOrEqualTo(120));
      expect(preview.endsWith('…'), isTrue);
      expect(preview, isNot(contains('\n')));
    });

    test('empty input returns empty string', () {
      expect(GoalNotificationAndroid.collapsedPreview('   '), '');
    });
  });

  group('GoalNotificationAndroid status-bar icon', () {
    test('uses ic_notification drawable name', () {
      expect(
        GoalNotificationAndroid.androidStatusBarIcon,
        'ic_notification',
      );
    });

    test('androidDetails wires the status-bar icon', () {
      final details = GoalNotificationAndroid.androidDetails(
        channelId: 'channel',
        channelName: 'Channel',
        channelDescription: 'desc',
        title: 'Title',
        fullBody: 'Body text',
      );
      expect(details.icon, GoalNotificationAndroid.androidStatusBarIcon);
    });
  });
}
