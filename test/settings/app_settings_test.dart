import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/utils/user_prefs_codec.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('ThemeStyles', () {
    test('resolvePrimaryColor uses customization when enabled for reward', () {
      const prefs = UserPrefsSnapshot(
        rewardType: 'Customization',
        customizationEnabled: true,
        customizedPrimary: Colors.red,
      );
      expect(
        ThemeStyles.resolvePrimaryColor(
          isDark: false,
          highContrast: false,
          prefs: prefs,
        ),
        Colors.red,
      );
    });

    test('resolvePrimaryColor ignores stored custom colours when toggle off', () {
      const prefs = UserPrefsSnapshot(
        rewardType: 'Customization',
        customizationEnabled: false,
        customizedPrimary: Colors.red,
        theme: 'light',
      );
      expect(
        ThemeStyles.resolvePrimaryColor(
          isDark: false,
          highContrast: false,
          prefs: prefs,
        ),
        Colors.black87,
      );
    });

    test('notificationsEnabledForFrequency', () {
      expect(ThemeStyles.notificationsEnabledForFrequency('Low'), isTrue);
      expect(
        ThemeStyles.notificationsEnabledForFrequency('No notifications'),
        isFalse,
      );
    });
  });

  group('AppSettings', () {
    late InMemoryKeyValueStorage storage;
    late AppSettings settings;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      final prefs = UserPrefsRepository(storage);
      settings = AppSettings(prefs, ThemeRepository(prefs));
    });

    test('load applies defaults', () async {
      await settings.load();
      expect(settings.userTheme, 'light');
      expect(settings.userFontSize, 14.0);
      expect(settings.rewardType, 'Mini-games');
    });

    test('setUserTheme persists and updates snapshot', () async {
      await settings.load();
      await settings.setUserTheme('dark');
      expect(settings.userTheme, 'dark');
      expect(await storage.read(key: 'theme'), 'dark');
    });

    test('setPauseGoals accepts legacy True on reload', () async {
      await storage.write(key: 'pauseGoals', value: 'True');
      await settings.load();
      expect(settings.pauseGoals, isTrue);
    });

    test('completeRegistration marks setup and routes before onboarding', () async {
      await settings.load();
      await settings.completeRegistration(
        notificationFrequency: 'High',
        notificationStyle: 'Vibrant',
        rewardType: 'Mini-games',
      );
      expect(settings.registrationComplete, isTrue);
      expect(settings.onboardingCompleted, isFalse);
      expect(settings.notificationFrequency, 'High');
      expect(settings.notificationStyle, 'Vibrant');
    });

    test('load maps legacy loggedIn to registrationComplete', () async {
      await storage.write(key: 'loggedIn', value: 'true');
      await settings.load();
      expect(settings.registrationComplete, isTrue);
    });

    test('setRewardType does not auto-enable customized colours', () async {
      await settings.load();
      await settings.setRewardType('Customization');
      expect(settings.customizationEnabled, isFalse);
    });
  });
}
