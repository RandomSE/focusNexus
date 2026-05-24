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
    test('resolvePrimaryColor uses customization when enabled', () {
      const prefs = UserPrefsSnapshot(
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
  });
}
