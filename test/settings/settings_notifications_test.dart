import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:focusNexus/settings/settings_notifications.dart';

void main() {
  test('showsNotificationControls follows enabled frequencies', () {
    expect(
      SettingsNotifications.showsNotificationControls(
        NotificationPreferenceOptions.frequencyMedium,
      ),
      isTrue,
    );
    expect(
      SettingsNotifications.showsNotificationControls(
        NotificationPreferenceOptions.frequencyDisabled,
      ),
      isFalse,
    );
  });
}
