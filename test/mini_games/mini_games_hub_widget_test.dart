import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/mini_game_definition.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/providers/mini_game_catalog_provider.dart';
import 'package:focusNexus/screens/mini_games_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

const _fakeGame = MiniGameDefinition(
  id: 'fake_one',
  title: 'Fake One',
  description: 'A test catalog entry',
  unlockCost: 25,
  playCost: 5,
  endlessCost: 3,
  defaultDurationSeconds: 60,
  baseDifficulty: 1,
  implemented: false,
);

void main() {
  testWidgets('hub shows empty state when catalog is empty', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.miniGames,
      storage: onboardedTestStorage(),
      overrides: [miniGameCatalogProvider.overrideWithValue(const [])],
    );
    await pumpUntilFound(tester, find.text(miniGamesHubEmptyMessage));
    expect(find.text('Mini-games'), findsWidgets);
  });

  testWidgets(
    'hub lists titles without embedding game descriptions',
    (tester) async {
      await pumpFocusNexusApp(
        tester,
        initialRoute: AppRoutes.miniGames,
        storage: onboardedTestStorage(),
      );
      await pumpUntilFound(
        tester,
        find.text(miniGamesLastPlayedButtonLabel(FireflyJarConstants.title)),
      );
      await pumpUntilFound(tester, find.text(FireflyJarConstants.title));
      expect(find.text(FireflyJarConstants.description), findsNothing);
      expect(miniGamesHubImageAspectRatio, closeTo(9 / 16, 0.001));

      Future<void> expectTitle(String title) async {
        await tester.scrollUntilVisible(
          find.text(title),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(title), findsOneWidget);
      }

      await expectTitle('Stone Balance');
      await expectTitle('Breath Pacer');
      await expectTitle('Meteor Catch');
      await expectTitle('Word Bloom');
      await expectTitle('Rain Catcher');
    },
  );

  testWidgets('last played defaults to Firefly Jar lobby', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.miniGames,
      storage: onboardedTestStorage(),
    );
    final lastPlayed = find.text(
      miniGamesLastPlayedButtonLabel(FireflyJarConstants.title),
    );
    await pumpUntilFound(tester, lastPlayed);
    await tester.tap(lastPlayed);
    await pumpUntilFound(tester, find.textContaining('Play cost:'));
    expect(find.text(FireflyJarConstants.description), findsOneWidget);
  });

  testWidgets('last played opens most recently played game lobby', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(
      key: StorageKeys.miniGamesProgress,
      value:
          '{"${StoneBalanceConstants.gameId}":{"unlocked":true,"highScore":1,'
          '"endlessHighScore":0,"freeDurationEntries":0,'
          '"freeEndlessEntries":0,"schemaVersion":2,'
          '"lastPlayedAt":"2026-08-02T12:00:00.000Z"}}',
    );

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.miniGames,
      storage: storage,
    );
    final lastPlayed = find.text(
      miniGamesLastPlayedButtonLabel(StoneBalanceConstants.title),
    );
    await pumpUntilFound(tester, lastPlayed);
    await tester.tap(lastPlayed);
    await pumpUntilFound(tester, find.text(StoneBalanceConstants.description));
    expect(find.textContaining('Play cost:'), findsOneWidget);
  });

  testWidgets('locked hub tile asks to unlock when balance is enough', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '100');

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.miniGames,
      storage: storage,
      overrides: [
        miniGameCatalogProvider.overrideWithValue(const [_fakeGame]),
      ],
    );
    await pumpUntilFound(tester, find.text('Fake One'));
    await tester.pump();
    await tester.tap(find.text('Fake One'));
    await pumpUntilFound(
      tester,
      find.textContaining('unlock this mini game for 25 points'),
    );
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('A test catalog entry'), findsNothing);
  });

  testWidgets('locked hub tile shows Okay when balance is too low', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '10');

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.miniGames,
      storage: storage,
      overrides: [
        miniGameCatalogProvider.overrideWithValue(const [_fakeGame]),
      ],
    );
    await pumpUntilFound(tester, find.text('Fake One'));
    await tester.pump();
    await tester.tap(find.text('Fake One'));
    await pumpUntilFound(
      tester,
      find.text('This mini game costs 25 points to unlock'),
    );
    expect(find.text('Okay'), findsOneWidget);
    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();
    expect(find.text('Fake One'), findsOneWidget);
  });

  testWidgets('unlocked paid game opens lobby without unlock dialog', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '500');
    await storage.write(
      key: StorageKeys.miniGamesProgress,
      value:
          '{"${StoneBalanceConstants.gameId}":{"unlocked":true,"highScore":0,'
          '"endlessHighScore":0,"freeDurationEntries":0,'
          '"freeEndlessEntries":0,"schemaVersion":2}}',
    );

    const unlockedOnly = MiniGameDefinition(
      id: StoneBalanceConstants.gameId,
      title: StoneBalanceConstants.title,
      description: StoneBalanceConstants.description,
      unlockCost: StoneBalanceConstants.unlockCost,
      playCost: StoneBalanceConstants.playCost,
      endlessCost: StoneBalanceConstants.endlessCost,
      defaultDurationSeconds: StoneBalanceConstants.durationSeconds,
      baseDifficulty: StoneBalanceConstants.baseDifficulty,
      implemented: true,
    );

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.miniGames,
      storage: storage,
      overrides: [
        miniGameCatalogProvider.overrideWithValue(const [unlockedOnly]),
      ],
    );
    await pumpUntilFound(tester, find.text('Stone Balance'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Stone Balance'));
    await pumpUntilFound(tester, find.textContaining('Play cost:'));
    expect(find.textContaining('Would you like to unlock'), findsNothing);
    expect(find.text(StoneBalanceConstants.description), findsOneWidget);
  });
}
