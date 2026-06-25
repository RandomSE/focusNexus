import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';

import '../helpers/in_memory_key_value_storage.dart';

Future<AppSettings> _loadedSettings({
  bool registrationComplete = false,
  bool onboardingCompleted = false,
}) async {
  final storage = InMemoryKeyValueStorage(
    initial: {
      if (registrationComplete) StorageKeys.registrationComplete: 'true',
      if (onboardingCompleted) StorageKeys.onboardingCompleted: 'true',
    },
  );
  final prefs = UserPrefsRepository(storage);
  final settings = AppSettings(prefs, ThemeRepository(prefs));
  await settings.load();
  return settings;
}

void main() {
  group('AppRouteGuard', () {
    test('initialFor sends unregistered users to auth', () async {
      final settings = await _loadedSettings();
      expect(AppRouteGuard.initialFor(settings).path, AuthRoute.routeName);
    });

    test('initialFor sends registered-but-not-onboarded users to onboard', () async {
      final settings = await _loadedSettings(registrationComplete: true);
      expect(AppRouteGuard.initialFor(settings).path, OnboardRoute.routeName);
    });

    test('initialFor sends onboarded users to dashboard', () async {
      final settings = await _loadedSettings(
        registrationComplete: true,
        onboardingCompleted: true,
      );
      expect(AppRouteGuard.initialFor(settings).path, DashboardRoute.routeName);
    });

    test('guard blocks dashboard when onboarding incomplete', () async {
      final settings = await _loadedSettings(registrationComplete: true);
      final guarded = AppRouteGuard.guard(AppRoute.dashboard, settings);
      expect(guarded.path, OnboardRoute.routeName);
    });

    test('guard redirects completed onboard route to dashboard', () async {
      final settings = await _loadedSettings(
        registrationComplete: true,
        onboardingCompleted: true,
      );
      final guarded = AppRouteGuard.guard(AppRoute.onboard, settings);
      expect(guarded.path, DashboardRoute.routeName);
    });
  });

  group('AppRoute.fromRouteSettings', () {
    test('parses progressive visual section with typed theme id', () {
      final route = AppRoute.fromRouteSettings(
        RouteSettings(
          name: ProgressiveVisualSectionRoute.routeName,
          arguments: VisualThemeId.zenGarden,
        ),
      );
      expect(route, isA<ProgressiveVisualSectionRoute>());
      expect(
        (route as ProgressiveVisualSectionRoute).themeId,
        VisualThemeId.zenGarden,
      );
    });

    test('parses theme id from enum name string', () {
      final route = AppRoute.fromRouteSettings(
        RouteSettings(
          name: ProgressiveVisualSectionRoute.routeName,
          arguments: 'zenGarden',
        ),
      );
      expect(
        (route as ProgressiveVisualSectionRoute).themeId,
        VisualThemeId.zenGarden,
      );
    });

    test('ProgressiveVisualSectionRoute carries theme in navigationArguments', () {
      const route = ProgressiveVisualSectionRoute(VisualThemeId.zenGarden);
      expect(route.navigationArguments, VisualThemeId.zenGarden);
    });
  });

  group('RewardKind', () {
    test('parse maps storage strings', () {
      expect(RewardKind.parse('Mini-games'), RewardKind.miniGames);
      expect(
        RewardKind.parse('Progressive visuals'),
        RewardKind.progressiveVisuals,
      );
      expect(RewardKind.parse('Customization'), RewardKind.customization);
      expect(RewardKind.parse(null), RewardKind.miniGames);
    });
  });
}
