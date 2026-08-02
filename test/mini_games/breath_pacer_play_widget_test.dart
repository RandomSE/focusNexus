import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_constants.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/screens/breath_pacer_play_screen.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
  });

  testWidgets('play screen renders phase cue and title', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '400');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: BreathPacerPlayScreen(
            config: MiniGameRoundConfig(
              gameId: BreathPacerConstants.gameId,
              endless: false,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Inhale'));
    expect(find.byType(BreathPacerPlayScreen), findsOneWidget);
    expect(find.text('Calm score'), findsNothing);
  });

  testWidgets('endless mode shows End button', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '400');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: BreathPacerPlayScreen(
            config: MiniGameRoundConfig(
              gameId: BreathPacerConstants.gameId,
              endless: true,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('End'));
    expect(find.text('End'), findsOneWidget);
  });

  testWidgets('ending round continues completion animation', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '400');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          initialRoute: '/breath',
          routes: {
            '/': (_) => const Scaffold(body: Text('Returned home')),
            '/breath': (_) => const BreathPacerPlayScreen(
              config: MiniGameRoundConfig(
                gameId: BreathPacerConstants.gameId,
                endless: true,
              ),
            ),
          },
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('End'));
    await tester.tap(find.text('End'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    final completionOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('breath_completion_opacity')),
    );
    expect(completionOpacity.opacity, greaterThan(0.9));
    // End overlay covers the HUD back button; dismiss via Done (same as rain tests).
    await pumpUntilFound(tester, find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Returned home'), findsOneWidget);
  });
}
