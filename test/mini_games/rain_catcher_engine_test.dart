import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_engine.dart';

void main() {
  RainCatcherEngine engine({bool endless = false, int seed = 1}) {
    return RainCatcherEngine(
      playSize: const Size(400, 700),
      endless: endless,
      baseDifficulty: 1,
      random: math.Random(seed),
    );
  }

  Raindrop testDrop({
    required int id,
    required double x,
    required double y,
    double vy = 200,
  }) {
    return Raindrop(id: id, x: x, y: y, vy: vy, scale: 1, height: 14);
  }

  /// Prime atmosphere seed, then clear catchable drops for isolated cases.
  void clearCatchable(RainCatcherEngine e) {
    e.suppressSpawning = true;
    e.update(0.001);
    e.drops.clear();
    e.score = 0;
    e.streak = 0;
    e.bestStreak = 0;
    e.gauge = RainCatcherConstants.gaugeStartFor(endless: e.endless);
    e.ripples.clear();
    e.splashes.clear();
    e.catchParticles.clear();
  }

  group('RainCatcherConstants pure helpers', () {
    test('duration is 90 seconds with locked achievement maxes', () {
      expect(RainCatcherConstants.durationSeconds, 90);
      expect(RainCatcherConstants.durationMaxAchievement, 150);
      expect(RainCatcherConstants.endlessTarget, 405);
      expect(RainCatcherConstants.streakMaxAchievement, 120);
      expect(RainCatcherConstants.endlessStreakTarget, 200);
    });

    test('duration score tiers are the round 50-150 ladder', () {
      expect(
        RainCatcherConstants.durationTiers,
        const [50, 75, 100, 125, 150],
      );
    });

    test('duration streak tiers are the round 25-120 ladder', () {
      expect(
        RainCatcherConstants.streakTiers,
        const [25, 50, 75, 100, 120],
      );
    });

    test('endless score tiers are 45-step marks through 405', () {
      expect(RainCatcherConstants.endlessTarget, 405);
      expect(
        RainCatcherConstants.endlessTiers,
        const [45, 90, 135, 180, 225, 270, 315, 360, 405],
      );
    });

    test('endless spawn rate stays landing-capped; speed escalates after 90s', () {
      final before = RainCatcherConstants.spawnRatePerSecond(
        89,
        endless: true,
      );
      final justAfter = RainCatcherConstants.spawnRatePerSecond(
        91,
        endless: true,
      );
      final oneStepLater = RainCatcherConstants.spawnRatePerSecond(
        111,
        endless: true,
      );
      final maxRate = 1.0 / RainCatcherConstants.minLandingIntervalSeconds;

      expect(justAfter, greaterThanOrEqualTo(before));
      expect(oneStepLater, lessThanOrEqualTo(maxRate));
      expect(
        RainCatcherConstants.speedMultiplier(111, endless: true),
        greaterThan(RainCatcherConstants.speedMultiplier(89, endless: true)),
      );
    });

    test('fall speed is 1.5x Duration and 2.0x Endless before step ramps', () {
      expect(
        RainCatcherConstants.speedMultiplier(0, endless: false),
        RainCatcherConstants.durationFallSpeedFactor,
      );
      expect(RainCatcherConstants.durationFallSpeedFactor, 1.5);
      expect(
        RainCatcherConstants.speedMultiplier(0, endless: true),
        RainCatcherConstants.endlessFallSpeedFactor,
      );
      expect(RainCatcherConstants.endlessFallSpeedFactor, 2.0);
      expect(
        RainCatcherConstants.speedMultiplier(110, endless: true),
        greaterThan(RainCatcherConstants.endlessFallSpeedFactor),
      );
      expect(
        RainCatcherConstants.speedMultiplier(110, endless: false),
        RainCatcherConstants.durationFallSpeedFactor,
      );
    });

    test('spawnMaxX keeps drops left of the gauge column', () {
      const width = 400.0;
      final maxX = RainCatcherConstants.spawnMaxX(width);
      final gaugeLeft =
          width -
          RainCatcherConstants.gaugeInset -
          RainCatcherConstants.gaugeBarWidth;
      expect(maxX, lessThan(gaugeLeft));
    });
  });

  group('RainCatcherEngine basics', () {
    test('starts centered with the configured gauge, score, and streak', () {
      final e = engine();
      expect(e.score, 0);
      expect(e.streak, 0);
      expect(e.bestStreak, 0);
      expect(e.gauge, RainCatcherConstants.gaugeStartDuration);
      expect(e.padCenterX, 200);
      expect(e.isFinished, isFalse);
      expect(e.failed, isFalse);
      expect(e.backgroundRain, isNotEmpty);
    });

    test('endless starts with a 5-point gauge buffer', () {
      final e = engine(endless: true);
      expect(e.gauge, RainCatcherConstants.gaugeStartEndless);
    });

    test('setPadX clamps within the playfield bounds', () {
      final e = engine();
      e.setPadX(-500);
      expect(e.padCenterX, greaterThanOrEqualTo(0));
      e.setPadX(5000);
      expect(e.padCenterX, lessThanOrEqualTo(400));
    });

    test('endRound marks the round finished immediately', () {
      final e = engine();
      expect(e.isFinished, isFalse);
      e.endRound();
      expect(e.isFinished, isTrue);
      expect(e.failed, isFalse);
    });

    test('seeds a rainy field of catchable drops', () {
      final e = engine();
      e.update(0.016);
      expect(
        e.drops.length,
        greaterThanOrEqualTo(RainCatcherConstants.targetActiveDropsMin),
      );
      expect(
        e.drops.length,
        lessThanOrEqualTo(RainCatcherConstants.targetActiveDropsMax),
      );
      final maxX = RainCatcherConstants.spawnMaxX(e.playSize.width);
      for (final drop in e.drops) {
        expect(drop.x + drop.width / 2, lessThanOrEqualTo(maxX + 1e-6));
      }
    });
  });

  group('RainCatcherEngine collisions', () {
    test('a drop crossing the pad band under the pad is caught', () {
      final e = engine();
      clearCatchable(e);
      e.gauge = 50;
      e.drops.add(testDrop(id: 1, x: e.padCenterX, y: e.padTop));
      e.update(0.01);

      expect(e.score, 1);
      expect(e.streak, 1);
      expect(e.bestStreak, 1);
      final expectedGauge =
          50 +
          RainCatcherConstants.gaugeCatchFill +
          RainCatcherConstants.gaugeRegenPerSecond * 0.01;
      expect(e.gauge, closeTo(expectedGauge, 1e-6));
      expect(e.ripples, isNotEmpty);
      expect(e.catchParticles, isNotEmpty);
      expect(e.consumeJustCatch(), isTrue);
      expect(e.consumeJustCatch(), isFalse);
    });

    test('a drop that falls past the bottom outside the pad is a miss', () {
      final e = engine();
      clearCatchable(e);
      e.gauge = 50;
      e.streak = 3;
      e.drops.add(testDrop(id: 1, x: 10, y: 703));
      e.update(0.1);

      expect(e.streak, 0);
      expect(e.gauge, 50 - RainCatcherConstants.gaugeMissDrain);
      expect(e.splashes, isNotEmpty);
      expect(e.consumeJustMiss(), isTrue);
      expect(e.consumeJustMiss(), isFalse);
    });

    test('gauge is clamped and does not exceed max on repeated catches', () {
      final e = engine();
      clearCatchable(e);
      e.gauge = RainCatcherConstants.gaugeMax - 0.5;
      e.drops.add(testDrop(id: 1, x: e.padCenterX, y: e.padTop));
      e.update(0.01);
      expect(e.gauge, RainCatcherConstants.gaugeMax);
    });

    test('endless gauge clamps to 405, not Duration 150', () {
      final e = engine(endless: true);
      clearCatchable(e);
      e.gauge = RainCatcherConstants.gaugeMaxEndless - 0.5;
      e.drops.add(testDrop(id: 1, x: e.padCenterX, y: e.padTop));
      e.update(0.01);
      expect(e.gauge, RainCatcherConstants.gaugeMaxEndless);
      expect(e.gaugeCeiling, RainCatcherConstants.gaugeMaxEndless);
    });

    test('gauge marks and max use Duration 30-150 and Endless 45-405', () {
      expect(RainCatcherConstants.gaugeMaxDuration, 150);
      expect(
        RainCatcherConstants.gaugeMarkValuesDuration,
        const [30, 60, 90, 120, 150],
      );
      expect(RainCatcherConstants.gaugeMaxEndless, 405);
      expect(
        RainCatcherConstants.gaugeMarkValuesEndless,
        const [45, 90, 135, 180, 225, 270, 315, 360, 405],
      );
      expect(
        RainCatcherConstants.gaugeColorForLevel(0),
        RainCatcherConstants.gaugeTierColors[0],
      );
      expect(
        RainCatcherConstants.gaugeColorForLevel(150),
        RainCatcherConstants.gaugeTierColors.last,
      );
      expect(
        RainCatcherConstants.gaugeColorForLevel(405, endless: true),
        RainCatcherConstants.gaugeTierColors.last,
      );
    });

    test('gauge palette is calm blue through amber with no lime', () {
      expect(
        RainCatcherConstants.gaugeTierColors,
        const [
          Color(0xFF4A90C4),
          Color(0xFF5AAA8A),
          Color(0xFF64C87A),
          Color(0xFFC4AA3A),
          Color(0xFFC45A3A),
        ],
      );
      expect(
        RainCatcherConstants.gaugeTierColors.contains(const Color(0xFF7AC45A)),
        isFalse,
      );
    });

    test('lily pad is garden-scale with a narrow notch', () {
      expect(RainCatcherConstants.padDiameterFraction, inInclusiveRange(0.18, 0.22));
      expect(RainCatcherConstants.padNotchDegrees, inInclusiveRange(30, 35));
      final e = engine();
      expect(e.padRight - e.padLeft, closeTo(400 * 0.20, 0.01));
    });

    test('background rain leans a few degrees from vertical', () {
      expect(
        RainCatcherConstants.backgroundRainLeanDegrees,
        inInclusiveRange(3, 5),
      );
    });

    test('miss drain exceeds catch fill so the gauge is not trivial', () {
      expect(
        RainCatcherConstants.gaugeMissDrain,
        greaterThan(RainCatcherConstants.gaugeCatchFill),
      );
    });

    test('scheduled landings stay at least 500ms apart', () {
      final e = engine(seed: 42);
      for (var i = 0; i < 200; i++) {
        e.update(0.05);
      }
      final midair = e.drops.where((d) => d.y < e.padTop - 20).toList();
      expect(midair.length, greaterThanOrEqualTo(2));
      final landings = midair.map((d) {
        final remaining = (e.padTop - d.y).clamp(0.0, double.infinity);
        return e.elapsedSeconds + remaining / d.vy;
      }).toList()
        ..sort();
      for (var i = 1; i < landings.length; i++) {
        expect(
          landings[i] - landings[i - 1],
          greaterThanOrEqualTo(
            RainCatcherConstants.minLandingIntervalSeconds - 1e-6,
          ),
        );
      }
    });

    test('gauge is clamped and does not go below 0 on repeated misses', () {
      final e = engine();
      clearCatchable(e);
      e.gauge = 1;
      e.drops.add(testDrop(id: 1, x: 10, y: 703));
      e.update(0.1);
      expect(e.gauge, RainCatcherConstants.gaugeMin);
      expect(e.isFinished, isFalse);
      expect(e.failed, isFalse);
    });
  });

  group('RainCatcherEngine gauge and failure', () {
    test('passive regen only applies while streak is at least 1', () {
      final e = engine();
      clearCatchable(e);
      e.gauge = 50;
      e.streak = 0;
      e.update(1.0);
      expect(e.gauge, 50);
    });

    test('passive regen increases the gauge while streak >= 1', () {
      final e = engine();
      clearCatchable(e);
      e.gauge = 50;
      e.streak = 2;
      e.update(1.0);
      expect(e.gauge, greaterThan(50));
    });

    test('Duration at gauge 0 does not fail the round', () {
      final e = engine(endless: false);
      clearCatchable(e);
      e.gauge = 0;
      e.update(0.01);
      expect(e.isFinished, isFalse);
      expect(e.failed, isFalse);
      expect(e.consumeJustFailed(), isFalse);
    });

    test('Endless at gauge 0 fails the round and fires failure once', () {
      final e = engine(endless: true);
      clearCatchable(e);
      e.gauge = 0;
      e.update(0.01);
      expect(e.isFinished, isTrue);
      expect(e.failed, isTrue);
      expect(e.consumeJustFailed(), isTrue);
      expect(e.consumeJustFailed(), isFalse);
    });

    test('a failed Endless round still reports its score and streak', () {
      final e = engine(endless: true);
      clearCatchable(e);
      e.score = 7;
      e.streak = 0;
      e.bestStreak = 5;
      e.gauge = 0;
      e.update(0.01);
      expect(e.isFinished, isTrue);
      expect(e.failed, isTrue);
      expect(e.score, 7);
      expect(e.streak, 0);
      expect(e.bestStreak, 5);
    });
  });

  group('RainCatcherEngine duration and endless timing', () {
    test('duration mode ends exactly at 90s when the gauge survives', () {
      final e = engine(endless: false);
      for (var i = 0; i < 1000 && !e.isFinished; i++) {
        e.gauge = RainCatcherConstants.gaugeMax;
        e.update(0.1);
      }
      expect(e.isFinished, isTrue);
      expect(e.finishedByTimeout, isTrue);
      expect(e.failed, isFalse);
      expect(
        e.elapsedSeconds,
        RainCatcherConstants.durationSeconds.toDouble(),
      );
    });

    test('endless mode does not auto-end after the duration threshold', () {
      final e = engine(endless: true);
      for (var i = 0; i < 1100; i++) {
        e.gauge = RainCatcherConstants.gaugeMax;
        e.update(0.1);
      }
      expect(e.isFinished, isFalse);
      expect(
        e.elapsedSeconds,
        greaterThan(RainCatcherConstants.durationSeconds.toDouble()),
      );
    });

    test('gauge at 0 does not end a Duration round before the 90s timeout', () {
      final e = engine(endless: false);
      clearCatchable(e);
      e.gauge = 1;
      e.drops.add(testDrop(id: 1, x: 10, y: 703));
      e.update(0.1);
      expect(e.gauge, RainCatcherConstants.gaugeMin);
      expect(e.isFinished, isFalse);
      expect(e.failed, isFalse);
      expect(e.finishedByTimeout, isFalse);
    });
  });
}
