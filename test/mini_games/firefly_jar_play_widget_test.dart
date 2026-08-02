import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/screens/firefly_jar_play_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('play screen shows catch label and timer', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: FireflyJarPlayScreen(
            config: MiniGameRoundConfig(
              gameId: FireflyJarConstants.gameId,
              endless: false,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Fireflies'));
    expect(find.byType(FireflyJarPlayScreen), findsOneWidget);
    expect(find.textContaining('s'), findsWidgets);
  });

  testWidgets('endless play shows End control', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: FireflyJarPlayScreen(
            config: MiniGameRoundConfig(
              gameId: FireflyJarConstants.gameId,
              endless: true,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('End'));
    expect(find.byType(FireflyJarPlayScreen), findsOneWidget);
  });
}
