import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/meteor_catch/meteor_catch_engine.dart';

void main() {
  const playSize = Size(400, 700);

  MeteorCatchEngine engine({bool endless = false, int seed = 42}) {
    return MeteorCatchEngine(
      playSize: playSize,
      endless: endless,
      baseDifficulty: 1.0,
      random: math.Random(seed),
    );
  }

  (Offset, Offset) crossingSwipe(Meteor m, {required double alongPath}) {
    final unit = m.velocityUnit;
    final perp = Offset(-unit.dy, unit.dx);
    final point = m.head + unit * alongPath;
    return (point + perp * 8, point - perp * 8);
  }

  group('MeteorCatchEngine duration', () {
    test('starts with zero score and unfinished', () {
      final e = engine();
      expect(e.score, 0);
      expect(e.catchCount, 0);
      expect(e.isFinished, isFalse);
      expect(e.remainingSeconds, MeteorCatchConstants.durationSeconds);
      expect(e.waveIndex, 0);
    });

    test('finishes after exactly duration seconds', () {
      final e = engine();
      e.update(MeteorCatchConstants.durationSeconds.toDouble());
      expect(e.isFinished, isTrue);
      expect(e.remainingSeconds, 0);
    });

    test('spawns meteors over time', () {
      final e = engine();
      e.update(MeteorCatchConstants.approachWarningSeconds + 0.2);
      expect(e.meteors, isNotEmpty);
    });

    test('meteors move across the field', () {
      final e = engine(seed: 3);
      e.update(MeteorCatchConstants.approachWarningSeconds + 0.1);
      final m = e.meteors.first;
      final x0 = m.x;
      final y0 = m.y;
      e.update(0.4);
      expect(m.x != x0 || m.y != y0, isTrue);
    });

    test('trySwipe hits when meteor head overlaps drawn barrier stroke', () {
      final e = engine(seed: 7);
      final target = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      // Barrier through the head (drawn contact), not ahead of it.
      final swipe = crossingSwipe(target, alongPath: 0);
      final before = e.score;
      expect(e.trySwipe(swipe.$1, swipe.$2), isTrue);
      expect(e.score, before + MeteorCatchConstants.standardWorth);
      expect(e.catchBursts, isNotEmpty);
      expect(e.meteors.any((m) => identical(m, target)), isFalse);
    });

    test('trySwipe does not catch when head is farther than contact radius', () {
      final e = engine(seed: 1);
      final m = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.steepVertical,
        crossingSeconds: 5.0,
      );
      final contact = MeteorCatchConstants.contactRadius(
        headScale: m.headScale,
      );
      // Outside visible head+stroke contact, even if old 40px padding would hit.
      final along = contact + 15;
      final swipe = crossingSwipe(m, alongPath: along);
      expect(e.trySwipe(swipe.$1, swipe.$2), isFalse);
      expect(e.score, 0);
      expect(e.catchBursts, isEmpty);
    });

    test('trySwipe misses when far from barrier', () {
      final e = engine();
      e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.steepVertical,
        crossingSeconds: 2.0,
      );
      expect(e.trySwipe(const Offset(10, 10), const Offset(20, 10)), isFalse);
      expect(e.score, 0);
      expect(e.catchBursts, isEmpty);
    });

    test('legacy 40px padding no longer catches early', () {
      final e = engine(seed: 1);
      final m = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      m
        ..x = 50
        ..y = 200
        ..vx = 200
        ..vy = 0;
      // Distance 30 was inside old swipeHitRadiusPx=40 but outside contact (~6).
      expect(
        e.commitTangibleSwipe(const Offset(80, 180), const Offset(80, 220)),
        isTrue,
      );
      e.update(0.001);
      expect(e.score, 0);
      expect(e.meteors.any((meteor) => identical(meteor, m)), isTrue);
    });

    test('swept contact catches when head tunnels past barrier in one tick', () {
      final e = engine(seed: 5);
      final m = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      m
        ..x = 40
        ..y = 200
        ..vx = 400
        ..vy = 0
        ..prevX = 40
        ..prevY = 200;
      expect(
        e.commitTangibleSwipe(const Offset(100, 180), const Offset(100, 220)),
        isTrue,
      );
      // One 0.2s step: 40 -> 120 crosses x=100; endpoints stay outside contact.
      e.update(0.2);
      expect(e.score, MeteorCatchConstants.standardWorth);
      expect(e.meteors.any((meteor) => identical(meteor, m)), isFalse);
    });

    test('miss produces no catch FX (silent miss)', () {
      final e = engine();
      e.spawnForTest(crossingSeconds: 3.0);
      e.addSwipeTrail(const Offset(5, 5), const Offset(15, 5));
      expect(e.trySwipe(const Offset(5, 5), const Offset(15, 5)), isFalse);
      expect(e.catchBursts, isEmpty);
      expect(e.scorePops, isEmpty);
    });

    test('fire catch awards 3 and leaves sparks', () {
      final e = engine(seed: 1);
      e.spawnForTest(
        kind: MeteorKind.fire,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      final m = e.meteors.first;
      final swipe = crossingSwipe(m, alongPath: 0);
      expect(e.trySwipe(swipe.$1, swipe.$2), isTrue);
      expect(e.score, MeteorCatchConstants.fireWorth);
      expect(e.fireSparks, isNotEmpty);
    });

    test('decoy catch penalizes score and does not increase catchCount', () {
      final e = engine(seed: 2);
      e.spawnForTest(kind: MeteorKind.standard, crossingSeconds: 2.0);
      var m = e.meteors.first;
      var swipe = crossingSwipe(m, alongPath: 0);
      e.trySwipe(swipe.$1, swipe.$2);
      expect(e.score, greaterThan(0));
      final prior = e.score;

      e.spawnForTest(kind: MeteorKind.decoy, crossingSeconds: 2.0);
      m = e.meteors.first;
      swipe = crossingSwipe(m, alongPath: 0);
      expect(e.trySwipe(swipe.$1, swipe.$2), isTrue);
      expect(e.score, math.max(0, prior - MeteorCatchConstants.decoyPenalty));
      expect(e.catchCount, 1);
    });

    test('golden awards ten points', () {
      final e = engine(seed: 4);
      e.spawnForTest(kind: MeteorKind.golden, crossingSeconds: 2.0);
      final m = e.meteors.first;
      final swipe = crossingSwipe(m, alongPath: 0);
      expect(e.trySwipe(swipe.$1, swipe.$2), isTrue);
      expect(e.score, MeteorCatchConstants.goldenWorth);
    });

    test('kind weights are ~70/20/10 before endless cluster phase', () {
      final counts = <MeteorKind, int>{
        MeteorKind.standard: 0,
        MeteorKind.ice: 0,
        MeteorKind.fire: 0,
      };
      final sampler = engine(seed: 11);
      for (var i = 0; i < 400; i++) {
        final k = sampler.debugPickKind();
        counts[k] = counts[k]! + 1;
      }
      final total = counts.values.reduce((a, b) => a + b);
      expect(counts[MeteorKind.standard]! / total, closeTo(0.70, 0.08));
      expect(counts[MeteorKind.ice]! / total, closeTo(0.20, 0.08));
      expect(counts[MeteorKind.fire]! / total, closeTo(0.10, 0.08));
    });

    test('crossing-time mix is ~60/25/15 for standard', () {
      final sampler = engine(seed: 19);
      var mid = 0;
      var slow = 0;
      var fast = 0;
      const n = 500;
      for (var i = 0; i < n; i++) {
        final c = sampler.debugPickCrossingSeconds(MeteorKind.standard);
        if (c >= 0.9 - 1e-9 && c <= 1.1 + 1e-9) {
          mid++;
        } else if (c >= 1.3 - 1e-9 && c <= 1.4 + 1e-9) {
          slow++;
        } else if (c >= 0.7 - 1e-9 && c <= 0.8 + 1e-9) {
          fast++;
        }
      }
      expect(mid + slow + fast, n);
      expect(mid / n, closeTo(0.60, 0.08));
      expect(slow / n, closeTo(0.25, 0.08));
      expect(fast / n, closeTo(0.15, 0.08));
    });

    test('anti-parallel trajectories count as parallel', () {
      final e = engine(seed: 8);
      e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      final angle = e.meteors.first.angleRadians;
      expect(e.debugIsDirectionParallelToActive(angle), isTrue);
      expect(e.debugIsDirectionParallelToActive(angle + math.pi), isTrue);
      expect(e.debugIsDirectionParallelToActive(angle + math.pi / 2), isFalse);
    });

    test('spawn offsets when parallel to an active meteor', () {
      final e = engine(seed: 21);
      final first = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 3.0,
      );
      final second = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 3.0,
      );
      final delta = (first.angleRadians - second.angleRadians).abs();
      final wrapped = delta > math.pi ? 2 * math.pi - delta : delta;
      final acute = math.min(wrapped, math.pi - wrapped);
      expect(
        acute * 180 / math.pi,
        greaterThan(MeteorCatchConstants.parallelAngleThresholdDeg),
      );
    });

    test('upward family still exits toward the opposite quadrant', () {
      final e = engine(seed: 8);
      final m = e.spawnForTest(
        kind: MeteorKind.ice,
        family: TrajectoryFamily.upward,
        crossingSeconds: 1.5,
      );
      final entryQ = e.debugQuadrantIndex(m.head);
      final atExit =
          m.head + m.velocityUnit * m.remainingPathDistance(playSize);
      expect(e.debugQuadrantIndex(atExit), entryQ ^ 3);
      // Side-spawned ice still trends upward overall.
      expect(m.vy, lessThan(0));
    });

    test('wave index and speed escalate over time', () {
      final e = engine(seed: 5);
      e.update(1.0);
      final earlyWave = e.waveIndex;
      final earlySpeed = e.waveSpeedMultiplier;
      e.update(MeteorCatchConstants.waveSeconds.toDouble() * 2);
      expect(e.waveIndex, greaterThan(earlyWave));
      expect(e.waveSpeedMultiplier, greaterThan(earlySpeed));
    });

    test('ignores updates and swipes after finished', () {
      final e = engine();
      e.update(MeteorCatchConstants.durationSeconds.toDouble());
      final score = e.score;
      e.update(1.0);
      e.spawnForTest(crossingSeconds: 1.0);
      expect(e.trySwipe(const Offset(0, 0), const Offset(100, 100)), isFalse);
      expect(e.score, score);
    });

    test('meteors despawn off screen without scoring', () {
      final e = engine(seed: 11);
      e.update(0.2);
      final score = e.score;
      e.update(60);
      expect(e.score, score);
    });

    test('swipe trail ages out in 0.5s without requiring a collision', () {
      final e = engine();
      expect(
        e.commitTangibleSwipe(const Offset(0, 0), const Offset(40, 0)),
        isTrue,
      );
      expect(e.swipeTrails, isNotEmpty);
      e.update(MeteorCatchConstants.swipeTrailLife + 0.05);
      expect(e.swipeTrails, isEmpty);
    });

    test('commitTangibleSwipe rejects short taps under min length', () {
      final e = engine();
      final short = MeteorCatchConstants.minTangibleSwipeLength * 0.5;
      expect(
        e.commitTangibleSwipe(Offset.zero, Offset(short, 0)),
        isFalse,
      );
      expect(e.swipeTrails, isEmpty);
      expect(e.trySwipe(Offset.zero, Offset(short, 0)), isFalse);
    });

    test('preview while dragging does not catch until tangible commit', () {
      final e = engine(seed: 7);
      final target = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      final swipe = crossingSwipe(target, alongPath: 20);
      e.beginSwipePreview(swipe.$1);
      e.extendSwipePreview(swipe.$2);
      expect(e.swipePreview, isNotEmpty);
      e.update(0.05);
      expect(e.meteors.any((m) => identical(m, target)), isTrue);
      expect(e.score, 0);

      e.clearSwipePreview();
      expect(e.commitTangibleSwipe(swipe.$1, swipe.$2), isTrue);
      e.update(0.05);
      expect(e.score, MeteorCatchConstants.standardWorth);
      expect(e.meteors.any((m) => identical(m, target)), isFalse);
    });

    test('commitTangiblePolyline keeps curved path points', () {
      final e = engine();
      final points = <Offset>[
        const Offset(40, 40),
        const Offset(80, 40),
        const Offset(80, 90),
        const Offset(40, 90),
        const Offset(40, 50),
      ];
      expect(e.commitTangiblePolyline(points), isTrue);
      expect(e.swipeTrails.single.points, points);
      expect(
        SwipeTrailSegment.pathLength(e.swipeTrails.single.points),
        greaterThanOrEqualTo(MeteorCatchConstants.minTangibleSwipeLength),
      );
    });

    test('tangible catch waits for contact, not predicted arrival', () {
      final e = engine(seed: 9);
      final m = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      m
        ..x = 50
        ..y = 200
        ..vx = 200
        ..vy = 0;
      final contact = MeteorCatchConstants.contactRadius(headScale: m.headScale);
      // Distance 55 >> contact; time to barrier 55/200 = 0.275s (< old 0.3s predict).
      expect(
        e.commitTangibleSwipe(const Offset(105, 180), const Offset(105, 220)),
        isTrue,
      );
      e.update(0.001);
      expect(e.score, 0);
      expect(e.meteors.any((meteor) => identical(meteor, m)), isTrue);

      // Still outside contact after 0.2s (x ~= 90; need x >= 105 - contact).
      e.update(0.2);
      expect(e.score, 0);
      expect(m.x, lessThan(105 - contact));

      // Reach visible overlap (x >= 105 - contact ~= 99).
      e.update(0.05); // x ~= 100
      expect(e.score, MeteorCatchConstants.standardWorth);
      expect(e.meteors.any((meteor) => identical(meteor, m)), isFalse);
    });

    test('same tangible segment can catch multiple meteors before expiry', () {
      final e = engine(seed: 3);
      final first = e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      first
        ..x = 96
        ..y = 200
        ..vx = 120
        ..vy = 0;
      final second = e.spawnForTest(
        kind: MeteorKind.ice,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 2.0,
      );
      second
        ..x = 95
        ..y = 200
        ..vx = 120
        ..vy = 0;

      expect(
        e.commitTangibleSwipe(const Offset(100, 180), const Offset(100, 220)),
        isTrue,
      );
      expect(e.swipeTrails, hasLength(1));
      final barrier = e.swipeTrails.single;

      e.update(0.05);
      expect(e.meteors.any((m) => identical(m, first)), isFalse);
      expect(e.meteors.any((m) => identical(m, second)), isFalse);
      expect(e.swipeTrails, contains(barrier));
      expect(barrier.isDone, isFalse);
      expect(
        e.score,
        greaterThanOrEqualTo(
          MeteorCatchConstants.standardWorth + MeteorCatchConstants.iceWorth,
        ),
      );
    });

    test('catch burst ages out', () {
      final e = engine(seed: 2);
      e.spawnForTest(crossingSeconds: 2.0);
      final m = e.meteors.first;
      final swipe = crossingSwipe(m, alongPath: 0);
      expect(e.trySwipe(swipe.$1, swipe.$2), isTrue);
      expect(e.catchBursts, isNotEmpty);
      final burst = e.catchBursts.single;
      expect(
        burst.particleAngles,
        hasLength(MeteorCatchConstants.starburstParticleCount),
      );
      expect(MeteorCatchConstants.starburstParticleCount, 10);
      expect(MeteorCatchConstants.starburstColor, const Color(0xFFFFE566));
      expect(burst.headFlare, MeteorCatchConstants.headFlareScale);
      expect(MeteorCatchConstants.headFlareScale, 2.5);
      e.update(MeteorCatchConstants.catchFxLife + 0.05);
      expect(e.catchBursts, isEmpty);
    });
  });

  group('MeteorCatchEngine endless phases', () {
    test('does not auto-finish on duration elapsed', () {
      final e = engine(endless: true);
      e.update(MeteorCatchConstants.durationSeconds.toDouble() + 10);
      expect(e.isFinished, isFalse);
    });

    test('endRound finishes and freezes play', () {
      final e = engine(endless: true);
      e.update(2.0);
      e.endRound();
      expect(e.isFinished, isTrue);
      final score = e.score;
      e.update(1.0);
      expect(e.score, score);
    });

    test('max simultaneous rises after 90s and 360s', () {
      final e = engine(endless: true);
      expect(e.maxSimultaneous, 2);
      e.update(91);
      expect(e.maxSimultaneous, 3);
      e.update(270);
      expect(e.maxSimultaneous, 4);
    });

    test('motion escalates 8% every 30s after 90s', () {
      final e = engine(endless: true, seed: 3);
      e.debugSetElapsedSeconds(MeteorCatchConstants.endlessEscalationStart);
      final waveAtStart = e.waveSpeedMultiplier;
      expect(e.debugMotionMultiplier, closeTo(waveAtStart, 1e-9));

      e.debugSetElapsedSeconds(
        MeteorCatchConstants.endlessEscalationStart +
            MeteorCatchConstants.endlessEscalationStepSeconds,
      );
      expect(
        e.debugMotionMultiplier,
        closeTo(
          e.waveSpeedMultiplier *
              (1 + MeteorCatchConstants.endlessEscalationStepFactor),
          1e-9,
        ),
      );
    });

    test('kind mix shifts to ~60/25/15 after cluster phase starts', () {
      final e = engine(endless: true, seed: 5);
      e.debugSetElapsedSeconds(
        MeteorCatchConstants.endlessClusterPhaseStart + 1,
      );
      final counts = <MeteorKind, int>{
        MeteorKind.standard: 0,
        MeteorKind.ice: 0,
        MeteorKind.fire: 0,
      };
      for (var i = 0; i < 400; i++) {
        final k = e.debugPickKind();
        counts[k] = counts[k]! + 1;
      }
      final total = counts.values.reduce((a, b) => a + b);
      expect(counts[MeteorKind.standard]! / total, closeTo(0.60, 0.08));
      expect(counts[MeteorKind.ice]! / total, closeTo(0.25, 0.08));
      expect(counts[MeteorKind.fire]! / total, closeTo(0.15, 0.08));
    });

    test('cluster spawns three meteors within 1.5s from distinct edges', () {
      final e = engine(endless: true, seed: 9);
      e.debugSetElapsedSeconds(MeteorCatchConstants.endlessClusterPhaseStart);
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.debugScheduleClusterAt(e.elapsedSeconds);

      final spawnTimes = <double>[];
      final entries = <Offset>[];
      for (var i = 0; i < 40; i++) {
        final beforeIds = e.meteors.map((m) => m.id).toSet();
        e.update(0.1);
        for (final m in e.meteors) {
          if (!beforeIds.contains(m.id)) {
            spawnTimes.add(e.elapsedSeconds);
            entries.add(m.head);
          }
        }
        if (spawnTimes.length >= 3) break;
      }

      expect(spawnTimes.length, greaterThanOrEqualTo(3));
      expect(
        spawnTimes[2] - spawnTimes[0],
        lessThanOrEqualTo(MeteorCatchConstants.endlessClusterWindow + 1e-6),
      );
      final uniqueish = entries.take(3).map((o) {
        return '${o.dx.round()},${o.dy.round()}';
      }).toSet();
      expect(uniqueish.length, 3);
    });

    test('decoys spawn once per minute during 6-10m with decoy values', () {
      final e = engine(endless: true, seed: 12);
      e.debugSetElapsedSeconds(MeteorCatchConstants.endlessDecoyPhaseStart);
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.debugScheduleDecoyAt(e.elapsedSeconds);
      e.update(0.1);
      expect(e.pendingApproaches.any((p) => p.meteor.kind == MeteorKind.decoy), isTrue);
      e.update(MeteorCatchConstants.approachWarningSeconds);
      final decoys = e.meteors
          .where((m) => m.kind == MeteorKind.decoy)
          .toList();
      expect(decoys, isNotEmpty);
      expect(decoys.first.pointsValue, 0);
      expect(decoys.first.glowPulse, isTrue);

      final now = e.elapsedSeconds;
      e.debugScheduleDecoyAt(now + MeteorCatchConstants.endlessDecoyInterval);
      e.debugSetElapsedSeconds(
        now + MeteorCatchConstants.endlessDecoyInterval - 0.2,
      );
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.update(0.1);
      expect(e.pendingApproaches.any((p) => p.meteor.kind == MeteorKind.decoy), isFalse);
      expect(e.meteors.any((m) => m.kind == MeteorKind.decoy), isFalse);

      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.debugSetElapsedSeconds(now + MeteorCatchConstants.endlessDecoyInterval);
      e.update(0.1);
      expect(e.pendingApproaches.any((p) => p.meteor.kind == MeteorKind.decoy), isTrue);
      e.update(MeteorCatchConstants.approachWarningSeconds);
      expect(e.meteors.any((m) => m.kind == MeteorKind.decoy), isTrue);

      e.debugSetElapsedSeconds(MeteorCatchConstants.endlessDecoyPhaseEnd + 1);
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.debugScheduleDecoyAt(e.elapsedSeconds);
      e.update(0.1);
      expect(e.pendingApproaches.any((p) => p.meteor.kind == MeteorKind.decoy), isFalse);
      expect(e.meteors.any((m) => m.kind == MeteorKind.decoy), isFalse);
    });

    test('golden spawns every 2-3m after 10m with special values', () {
      final e = engine(endless: true, seed: 14);
      e.debugSetElapsedSeconds(MeteorCatchConstants.endlessGoldenPhaseStart);
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.debugScheduleGoldenAt(e.elapsedSeconds);
      e.update(0.1);
      expect(
        e.pendingApproaches.any((p) => p.meteor.kind == MeteorKind.golden),
        isTrue,
      );
      // Promote without a follow-up motion tick (high endless speed can despawn).
      e.update(MeteorCatchConstants.approachWarningSeconds);
      final goldens = e.meteors
          .where((m) => m.kind == MeteorKind.golden)
          .toList();
      expect(goldens, isNotEmpty);
      final g = goldens.first;
      expect(g.pointsValue, MeteorCatchConstants.goldenWorth);
      expect(g.headScale, 2.0);
      expect(g.trailLengthFactor, 2.5);

      final afterFirst = e.elapsedSeconds;
      final scheduledGap = MeteorCatchConstants.endlessGoldenIntervalMin;
      e.debugSetElapsedSeconds(afterFirst + scheduledGap - 0.05);
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.update(0.1);
      expect(
        e.pendingApproaches.any((p) => p.meteor.kind == MeteorKind.golden),
        isFalse,
      );

      e.debugSetElapsedSeconds(
        afterFirst +
            MeteorCatchConstants.endlessGoldenIntervalMin +
            MeteorCatchConstants.endlessGoldenIntervalSpan,
      );
      e.debugScheduleGoldenAt(e.elapsedSeconds);
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.update(0.1);
      expect(
        e.pendingApproaches.any((p) => p.meteor.kind == MeteorKind.golden),
        isTrue,
      );
      e.update(MeteorCatchConstants.approachWarningSeconds);
      expect(e.meteors.any((m) => m.kind == MeteorKind.golden), isTrue);
    });

    test('starfield rotates 1 degree per 8 seconds after 10m', () {
      final e = engine(endless: true, seed: 2);
      e.debugSetElapsedSeconds(MeteorCatchConstants.endlessGoldenPhaseStart);
      final before = e.starfieldRotationRadians;
      e.update(8.0);
      expect(e.starfieldRotationRadians - before, closeTo(math.pi / 180, 1e-9));
    });
  });

  group('MeteorCatchEngine presentation', () {
    test('seeds night stars without image assets', () {
      final e = engine(seed: 9);
      expect(
        e.stars.length,
        inInclusiveRange(
          MeteorCatchConstants.starCountMin,
          MeteorCatchConstants.starCountMax,
        ),
      );
      expect(e.stars.every((s) => s.ny <= 1.0), isTrue);
    });

    test('spawn exits in the opposite screen quadrant', () {
      final e = engine(seed: 21);
      for (var i = 0; i < 40; i++) {
        final m = e.spawnForTest(crossingSeconds: 1.2);
        final entryQ = e.debugQuadrantIndex(m.head);
        final remaining = m.remainingPathDistance(playSize);
        expect(remaining, greaterThan(40));
        final atExit = m.head + m.velocityUnit * remaining;
        final exitQ = e.debugQuadrantIndex(atExit);
        expect(
          exitQ,
          entryQ ^ 3,
          reason: 'entry=$entryQ exit=$exitQ head=${m.head} atExit=$atExit',
        );
        e.meteors.clear();
      }
    });

    test('decoy approach warning is queued with decoy kind', () {
      final e = engine(endless: true, seed: 12);
      e.debugSetElapsedSeconds(MeteorCatchConstants.endlessDecoyPhaseStart);
      e.meteors.clear();
      e.pendingApproaches.clear();
      e.approachWarnings.clear();
      e.debugScheduleDecoyAt(e.elapsedSeconds);
      e.update(0.1);
      expect(e.approachWarnings, isNotEmpty);
      expect(e.approachWarnings.first.kind, MeteorKind.decoy);
    });

    test('trail length is 35-45% of remaining path for standard', () {
      final e = engine(seed: 6);
      final m = e.spawnForTest(kind: MeteorKind.standard, crossingSeconds: 2.0);
      final remaining = m.remainingPathDistance(playSize);
      final tail = m.trailEndFor(playSize, fraction: 0.4);
      final len = (m.head - tail).distance;
      expect(len / remaining, closeTo(0.4, 0.06));
    });

    test('slow normal fast crossing bands map to 35 40 45 percent tails', () {
      Meteor meteor(double crossingSeconds) => Meteor(
        id: crossingSeconds.hashCode,
        kind: MeteorKind.standard,
        pointsValue: MeteorCatchConstants.standardWorth,
        x: 120,
        y: 160,
        vx: 160,
        vy: 100,
        family: TrajectoryFamily.leftRightDown,
        baseCrossingSeconds: crossingSeconds,
        trailLengthFactor: 1,
      );

      final slow = meteor(1.35);
      final normal = meteor(1.0);
      final fast = meteor(0.75);

      expect(slow.baseTailFraction, 0.35);
      expect(normal.baseTailFraction, 0.40);
      expect(fast.baseTailFraction, 0.45);

      final slowLength = (slow.head - slow.trailEndFor(playSize)).distance;
      final normalLength =
          (normal.head - normal.trailEndFor(playSize)).distance;
      final fastLength = (fast.head - fast.trailEndFor(playSize)).distance;
      expect(slowLength, lessThan(normalLength));
      expect(normalLength, lessThan(fastLength));
    });

    test('trail length collapses when past exit plane (no longestSide spike)', () {
      final m = Meteor(
        id: 1,
        kind: MeteorKind.standard,
        pointsValue: 1,
        x: playSize.width + MeteorCatchConstants.spawnMargin + 4,
        y: 200,
        vx: 120,
        vy: 40,
        family: TrajectoryFamily.leftRightDown,
        baseCrossingSeconds: 1.0,
        trailLengthFactor: 1,
      );
      expect(m.remainingPathDistance(playSize), 0);
      expect(m.hasLeftPlayPath(playSize), isTrue);
      expect((m.head - m.trailEndFor(playSize)).distance, 0);
    });

    test('approach warning appears before meteor becomes active', () {
      final e = engine(seed: 2);
      e.update(0.05);
      expect(e.approachWarnings, isNotEmpty);
      expect(e.pendingApproaches, isNotEmpty);
      expect(e.meteors, isEmpty);

      final warning = e.approachWarnings.first;
      expect(warning.anchor.dx, inInclusiveRange(0, playSize.width));
      expect(warning.anchor.dy, inInclusiveRange(0, playSize.height));
      expect(warning.direction.distance, closeTo(1.0, 0.05));

      e.update(MeteorCatchConstants.approachWarningSeconds + 0.05);
      expect(e.meteors, isNotEmpty);
      expect(e.pendingApproaches, isEmpty);
    });

    test('fire tail is 1.5x standard before safe path clamp', () {
      Meteor meteor(MeteorKind kind, double factor) => Meteor(
        id: kind.index,
        kind: kind,
        pointsValue: kind == MeteorKind.fire
            ? MeteorCatchConstants.fireWorth
            : MeteorCatchConstants.standardWorth,
        x: 80,
        y: 100,
        vx: 120,
        vy: 80,
        family: TrajectoryFamily.leftRightDown,
        baseCrossingSeconds: 1.0,
        trailLengthFactor: factor,
      );

      final standard = meteor(MeteorKind.standard, 1);
      final fire = meteor(MeteorKind.fire, 1.5);
      final standardLength =
          (standard.head - standard.trailEndFor(playSize)).distance;
      final fireLength = (fire.head - fire.trailEndFor(playSize)).distance;

      expect(fireLength / standardLength, closeTo(1.5, 0.01));
      expect(
        fireLength,
        lessThanOrEqualTo(fire.remainingPathDistance(playSize) * 0.95),
      );
    });

    test('catch streak rises on catches and breaks on miss', () {
      final e = engine(seed: 7);
      e.spawnForTest(kind: MeteorKind.standard, crossingSeconds: 2.0);
      var m = e.meteors.first;
      var swipe = crossingSwipe(m, alongPath: 0);
      expect(e.trySwipe(swipe.$1, swipe.$2), isTrue);
      expect(e.catchStreak, 1);
      expect(e.bestCatchStreak, 1);
      expect(e.score, MeteorCatchConstants.standardWorth);

      e.spawnForTest(kind: MeteorKind.standard, crossingSeconds: 2.0);
      m = e.meteors.first;
      swipe = crossingSwipe(m, alongPath: 0);
      expect(e.trySwipe(swipe.$1, swipe.$2), isTrue);
      expect(e.catchStreak, 2);
      expect(e.bestCatchStreak, 2);

      e.spawnForTest(
        kind: MeteorKind.standard,
        family: TrajectoryFamily.leftRightDown,
        crossingSeconds: 0.6,
      );
      m = e.meteors.first;
      m
        ..x = -80
        ..y = 40
        ..vx = -200
        ..vy = 0;
      e.update(0.5);
      expect(e.meteors, isEmpty);
      expect(e.catchStreak, 0);
      expect(e.bestCatchStreak, 2);
      expect(e.score, MeteorCatchConstants.standardWorth * 2);
    });

    test('decoy catch resets streak without lowering bestCatchStreak', () {
      final e = engine(seed: 8);
      e.spawnForTest(kind: MeteorKind.standard, crossingSeconds: 2.0);
      var m = e.meteors.first;
      var swipe = crossingSwipe(m, alongPath: 0);
      e.trySwipe(swipe.$1, swipe.$2);
      expect(e.catchStreak, 1);

      e.spawnForTest(kind: MeteorKind.decoy, crossingSeconds: 2.0);
      m = e.meteors.first;
      swipe = crossingSwipe(m, alongPath: 0);
      e.trySwipe(swipe.$1, swipe.$2);
      expect(e.catchStreak, 0);
      expect(e.bestCatchStreak, 1);
    });

    test('approach warning arrow is longer for faster meteors', () {
      final fast = ApproachWarning(
        anchor: Offset.zero,
        direction: const Offset(0, 1),
        kind: MeteorKind.standard,
        baseCrossingSeconds: 0.6,
      );
      final slow = ApproachWarning(
        anchor: Offset.zero,
        direction: const Offset(0, 1),
        kind: MeteorKind.standard,
        baseCrossingSeconds: 1.4,
      );
      expect(fast.arrowLengthScale, greaterThan(slow.arrowLengthScale));
      expect(fast.arrowLengthScale, greaterThan(1.0));
      expect(slow.arrowLengthScale, lessThan(1.0));
    });

    test('steepVertical and upward spawn from left or right only', () {
      final e = engine(seed: 21);
      for (var i = 0; i < 40; i++) {
        e.spawnForTest(
          kind: MeteorKind.standard,
          family: TrajectoryFamily.steepVertical,
          crossingSeconds: 1.0,
        );
      }
      expect(e.meteors, hasLength(40));
      for (final m in e.meteors) {
        expect(
          m.x < 0 || m.x > e.playSize.width,
          isTrue,
          reason: 'steepVertical entry must be left/right, got x=${m.x}',
        );
        expect(
          m.y >= 0 && m.y <= e.playSize.height,
          isTrue,
          reason: 'steepVertical must not spawn from top/bottom, y=${m.y}',
        );
      }
      e.meteors.clear();

      for (var i = 0; i < 40; i++) {
        e.spawnForTest(
          kind: MeteorKind.ice,
          family: TrajectoryFamily.upward,
          crossingSeconds: 1.0,
        );
      }
      expect(e.meteors, hasLength(40));
      for (final m in e.meteors) {
        expect(
          m.x < 0 || m.x > e.playSize.width,
          isTrue,
          reason: 'upward entry must be left/right, got x=${m.x}',
        );
        expect(
          m.y >= 0 && m.y <= e.playSize.height,
          isTrue,
          reason: 'upward must not spawn from top/bottom, y=${m.y}',
        );
      }
    });
  });
}
