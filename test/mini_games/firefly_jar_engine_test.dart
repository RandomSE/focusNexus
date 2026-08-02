import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_engine.dart';

void main() {
  const playSize = Size(400, 700);

  FireflyJarEngine engine({
    bool endless = false,
    int seed = 42,
  }) {
    return FireflyJarEngine(
      playSize: playSize,
      endless: endless,
      baseDifficulty: 1.0,
      random: math.Random(seed),
    );
  }

  group('FireflyJarEngine duration', () {
    test('starts with zero catches and empty jar', () {
      final e = engine();
      expect(e.catchCount, 0);
      expect(e.jarFillFraction, 0);
      expect(e.isFinished, isFalse);
      expect(e.remainingSeconds, FireflyJarConstants.durationSeconds);
    });

    test('finishes after default duration seconds', () {
      final e = engine();
      e.update(FireflyJarConstants.durationSeconds.toDouble());
      expect(e.isFinished, isTrue);
      expect(e.remainingSeconds, 0);
    });

    test('spawns active fireflies over time', () {
      final e = engine();
      e.update(0.5);
      expect(e.activeFireflies, isNotEmpty);
    });

    test('tryCatch hits nearest firefly within radius and fills jar', () {
      final e = engine(seed: 7);
      e.update(1.0);
      expect(e.activeFireflies, isNotEmpty);
      final target = e.activeFireflies.first;
      final before = e.catchCount;
      final hit = e.tryCatch(Offset(target.x, target.y));
      expect(hit, isTrue);
      expect(e.catchCount, before + 1);
      expect(e.jarFillFraction, greaterThan(0));
      expect(
        e.activeFireflies.any((f) => identical(f, target)),
        isFalse,
      );
    });

    test('tryCatch misses when far from all fireflies', () {
      final e = engine();
      e.update(0.5);
      expect(e.tryCatch(const Offset(-200, -200)), isFalse);
      expect(e.catchCount, 0);
    });

    test('fireflies move along sine-influenced paths', () {
      final e = engine(seed: 3);
      e.update(0.2);
      final fly = e.activeFireflies.first;
      final x0 = fly.x;
      final y0 = fly.y;
      e.update(0.4);
      expect(fly.x != x0 || fly.y != y0, isTrue);
    });

    test('jar fill caps at 1.0', () {
      final e = engine(seed: 1);
      for (var i = 0; i < FireflyJarConstants.jarFillCapacity + 5; i++) {
        e.update(0.15);
        if (e.activeFireflies.isEmpty) continue;
        final f = e.activeFireflies.first;
        e.tryCatch(Offset(f.x, f.y));
      }
      expect(e.jarFillFraction, 1.0);
      expect(e.catchCount, greaterThanOrEqualTo(FireflyJarConstants.jarFillCapacity));
    });

    test('ignores updates after finished', () {
      final e = engine();
      e.update(FireflyJarConstants.durationSeconds.toDouble());
      final count = e.catchCount;
      final active = e.activeFireflies.length;
      e.update(1.0);
      expect(e.catchCount, count);
      expect(e.activeFireflies.length, active);
    });
  });

  group('FireflyJarEngine endless', () {
    test('does not auto-finish on duration elapsed', () {
      final e = engine(endless: true);
      e.update(FireflyJarConstants.durationSeconds.toDouble() + 10);
      expect(e.isFinished, isFalse);
    });

    test('endRound finishes and freezes play', () {
      final e = engine(endless: true);
      e.update(2.0);
      e.endRound();
      expect(e.isFinished, isTrue);
      final count = e.catchCount;
      e.update(1.0);
      expect(e.catchCount, count);
    });

    test('difficulty tick rises with elapsed time', () {
      final e = engine(endless: true);
      expect(e.difficultyTick, 0);
      e.update(FireflyJarConstants.endlessTickSeconds.toDouble());
      expect(e.difficultyTick, 1);
      expect(e.currentDifficulty, greaterThan(1.0));
    });

    test('motion and difficulty ramp harder after 90s', () {
      final e = engine(endless: true);
      e.update(FireflyJarConstants.durationSeconds.toDouble());
      final atNinety = e.currentDifficulty;
      final motionAtNinety = e.endlessMotionScale;
      expect(motionAtNinety, 1.0);
      e.update(FireflyJarConstants.endlessOvertimeTickSeconds * 2);
      expect(e.endlessMotionScale, greaterThan(1.0));
      expect(e.currentDifficulty, greaterThan(atNinety));
      expect(e.difficultyTick, greaterThan(6));
    });
  });

  group('FireflyJarEngine presentation', () {
    test('seeds 18-24 stars in the upper 80%', () {
      final e = engine(seed: 9);
      expect(
        e.stars.length,
        inInclusiveRange(
          FireflyJarConstants.starCountMin,
          FireflyJarConstants.starCountMax,
        ),
      );
      expect(e.stars.every((s) => s.ny <= 0.8), isTrue);
      expect(e.stars.every((s) => s.opacity >= 0.2 && s.opacity <= 0.5), isTrue);
    });

    test('fireflies use warm pulse periods in 1.2-2.8s', () {
      final e = engine(seed: 11);
      e.update(0.2);
      for (final fly in e.activeFireflies) {
        expect(
          fly.pulsePeriod,
          inInclusiveRange(
            FireflyJarConstants.pulsePeriodMin,
            FireflyJarConstants.pulsePeriodMax,
          ),
        );
        expect(fly.pulseScale, inInclusiveRange(0.6, 1.0));
      }
    });

    test('tryCatch spawns burst streak and jar boost', () {
      final e = engine(seed: 7);
      e.update(1.0);
      final target = e.activeFireflies.first;
      expect(e.tryCatch(Offset(target.x, target.y)), isTrue);
      expect(e.catchEffects, hasLength(1));
      final fx = e.catchEffects.single;
      expect(fx.rays.length, inInclusiveRange(6, 8));
      expect(e.jarBoostRemaining, FireflyJarConstants.jarBoostLife);
      expect(fx.travelGlowScale, greaterThanOrEqualTo(1.0));
      e.update(0.06);
      expect(e.catchEffects.single.travelGlowScale, greaterThan(1.0));
      e.update(FireflyJarConstants.catchStreakLife);
      expect(e.catchEffects, isEmpty);
      expect(e.jarBoostRemaining, 0);
    });

    test('jar catches spread across a wide band', () {
      final e = engine(seed: 5);
      for (var i = 0; i < 24; i++) {
        e.update(0.2);
        if (e.activeFireflies.isEmpty) continue;
        final f = e.activeFireflies.first;
        e.tryCatch(Offset(f.x, f.y));
      }
      expect(e.jarFireflies.length, greaterThan(12));
      final nxs = e.jarFireflies.map((j) => j.nx).toList()..sort();
      final nys = e.jarFireflies.map((j) => j.ny).toList()..sort();
      expect(nxs.last - nxs.first, greaterThan(0.4));
      expect(nys.last - nys.first, greaterThan(0.25));
      expect(nys.first, lessThan(0.55));
    });

    test('full jar mass reaches the neck opening band', () {
      final e = engine(seed: 1);
      for (var i = 0; i < FireflyJarConstants.jarFillCapacity + 5; i++) {
        e.update(0.15);
        if (e.activeFireflies.isEmpty) continue;
        final f = e.activeFireflies.first;
        e.tryCatch(Offset(f.x, f.y));
      }
      expect(e.jarFillFraction, 1.0);
      final topNy = FireflyJarConstants.jarMassTopNy(1.0);
      expect(topNy, lessThanOrEqualTo(0.08));
      final nys = e.jarFireflies.map((j) => j.ny).toList()..sort();
      expect(nys.first, lessThanOrEqualTo(0.12));
    });

    test('soft-redistributes older jar dots as fill grows', () {
      final e = engine(seed: 12);
      for (var i = 0; i < 6; i++) {
        e.update(0.2);
        if (e.activeFireflies.isEmpty) continue;
        e.tryCatch(Offset(e.activeFireflies.first.x, e.activeFireflies.first.y));
      }
      final earlyTop = e.jarFireflies.map((j) => j.ny).reduce(math.min);
      for (var i = 0; i < 18; i++) {
        e.update(0.2);
        if (e.activeFireflies.isEmpty) continue;
        e.tryCatch(Offset(e.activeFireflies.first.x, e.activeFireflies.first.y));
      }
      final lateTop = e.jarFireflies.map((j) => j.ny).reduce(math.min);
      expect(lateTop, lessThan(earlyTop));
    });
  });
}
