import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/legal/legal_documents.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/rewards/reward_type_selection.dart';
import 'package:focusNexus/screens/consistency_explorer_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';

import '../helpers/in_memory_key_value_storage.dart';

Future<AppSettings> _loadedSettings({
  bool registrationComplete = false,
  bool onboardingCompleted = false,
  bool acceptCurrentEula = false,
}) async {
  final storage = InMemoryKeyValueStorage(
    initial: {
      if (registrationComplete) StorageKeys.registrationComplete: 'true',
      if (onboardingCompleted) StorageKeys.onboardingCompleted: 'true',
      if (acceptCurrentEula) ...{
        StorageKeys.eulaAccepted: 'true',
        StorageKeys.eulaAcceptedVersion: kLegalDocsVersion,
        StorageKeys.eulaAcceptedAt: '2026-08-10T00:00:00.000Z',
      },
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

    test('initialFor sends registered users without EULA to eula accept', () async {
      final settings = await _loadedSettings(registrationComplete: true);
      expect(AppRouteGuard.initialFor(settings).path, EulaAcceptRoute.routeName);
    });

    test('initialFor sends registered+EULA-but-not-onboarded users to onboard', () async {
      final settings = await _loadedSettings(
        registrationComplete: true,
        acceptCurrentEula: true,
      );
      expect(AppRouteGuard.initialFor(settings).path, OnboardRoute.routeName);
    });

    test('initialFor sends onboarded users with EULA to dashboard', () async {
      final settings = await _loadedSettings(
        registrationComplete: true,
        onboardingCompleted: true,
        acceptCurrentEula: true,
      );
      expect(AppRouteGuard.initialFor(settings).path, DashboardRoute.routeName);
    });

    test('guard blocks dashboard when EULA outdated', () async {
      final settings = await _loadedSettings(
        registrationComplete: true,
        onboardingCompleted: true,
      );
      final guarded = AppRouteGuard.guard(AppRoute.dashboard, settings);
      expect(guarded.path, EulaAcceptRoute.routeName);
    });

    test('guard blocks dashboard when onboarding incomplete', () async {
      final settings = await _loadedSettings(
        registrationComplete: true,
        acceptCurrentEula: true,
      );
      final guarded = AppRouteGuard.guard(AppRoute.dashboard, settings);
      expect(guarded.path, OnboardRoute.routeName);
    });

    test('guard redirects completed onboard route to dashboard', () async {
      final settings = await _loadedSettings(
        registrationComplete: true,
        onboardingCompleted: true,
        acceptCurrentEula: true,
      );
      final guarded = AppRouteGuard.guard(AppRoute.onboard, settings);
      expect(guarded.path, DashboardRoute.routeName);
    });

    test('legal document routes remain accessible', () async {
      final settings = await _loadedSettings();
      final guarded = AppRouteGuard.guard(
        LegalDocumentRoute(LegalDocumentId.eula),
        settings,
      );
      expect(guarded, isA<LegalDocumentRoute>());
    });

    test('guard allows registration only when incomplete', () async {
      final incomplete = await _loadedSettings();
      expect(
        AppRouteGuard.guard(AppRoute.registration, incomplete).path,
        RegistrationRoute.routeName,
      );

      final complete = await _loadedSettings(
        registrationComplete: true,
        acceptCurrentEula: true,
        onboardingCompleted: true,
      );
      expect(
        AppRouteGuard.guard(AppRoute.registration, complete).path,
        DashboardRoute.routeName,
      );
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

    test('parses mini-game lobby game id', () {
      final route = AppRoute.fromRouteSettings(
        const RouteSettings(
          name: MiniGameLobbyRoute.routeName,
          arguments: 'demo',
        ),
      );
      expect(route, isA<MiniGameLobbyRoute>());
      expect((route as MiniGameLobbyRoute).gameId, 'demo');
      expect(route.navigationArguments, 'demo');
    });

    test('parses mini-game play round config', () {
      final route = AppRoute.fromRouteSettings(
        RouteSettings(
          name: MiniGamePlayRoute.routeName,
          arguments: const MiniGameRoundConfig(gameId: 'demo', endless: true),
        ),
      );
      expect(route, isA<MiniGamePlayRoute>());
      final play = route as MiniGamePlayRoute;
      expect(play.gameId, 'demo');
      expect(play.endless, isTrue);
      final args = play.navigationArguments as MiniGameRoundConfig;
      expect(args.gameId, 'demo');
      expect(args.endless, isTrue);
    });

    test('parses sound effects route', () {
      final route = AppRoute.fromRouteSettings(
        const RouteSettings(name: SoundEffectsRoute.routeName),
      );
      expect(route, isA<SoundEffectsRoute>());
      expect(route.path, SoundEffectsRoute.routeName);
    });

    test('parses registration route', () {
      final route = AppRoute.fromRouteSettings(
        const RouteSettings(name: RegistrationRoute.routeName),
      );
      expect(route, isA<RegistrationRoute>());
      expect(route.path, RegistrationRoute.routeName);
    });

    test('parses legal document route', () {
      final route = AppRoute.fromRouteSettings(
        const RouteSettings(
          name: LegalDocumentRoute.routeName,
          arguments: 'privacyPolicy',
        ),
      );
      expect(route, isA<LegalDocumentRoute>());
      expect(
        (route as LegalDocumentRoute).documentId,
        LegalDocumentId.privacyPolicy,
      );
    });

    test('parses split phrase pack routes', () {
      expect(
        AppRoute.fromRouteSettings(
          const RouteSettings(name: DashboardMotivatorPackRoute.routeName),
        ),
        isA<DashboardMotivatorPackRoute>(),
      );
      expect(
        AppRoute.fromRouteSettings(
          const RouteSettings(name: DailyAffirmationPackRoute.routeName),
        ),
        isA<DailyAffirmationPackRoute>(),
      );
      expect(
        AppRoute.fromRouteSettings(
          const RouteSettings(name: CustomAffirmationPackRoute.routeName),
        ),
        isA<CustomAffirmationPackRoute>(),
      );
    });

    test('parses consistency explorer with args', () {
      final route = AppRoute.fromRouteSettings(
        RouteSettings(
          name: ConsistencyExplorerRoute.routeName,
          arguments: ConsistencyExplorerArgs(
            year: 2025,
            month: 7,
            selectedDay: DateTime(2025, 7, 3),
            useMockData: true,
          ),
        ),
      );
      expect(route, isA<ConsistencyExplorerRoute>());
      final typed = route as ConsistencyExplorerRoute;
      expect(typed.year, 2025);
      expect(typed.month, 7);
      expect(typed.useMockData, isTrue);
      expect(typed.selectedDay, DateTime(2025, 7, 3));
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

  group('RewardRoute thin back-compat', () {
    test('fromRouteSettings still resolves reward path', () {
      final route = AppRoute.fromRouteSettings(
        const RouteSettings(name: RewardRoute.routeName),
      );
      expect(route, isA<RewardRoute>());
      expect(route.path, RewardRoute.routeName);
    });

    test('RewardTypeSelection maps primary to direct destinations', () {
      expect(
        RewardTypeSelection.routeForStorageValue('Mini-games'),
        AppRoute.miniGames,
      );
      expect(
        RewardTypeSelection.routeForStorageValue('Customization'),
        AppRoute.customization,
      );
    });
  });
}
