import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_engine.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/screens/rain_catcher_play_screen.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/delaying_key_value_storage.dart';
import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

/// Regression for Bug A: Done must await in-flight round persistence.
///
/// Rain Catcher uses the shared [MiniGameRoundCompleteGate] wired on all play
/// screens (Firefly, Meteor, Word Bloom, Stone, Breath).
void main() {
  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
  });

  testWidgets('Done waits for delayed recordScore before popping play route', (
    tester,
  ) async {
    final inner = InMemoryKeyValueStorage();
    await inner.write(key: StorageKeys.points, value: '50');
    final storage = DelayingKeyValueStorage(
      inner,
      delayKeys: {StorageKeys.miniGamesProgress},
      writeDelay: const Duration(milliseconds: 300),
    );

    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    await container.read(achievementServiceProvider).initialize();
    addTearDown(container.dispose);

    final engine = RainCatcherEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
    );
    engine.score = 42;

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RainCatcherPlayScreen(
                        config: const MiniGameRoundConfig(
                          gameId: RainCatcherConstants.gameId,
                          endless: false,
                        ),
                        testEngine: engine,
                      ),
                    ),
                  );
                },
                child: const Text('Open play'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open play'));
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Water'));

    engine.endRound();
    await tester.pump(const Duration(milliseconds: 32));
    await pumpUntilFound(tester, find.text('Done'));

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(RainCatcherPlayScreen), findsOneWidget);
    expect(storage.delayedWriteInFlight || !storage.delayedWriteCompleted, isTrue);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(RainCatcherPlayScreen), findsNothing);
    expect(storage.delayedWriteCompleted, isTrue);
    expect(await inner.read(key: StorageKeys.miniGamesProgress), isNotNull);
  });
}
