import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:focusNexus/utils/theme_styles.dart';

void main() {
  group('NotificationPreferenceOptions', () {
    test('style order is Vibrant, Minimal, Animated', () {
      expect(NotificationPreferenceOptions.styles, [
        'Vibrant',
        'Minimal',
        'Animated',
      ]);
    });

    test('frequencies include disabled sentinel last', () {
      expect(NotificationPreferenceOptions.frequencies, [
        'Low',
        'Medium',
        'High',
        NotificationPreferenceOptions.frequencyDisabled,
      ]);
    });

    test('isEnabled matches ThemeStyles helper and disabled sentinel', () {
      for (final frequency in NotificationPreferenceOptions.frequencies) {
        expect(
          NotificationPreferenceOptions.isEnabled(frequency),
          ThemeStyles.notificationsEnabledForFrequency(frequency),
        );
      }
      expect(
        NotificationPreferenceOptions.isDisabled(
          NotificationPreferenceOptions.frequencyDisabled,
        ),
        isTrue,
      );
      expect(
        NotificationPreferenceOptions.isDisabled(
          NotificationPreferenceOptions.frequencyMedium,
        ),
        isFalse,
      );
    });
  });
}
