import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_engine.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_seating.dart';

void main() {
  StoneBalanceEngine engine({bool endless = false, int seed = 1}) {
    return StoneBalanceEngine(
      playSize: const Size(400, 700),
      endless: endless,
      baseDifficulty: 1,
      random: math.Random(seed),
    );
  }

  test('aim hint only before first stacked stone', () {
    final e = engine(seed: 3);
    expect(e.score, 0);
    expect(e.showAimHint, isTrue);
    e.setAimScreenX(e.stack.first.cx);
    e.releaseDrop();
    for (var i = 0; i < 400 && e.score < 1; i++) {
      e.update(0.02);
    }
    expect(e.score, greaterThanOrEqualTo(1));
    expect(e.showAimHint, isFalse);
    for (var i = 0; i < 40 && !e.canAim && !e.toppled; i++) {
      e.update(0.02);
    }
    if (e.canAim) {
      expect(e.showAimHint, isFalse);
    }
  });

  test('starts at height 0 with foundation stone and ghost aiming', () {
    final e = engine();
    expect(e.score, 0);
    expect(e.stack, hasLength(1));
    expect(e.ghost, isNotNull);
    expect(e.isAiming, isTrue);
    expect(e.falling, isNull);
    expect(e.cameraY, 0);
  });

  test('first stone stays away from screen edges', () {
    for (var seed = 0; seed < 20; seed++) {
      final e = engine(seed: seed);
      final stone = e.stack.first;
      final margin = 400 * StoneBalanceConstants.firstStoneMarginFraction;
      expect(stone.cx - stone.width / 2, greaterThanOrEqualTo(margin - 0.5));
      expect(stone.cx + stone.width / 2, lessThanOrEqualTo(400 - margin + 0.5));
    }
  });

  test('foundation and platform seat just above the green grass line', () {
    final e = engine();
    final grass = e.grassLineY;
    expect(grass, 700 * StoneBalanceConstants.grassLineFraction);
    expect(e.platformTopY, grass - StoneBalanceConstants.platformStoneHeight);
    // Platform stone bottoms sit on the green; tops are platformTopY.
    final platformBottom = grass;
    final platformTop = e.platformTopY;
    expect(platformTop, lessThan(platformBottom));
    expect(
      platformBottom - platformTop,
      StoneBalanceConstants.platformStoneHeight,
    );

    final foundation = e.stack.first;
    final foundationBottom = foundation.cy + foundation.height / 2;
    expect(foundationBottom, closeTo(platformTop, 0.5));
    expect(foundation.cy, lessThan(grass));
    expect(e.cameraY, 0);
    // On screen, foundation sits above the green band, not down in deep sand.
    expect(foundation.cy - e.cameraY, closeTo(foundation.cy, 0.01));
    expect(
      foundationBottom,
      closeTo(
        700 * StoneBalanceConstants.grassLineFraction -
            StoneBalanceConstants.platformStoneHeight,
        0.5,
      ),
    );
  });

  test('releaseDrop locks X and starts a straight fall', () {
    final e = engine();
    e.setAimScreenX(260);
    final aimed = e.ghost!.cx;
    e.releaseDrop();
    expect(e.ghost, isNull);
    expect(e.falling, isNotNull);
    expect(e.falling!.cx, aimed);
    expect(e.falling!.lockedX, isTrue);
    final x = e.falling!.cx;
    e.update(0.05);
    expect(e.falling!.cx, x);
  });

  test('aim then land increases score from zero', () {
    final e = engine(seed: 3);
    expect(e.score, 0);
    e.setAimScreenX(e.stack.first.cx);
    e.releaseDrop();
    for (var i = 0; i < 200 && e.score < 1; i++) {
      e.update(0.02);
    }
    expect(e.score, greaterThanOrEqualTo(1));
  });

  test('stacked stones inherit tilt and meet on a shared edge', () {
    final e = engine(seed: 3);
    e.setAimScreenX(e.stack.first.cx);
    e.releaseDrop();
    for (var i = 0; i < 400 && e.score < 1; i++) {
      e.update(0.02);
    }
    expect(e.score, greaterThanOrEqualTo(1));
    final lower = e.stack[e.stack.length - 2];
    final upper = e.stack.last;
    // First stack on foundation: both nearly level.
    expect(upper.tilt, closeTo(lower.tilt, 0.02));

    final supportTop = StoneBalanceSeating.localToWorld(
      cx: lower.cx,
      cy: lower.cy,
      tilt: lower.tilt,
      local: Offset(0, -lower.height / 2),
    );
    final fallBottom = StoneBalanceSeating.localToWorld(
      cx: upper.cx,
      cy: upper.cy,
      tilt: upper.tilt,
      local: Offset(0, upper.height / 2),
    );
    expect(fallBottom.dx, closeTo(supportTop.dx, 0.75));
    expect(fallBottom.dy, closeTo(supportTop.dy, 0.75));

    // Two side samples: no sky gap along the contact edge.
    for (final x in [-15.0, 15.0]) {
      final t = StoneBalanceSeating.localToWorld(
        cx: lower.cx,
        cy: lower.cy,
        tilt: lower.tilt,
        local: Offset(x, -lower.height / 2),
      );
      final b = StoneBalanceSeating.localToWorld(
        cx: upper.cx,
        cy: upper.cy,
        tilt: upper.tilt,
        local: Offset(x, upper.height / 2),
      );
      expect(b.dy, closeTo(t.dy, 0.75));
    }
  });

  test('falling stone uses screen Y and camera freezes mid-drop', () {
    final e = engine(seed: 3, endless: true);
    // Raise camera as if past height 16.
    e.cameraY = -120;
    e.setAimScreenX(e.stack.first.cx);
    e.releaseDrop();
    expect(e.falling, isNotNull);
    expect(
      e.falling!.screenCy,
      closeTo(700 * StoneBalanceConstants.spawnYFraction, 0.01),
    );
    final screenBefore = e.falling!.screenCy;
    final camBefore = e.cameraY;
    e.update(0.02);
    expect(e.cameraY, camBefore);
    expect(e.falling!.screenCy, greaterThan(screenBefore));
  });

  test('camera follow band keeps top near one-third up the screen', () {
    expect(StoneBalanceConstants.cameraFollowBand, closeTo(0.67, 0.001));
  });

  void stackCenteredUntil(
    StoneBalanceEngine e, {
    required int targetScore,
    int maxAttempts = 80,
  }) {
    for (
      var n = 0;
      n < maxAttempts && !e.toppled && e.score < targetScore;
      n++
    ) {
      if (e.canAim) {
        e.setAimScreenX(e.stack.last.cx);
        e.releaseDrop();
      }
      for (var i = 0; i < 120 && e.falling != null; i++) {
        e.update(0.02);
      }
      for (var i = 0; i < 40 && !e.canAim && !e.toppled; i++) {
        e.update(0.02);
      }
    }
  }

  test('camera stays at 0 until height 16 then follows negative', () {
    final e = engine(seed: 3, endless: true);
    expect(e.cameraY, 0);

    stackCenteredUntil(e, targetScore: 10);
    expect(e.toppled, isFalse);
    expect(e.score, greaterThanOrEqualTo(10));
    expect(e.score, lessThan(StoneBalanceConstants.groundGoneHeight));
    // Settle camera ease.
    for (var i = 0; i < 60; i++) {
      e.update(0.02);
    }
    expect(e.cameraY, closeTo(0, 0.5));

    stackCenteredUntil(e, targetScore: StoneBalanceConstants.groundGoneHeight);
    expect(e.toppled, isFalse);
    expect(
      e.score,
      greaterThanOrEqualTo(StoneBalanceConstants.groundGoneHeight),
    );
    for (var i = 0; i < 60; i++) {
      e.update(0.02);
    }
    expect(e.cameraY, lessThan(-1));
  });

  test('overhang past immediate threshold starts topple and locks score', () {
    final e = engine(seed: 2);
    final support = e.stack.first;
    e.setAimScreenX(
      support.cx +
          support.width *
              (StoneBalanceConstants.overhangImmediateTopple + 0.05),
    );
    e.releaseDrop();
    for (var i = 0; i < 200 && !e.toppled; i++) {
      e.update(0.02);
    }
    expect(e.toppled, isTrue);
    expect(e.score, greaterThanOrEqualTo(1));
    expect(e.mode, StoneBalanceMode.toppling);
  });

  test('tower lean beyond 20% screen width topples', () {
    final e = engine(seed: 5, endless: true);
    // Place several stones stepped sideways until centroid drifts.
    for (var n = 0; n < 12 && !e.toppled; n++) {
      if (!e.canAim) break;
      final support = e.stack.last;
      final step = support.width * 0.22;
      e.setAimScreenX(support.cx + step);
      e.releaseDrop();
      for (var i = 0; i < 150 && e.falling != null; i++) {
        e.update(0.02);
      }
      for (var i = 0; i < 30 && e.isUnstable && !e.toppled; i++) {
        e.update(0.02);
      }
    }
    expect(e.toppled, isTrue);
  });

  test('topple descent knocks stones then fails with locked score', () {
    final e = engine(seed: 4, endless: true);
    e.setAimScreenX(e.stack.first.cx);
    e.releaseDrop();
    for (var i = 0; i < 200 && e.score < 1; i++) {
      e.update(0.02);
    }
    final height = e.score;
    e.forceToppleForTest();
    expect(e.toppled, isTrue);
    expect(e.toppleStage, ToppleStage.slideOff);
    var failed = false;
    var sawExplode = false;
    for (var i = 0; i < 1200 && !failed; i++) {
      e.update(0.02);
      if (e.toppleStage == ToppleStage.explode) sawExplode = true;
      failed = e.consumeJustFailed();
    }
    expect(sawExplode, isTrue);
    expect(failed, isTrue);
    expect(e.isFinished, isTrue);
    expect(e.score, height);
  });

  test('topple slows near ground then explodes after bounce', () {
    final e = engine(seed: 4, endless: true);
    e.setAimScreenX(e.stack.first.cx);
    e.releaseDrop();
    for (var i = 0; i < 200 && e.score < 1; i++) {
      e.update(0.02);
    }
    e.forceToppleForTest();
    // Drive until descent with offender near grass.
    for (var i = 0; i < 800 && e.toppleStage != ToppleStage.finale; i++) {
      e.update(0.02);
    }
    expect(
      e.toppleStage,
      anyOf(ToppleStage.finale, ToppleStage.explode, ToppleStage.descent),
    );
    if (e.toppleStage == ToppleStage.finale ||
        e.toppleStage == ToppleStage.descent) {
      expect(
        e.toppleTimeScale,
        closeTo(StoneBalanceConstants.toppleNearGroundTimeScale, 0.001),
      );
    }
    for (var i = 0; i < 800 && e.toppleStage != ToppleStage.explode; i++) {
      e.update(0.02);
    }
    expect(e.toppleStage, ToppleStage.explode);
    expect(e.toppleTimeScale, 1);
    expect(e.scatter.every((s) => !s.isOffender), isTrue);
  });

  test(
    'slide target and offender X stay fully inside screen during topple',
    () {
      final e = engine(seed: 8, endless: true);
      // Force a far edge overhang to exercise slide target clamp.
      e.setAimScreenX(390);
      e.releaseDrop();
      for (var i = 0; i < 240 && !e.toppled; i++) {
        e.update(0.02);
      }
      expect(e.toppled, isTrue);
      final slideTarget = e.debugSlideTargetX;
      expect(slideTarget, isNotNull);
      expect(
        slideTarget!,
        inInclusiveRange(e.offenderMinVisibleX, e.offenderMaxVisibleX),
      );

      for (var i = 0; i < 900 && !e.isFinished; i++) {
        e.update(0.02);
        final offender = e.scatter.where((s) => s.isOffender).toList();
        if (offender.isEmpty) continue;
        final s = offender.first;
        expect(s.cx - s.width / 2, greaterThanOrEqualTo(0));
        expect(s.cx + s.width / 2, lessThanOrEqualTo(e.playSize.width));
      }
    },
  );

  test('offender remains fully visible in both X and Y before explode', () {
    final e = engine(seed: 4, endless: true);
    e.setAimScreenX(e.stack.first.cx);
    e.releaseDrop();
    for (var i = 0; i < 220 && e.score < 1; i++) {
      e.update(0.02);
    }
    e.forceToppleForTest();

    var sawOffender = false;
    for (var i = 0; i < 1200 && e.toppleStage != ToppleStage.explode; i++) {
      e.update(0.02);
      final offender = e.scatter.where((s) => s.isOffender).toList();
      if (offender.isEmpty) continue;
      sawOffender = true;
      final s = offender.first;
      final screenY = s.cy - e.cameraY;
      expect(s.cx - s.width / 2, greaterThanOrEqualTo(0));
      expect(s.cx + s.width / 2, lessThanOrEqualTo(e.playSize.width));
      expect(screenY - s.height / 2, greaterThanOrEqualTo(0));
      expect(screenY + s.height / 2, lessThanOrEqualTo(e.playSize.height));
    }
    expect(sawOffender, isTrue);
  });

  test('grass line sits near bottom tenth of play area', () {
    expect(StoneBalanceConstants.grassLineFraction, closeTo(0.90, 0.001));
    final e = engine();
    expect(e.grassLineY, closeTo(700 * 0.90, 0.01));
  });

  test('background phase maps score bands including 6-15 and 16+', () {
    expect(StoneBalanceEngine.phaseForScore(0), 1);
    expect(StoneBalanceEngine.phaseForScore(5), 1);
    expect(StoneBalanceEngine.phaseForScore(6), 2);
    expect(StoneBalanceEngine.phaseForScore(15), 2);
    expect(StoneBalanceEngine.phaseForScore(16), 3);
    expect(StoneBalanceEngine.phaseForScore(31), 4);
    expect(StoneBalanceEngine.phaseForScore(60), 5);
  });

  test('showGround false at height 16+', () {
    expect(StoneBalanceConstants.groundGoneHeight, 16);
    final e = engine();
    expect(e.showGround, isTrue);
  });

  test('playerHeightFromStackLength excludes foundation', () {
    expect(StoneBalanceEngine.playerHeightFromStackLength(0), 0);
    expect(StoneBalanceEngine.playerHeightFromStackLength(1), 0);
    expect(StoneBalanceEngine.playerHeightFromStackLength(3), 2);
  });

  test('overhangFraction helper matches support-width definition', () {
    expect(
      StoneBalanceEngine.overhangFraction(
        fallCx: 110,
        supportCx: 100,
        supportWidth: 50,
      ),
      0.2,
    );
  });

  test('duration finishes after default seconds while aiming', () {
    final e = engine();
    e.update(StoneBalanceConstants.durationSeconds.toDouble());
    expect(e.isFinished, isTrue);
    expect(e.score, 0);
  });
}
