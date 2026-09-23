import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/utils/user_prefs_codec.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('ThemeStyles', () {
    test('resolvePrimaryColor uses customization when enabled for reward', () {
      const prefs = UserPrefsSnapshot(
        rewardTypes: ['Customization'],
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
        rewardTypes: ['Customization'],
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
        const Color(0xFF1D2730),
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
      expect(settings.rewardTypes, ['Mini-games']);
      expect(settings.soundEnabled, isTrue);
      expect(settings.soundVolume, 100.0);
    });

    test('setSoundEnabled invokes onSoundPrefsChanged', () async {
      var calls = 0;
      settings.onSoundPrefsChanged = () => calls += 1;
      await settings.load();
      await settings.setSoundEnabled(false);
      expect(calls, 1);
      await settings.setSoundVolume(50);
      expect(calls, 2);
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
        rewardTypes: ['Mini-games'],
      );
      expect(settings.registrationComplete, isTrue);
      expect(settings.onboardingCompleted, isFalse);
      expect(settings.hasAcceptedCurrentEula, isTrue);
      expect(settings.notificationFrequency, 'High');
      expect(settings.notificationStyle, 'Vibrant');
      expect(settings.rewardTypes, ['Mini-games']);
      expect(
        await storage.read(key: StorageKeys.notificationPrefsConfirmed),
        'false',
      );
      expect(settings.username, isEmpty);
      expect(settings.grantsComplimentaryPaidAccess, isFalse);
    });

    test('completeRegistration persists optional username', () async {
      await settings.load();
      await settings.completeRegistration(
        notificationFrequency: 'High',
        notificationStyle: 'Vibrant',
        rewardTypes: ['Mini-games'],
        username: '  play-tester  ',
      );
      expect(settings.username, 'play-tester');
      expect(await storage.read(key: StorageKeys.username), 'play-tester');
      expect(settings.grantsComplimentaryPaidAccess, isFalse);
    });

    test('tester username grants complimentary paid access after registration',
        () async {
      await settings.load();
      await settings.completeRegistration(
        notificationFrequency: 'High',
        notificationStyle: 'Vibrant',
        rewardTypes: ['Mini-games'],
        username:
            'scokologhunjmentlogdirfirelogsabndbasmnbjjxcbbxbsjjasldasljdaskjdwn',
      );
      expect(settings.grantsComplimentaryPaidAccess, isTrue);
    });

    test('clearEulaAcceptance clears acceptance used by applyDefaultPreferences', () async {
      await settings.load();
      await settings.acceptCurrentEula(
        acceptedAt: DateTime.utc(2026, 8, 10, 12),
      );
      expect(settings.hasAcceptedCurrentEula, isTrue);
      await settings.clearEulaAcceptance();
      expect(settings.hasAcceptedCurrentEula, isFalse);
      expect(settings.eulaAccepted, isFalse);
      expect(settings.eulaAcceptedVersion, isEmpty);
      await settings.acceptCurrentEula(
        acceptedAt: DateTime.utc(2026, 8, 10, 12),
      );
      await settings.applyDefaultPreferences();
      expect(settings.hasAcceptedCurrentEula, isFalse);
    });

    test('load maps legacy loggedIn to registrationComplete', () async {
      await storage.write(key: 'loggedIn', value: 'true');
      await settings.load();
      expect(settings.registrationComplete, isTrue);
    });

    test('setRewardTypes does not auto-enable customized colours', () async {
      await settings.load();
      await settings.setRewardTypes(['Customization']);
      expect(settings.customizationEnabled, isFalse);
      expect(settings.rewardTypes, ['Customization']);
    });

    test('setRewardTypes persists JSON list only', () async {
      await settings.load();
      await settings.setRewardTypes(['Mini-games', 'Customization']);
      expect(
        await storage.read(key: 'rewardTypes'),
        '["Mini-games","Customization"]',
      );
    });

    test('setRewardTypes refuses empty selection', () async {
      await settings.load();
      await settings.setRewardTypes(['Mini-games', 'Customization']);
      final ok = await settings.setRewardTypes([]);
      expect(ok, isFalse);
      expect(settings.rewardTypes, ['Mini-games', 'Customization']);
    });

    test('removing Customization disables customizationEnabled', () async {
      await settings.load();
      await settings.setRewardTypes(['Customization', 'Mini-games']);
      await settings.setCustomizationEnabled(true);
      expect(settings.customizationEnabled, isTrue);
      await settings.setRewardTypes(['Mini-games']);
      expect(settings.customizationEnabled, isFalse);
      expect(settings.isCustomizationReward, isFalse);
    });
  });
}
