import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_engine.dart';
import 'package:focusNexus/screens/word_bloom_play_screen.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
  });
  tearDown(() {
    SoundService.suppressNativePlaybackForTesting = false;
  });

  testWidgets('play screen shows score label and timer', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: WordBloomPlayScreen(
            config: MiniGameRoundConfig(
              gameId: WordBloomConstants.gameId,
              endless: false,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Score'));
    expect(find.text('Streak'), findsWidgets);
    expect(find.byType(WordBloomPlayScreen), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
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
          home: WordBloomPlayScreen(
            config: MiniGameRoundConfig(
              gameId: WordBloomConstants.gameId,
              endless: true,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('End'));
    expect(find.byType(WordBloomPlayScreen), findsOneWidget);
  });

  testWidgets('tap scatters resting word', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final engine = WordBloomEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
      random: math.Random(7),
    );
    engine.forceWordForTest('HOPE');

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: WordBloomPlayScreen(
            config: const MiniGameRoundConfig(
              gameId: WordBloomConstants.gameId,
              endless: false,
            ),
            testEngine: engine,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Score'));

    final center = engine.restingWordCenterForTest;
    final paintBox =
        tester.renderObject(find.byType(CustomPaint).first) as RenderBox;
    final origin = paintBox.localToGlobal(Offset.zero);
    await tester.tapAt(origin + center);
    await tester.pump();

    expect(engine.phase, WordBloomPhase.scattered);
  });
}
