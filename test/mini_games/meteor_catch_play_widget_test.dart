import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/meteor_catch/meteor_catch_engine.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/screens/meteor_catch_play_screen.dart';
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
          home: MeteorCatchPlayScreen(
            config: MiniGameRoundConfig(
              gameId: MeteorCatchConstants.gameId,
              endless: false,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Score'));
    expect(find.byType(MeteorCatchPlayScreen), findsOneWidget);
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
          home: MeteorCatchPlayScreen(
            config: MiniGameRoundConfig(
              gameId: MeteorCatchConstants.gameId,
              endless: true,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('End'));
    expect(find.byType(MeteorCatchPlayScreen), findsOneWidget);
  });

  testWidgets('swipe gesture catches meteor, shows trail and score pop', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final engine = MeteorCatchEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
      random: math.Random(7),
    );
    engine.spawnForTest(
      kind: MeteorKind.standard,
      family: TrajectoryFamily.leftRightDown,
      crossingSeconds: 2.0,
    );

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: MeteorCatchPlayScreen(
            config: const MiniGameRoundConfig(
              gameId: MeteorCatchConstants.gameId,
              endless: false,
            ),
            testEngine: engine,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Score'));
    expect(find.text('0'), findsWidgets);

    // Re-seat after layout so gesture coords match the live playSize.
    final m = engine.meteors.first;
    m.x = engine.playSize.width * 0.35;
    m.y = engine.playSize.height * 0.45;
    // Hold still during the drag so lift-time contact is reliable.
    m.vx = 0;
    m.vy = 0;
    const unit = Offset(1, 0);
    final perp = Offset(-unit.dy, unit.dx);
    // Barrier through the head so lift commits an immediate catch (SFX path).
    final along = m.head;
    final from = along + perp * 16;
    final to = along - perp * 16;

    final paintBox =
        tester.renderObject(find.byType(CustomPaint).first) as RenderBox;
    final origin = paintBox.localToGlobal(Offset.zero);

    final sound = container.read(soundServiceProvider);
    final clicksBefore = sound.meteorPlayStartCount;

    await tester.timedDragFrom(
      origin + from,
      to - from,
      const Duration(milliseconds: 80),
    );
    // Finger lift commits tangible; catch feedback must fire on lift too.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(engine.score, MeteorCatchConstants.standardWorth);
    expect(sound.meteorPlayStartCount, greaterThan(clicksBefore));
    expect(engine.swipeTrails, isNotEmpty);
    expect(engine.scorePops, isNotEmpty);
    expect(engine.scorePops.last.delta, MeteorCatchConstants.standardWorth);
    expect(find.text('${MeteorCatchConstants.standardWorth}'), findsWidgets);
    expect(find.text('+${MeteorCatchConstants.standardWorth}'), findsOneWidget);

    engine.update(MeteorCatchConstants.swipeTrailLife + 0.05);
    expect(engine.swipeTrails, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('short tap does not create tangible trail or catch', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final engine = MeteorCatchEngine(
      playSize: const Size(400, 700),
      endless: false,
      baseDifficulty: 1.0,
      random: math.Random(3),
    );
    engine.spawnForTest(
      kind: MeteorKind.standard,
      family: TrajectoryFamily.leftRightDown,
      crossingSeconds: 2.0,
    );

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: MeteorCatchPlayScreen(
            config: const MiniGameRoundConfig(
              gameId: MeteorCatchConstants.gameId,
              endless: false,
            ),
            testEngine: engine,
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Score'));

    final m = engine.meteors.first;
    m.x = engine.playSize.width * 0.4;
    m.y = engine.playSize.height * 0.5;
    m.vx = 100;
    m.vy = 0;

    final paintBox =
        tester.renderObject(find.byType(CustomPaint).first) as RenderBox;
    final origin = paintBox.localToGlobal(Offset.zero);
    final start = origin + m.head;

    await tester.timedDragFrom(
      start,
      const Offset(3, 0),
      const Duration(milliseconds: 40),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(engine.swipeTrails, isEmpty);
    expect(engine.score, 0);
    expect(engine.catchBursts, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
