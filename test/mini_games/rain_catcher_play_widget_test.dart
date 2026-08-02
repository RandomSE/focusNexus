import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_engine.dart';
import 'package:focusNexus/screens/rain_catcher_play_screen.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
  });

  testWidgets('play screen shows Water score label and timer', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: RainCatcherPlayScreen(
            config: MiniGameRoundConfig(
              gameId: RainCatcherConstants.gameId,
              endless: false,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Water'));
    expect(find.text('Streak'), findsWidgets);
    expect(find.byType(RainCatcherPlayScreen), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('s'), findsWidgets);
  });

  testWidgets('pad move hint hides after five seconds of play', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final engine = RainCatcherEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
      random: math.Random(3),
    );

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: RainCatcherPlayScreen(
            config: const MiniGameRoundConfig(
              gameId: RainCatcherConstants.gameId,
              endless: false,
            ),
            testEngine: engine,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Water'));
    expect(find.text(RainCatcherConstants.padHint), findsOneWidget);

    engine.elapsedSeconds = RainCatcherConstants.padHintVisibleSeconds + 0.05;
    // Advance the play ticker so setState rebuilds with the new elapsed time.
    await tester.pump(const Duration(milliseconds: 32));
    expect(find.text(RainCatcherConstants.padHint), findsNothing);
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
          home: RainCatcherPlayScreen(
            config: MiniGameRoundConfig(
              gameId: RainCatcherConstants.gameId,
              endless: true,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('End'));
    expect(find.byType(RainCatcherPlayScreen), findsOneWidget);
  });

  testWidgets('dragging moves the lily pad horizontally', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final engine = RainCatcherEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
      random: math.Random(9),
    );

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: RainCatcherPlayScreen(
            config: const MiniGameRoundConfig(
              gameId: RainCatcherConstants.gameId,
              endless: false,
            ),
            testEngine: engine,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Water'));

    final before = engine.padCenterX;
    await tester.drag(find.byType(CustomPaint).first, const Offset(120, 0));
    await tester.pump();

    expect(engine.padCenterX, isNot(equals(before)));
  });

  testWidgets('end overlay appears with Done when the round finishes', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final engine = RainCatcherEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
      random: math.Random(4),
    );
    engine.endRound();

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: RainCatcherPlayScreen(
            config: const MiniGameRoundConfig(
              gameId: RainCatcherConstants.gameId,
              endless: false,
            ),
            testEngine: engine,
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Done'));
    expect(find.text('Time'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });

  testWidgets('tap anywhere on end overlay dismisses like Done', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final engine = RainCatcherEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
      random: math.Random(5),
    );
    engine.endRound();

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: RainCatcherPlayScreen(
            config: const MiniGameRoundConfig(
              gameId: RainCatcherConstants.gameId,
              endless: false,
            ),
            testEngine: engine,
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Done'));
    // Tap the scrim away from the Done button (top-left of overlay).
    await tester.tapAt(const Offset(24, 24));
    await tester.pumpAndSettle();
    expect(find.byType(RainCatcherPlayScreen), findsNothing);
  });
}
