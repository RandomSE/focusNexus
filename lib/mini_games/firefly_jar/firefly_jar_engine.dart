import 'dart:math' as math;
import 'dart:ui';

import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';

/// A drifting firefly on a sine-influenced path with an independent pulse.
class Firefly {
  Firefly({
    required this.id,
    required this.x,
    required this.y,
    required this.baseY,
    required this.speedX,
    required this.speedY,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.pulsePeriod,
    required this.pulsePhase,
  });

  final int id;
  double x;
  double y;
  double baseY;
  double speedX;
  double speedY;
  final double amplitude;
  final double frequency;
  double phase;
  final double pulsePeriod;
  double pulsePhase;

  /// Glow radius scale oscillating between [pulseScaleMin] and [pulseScaleMax].
  double get pulseScale {
    final wave = 0.5 + 0.5 * math.sin(pulsePhase);
    return FireflyJarConstants.pulseScaleMin +
        (FireflyJarConstants.pulseScaleMax - FireflyJarConstants.pulseScaleMin) *
            wave;
  }
}

/// Soft blink marker inside the jar after a catch.
class JarFirefly {
  JarFirefly({
    required this.nx,
    required this.ny,
    required this.phase,
    required this.radius,
  });

  final double nx;
  final double ny;
  double phase;
  final double radius;
}

/// Static night-sky speck.
class NightStar {
  const NightStar({
    required this.nx,
    required this.ny,
    required this.radius,
    required this.opacity,
  });

  final double nx;
  final double ny;
  final double radius;
  final double opacity;
}

/// Starburst ray for catch feedback.
class CatchRay {
  const CatchRay({required this.angle, required this.length});

  final double angle;
  final double length;
}

/// Burst + curved streak from catch point toward the jar mouth.
class CatchFx {
  CatchFx({
    required this.origin,
    required this.mouth,
    required this.control,
    required this.rays,
  });

  final Offset origin;
  final Offset mouth;
  final Offset control;
  final List<CatchRay> rays;
  double age = 0;

  bool get isDone => age >= FireflyJarConstants.catchStreakLife;

  double get burstOpacity {
    final t = (age / FireflyJarConstants.catchBurstLife).clamp(0.0, 1.0);
    return 1.0 - t;
  }

  bool get showBurst => age < FireflyJarConstants.catchBurstLife;

  Offset get streakPos {
    final t = (age / FireflyJarConstants.catchStreakLife).clamp(0.0, 1.0);
    final u = 1.0 - t;
    return Offset(
      u * u * origin.dx + 2 * u * t * control.dx + t * t * mouth.dx,
      u * u * origin.dy + 2 * u * t * control.dy + t * t * mouth.dy,
    );
  }

  /// Flares to 2x then shrinks to zero along the streak.
  double get travelGlowScale {
    final flare = FireflyJarConstants.catchFlareLife;
    if (age <= flare) {
      return 1.0 + age / flare;
    }
    final remain = FireflyJarConstants.catchStreakLife - flare;
    final t = ((age - flare) / remain).clamp(0.0, 1.0);
    return 2.0 * (1.0 - t);
  }
}

/// Pure playfield simulation: spawn, sine drift, catch FX, timer, jar fill.
class FireflyJarEngine {
  FireflyJarEngine({
    required this.playSize,
    required this.endless,
    required this.baseDifficulty,
    math.Random? random,
  })  : _random = random ?? math.Random() {
    _seedStars();
  }

  Size playSize;
  final bool endless;
  final double baseDifficulty;
  final math.Random _random;

  final List<Firefly> activeFireflies = <Firefly>[];
  final List<JarFirefly> jarFireflies = <JarFirefly>[];
  final List<NightStar> stars = <NightStar>[];
  final List<CatchFx> catchEffects = <CatchFx>[];

  int catchCount = 0;
  double elapsedSeconds = 0;
  bool isFinished = false;
  double jarBoostRemaining = 0;
  int _nextId = 0;

  double get remainingSeconds {
    if (endless) return double.infinity;
    final left = FireflyJarConstants.durationSeconds - elapsedSeconds;
    return left <= 0 ? 0 : left;
  }

  double get durationProgress {
    if (endless) return 0;
    final p = elapsedSeconds / FireflyJarConstants.durationSeconds;
    if (p <= 0) return 0;
    if (p >= 1) return 1;
    return p;
  }

  int get difficultyTick {
    if (!endless) return 0;
    final durationCap = FireflyJarConstants.durationSeconds.toDouble();
    final earlyElapsed = elapsedSeconds < durationCap ? elapsedSeconds : durationCap;
    final earlyTicks =
        (earlyElapsed / FireflyJarConstants.endlessTickSeconds).floor();
    if (elapsedSeconds <= durationCap) return earlyTicks;
    final overtime = elapsedSeconds - durationCap;
    final overtimeTicks =
        (overtime / FireflyJarConstants.endlessOvertimeTickSeconds).floor();
    return earlyTicks + overtimeTicks;
  }

  double get currentDifficulty {
    if (!endless) return baseDifficulty;
    final durationCap = FireflyJarConstants.durationSeconds.toDouble();
    final earlyElapsed = elapsedSeconds < durationCap ? elapsedSeconds : durationCap;
    final earlyTicks =
        (earlyElapsed / FireflyJarConstants.endlessTickSeconds).floor();
    var scale = baseDifficulty *
        (1 + FireflyJarConstants.endlessEarlyDifficultyStep * earlyTicks);
    if (elapsedSeconds > durationCap) {
      final overtimeTicks = ((elapsedSeconds - durationCap) /
              FireflyJarConstants.endlessOvertimeTickSeconds)
          .floor();
      scale *= (1 +
          FireflyJarConstants.endlessOvertimeDifficultyStep * overtimeTicks);
    }
    return scale;
  }

  /// Extra motion multiplier after 90s endless (no fail state, pressure via speed).
  double get endlessMotionScale {
    if (!endless) return 1.0;
    final durationCap = FireflyJarConstants.durationSeconds.toDouble();
    if (elapsedSeconds <= durationCap) return 1.0;
    final overtimeTicks = ((elapsedSeconds - durationCap) /
            FireflyJarConstants.endlessOvertimeTickSeconds)
        .floor();
    return 1.0 + FireflyJarConstants.endlessOvertimeMotionStep * overtimeTicks;
  }

  double get jarFillFraction {
    final raw = catchCount / FireflyJarConstants.jarFillCapacity;
    if (raw <= 0) return 0;
    if (raw >= 1) return 1;
    return raw;
  }

  double get jarBoostStrength {
    if (jarBoostRemaining <= 0) return 0;
    return (jarBoostRemaining / FireflyJarConstants.jarBoostLife).clamp(0.0, 1.0);
  }

  /// Right-side jar strip reserved from free flight / spawn.
  Rect get jarBounds {
    final w = playSize.width * FireflyJarConstants.jarWidthFraction;
    return Rect.fromLTWH(playSize.width - w, 0, w, playSize.height);
  }

  /// Mason jar body rect (shared with painter).
  Rect get jarBodyRect {
    final bounds = jarBounds;
    final jarWidth = bounds.width * 0.82;
    final jarHeight = playSize.height * 0.38;
    final jarLeft = bounds.center.dx - jarWidth / 2;
    final jarTop = playSize.height * 0.30;
    return Rect.fromLTWH(jarLeft, jarTop, jarWidth, jarHeight);
  }

  Offset get jarMouth => Offset(jarBodyRect.center.dx, jarBodyRect.top - 6);

  /// Play area left of the jar.
  Rect get fieldBounds {
    final margin = FireflyJarConstants.spawnMargin;
    return Rect.fromLTRB(
      margin,
      margin,
      jarBounds.left - margin,
      playSize.height - margin,
    );
  }

  void update(double dt) {
    if (isFinished || dt <= 0) return;
    elapsedSeconds += dt;

    if (!endless && elapsedSeconds >= FireflyJarConstants.durationSeconds) {
      elapsedSeconds = FireflyJarConstants.durationSeconds.toDouble();
      isFinished = true;
      return;
    }

    final simDt = dt > 0.1 ? 0.1 : dt;
    if (jarBoostRemaining > 0) {
      jarBoostRemaining = math.max(0, jarBoostRemaining - dt);
    }
    _maintainPopulation();
    _advanceFireflies(simDt);
    _advanceJarGlow(simDt);
    _advanceCatchFx(dt);
  }

  void endRound() {
    isFinished = true;
  }

  /// Returns true when a firefly was caught at [local].
  bool tryCatch(Offset local) {
    if (isFinished) return false;
    Firefly? best;
    var bestDist = double.infinity;
    final maxDist = FireflyJarConstants.catchRadius;

    for (final fly in activeFireflies) {
      final dist = (Offset(fly.x, fly.y) - local).distance;
      final hit = maxDist + FireflyJarConstants.coreRadius;
      if (dist <= hit && dist < bestDist) {
        best = fly;
        bestDist = dist;
      }
    }
    if (best == null) return false;

    final origin = Offset(best.x, best.y);
    activeFireflies.remove(best);
    catchCount += 1;
    jarBoostRemaining = FireflyJarConstants.jarBoostLife;
    catchEffects.add(_buildCatchFx(origin));
    jarFireflies.add(_spawnJarFirefly());
    _softRedistributeJarFireflies();
    _maintainPopulation();
    return true;
  }

  double get _currentJarMassTopNy =>
      FireflyJarConstants.jarMassTopNy(jarFillFraction.clamp(0.08, 1.0));

  /// Places a catch in the least-filled cell of the current jar mass band.
  JarFirefly _spawnJarFirefly() {
    final topNy = _currentJarMassTopNy;
    const bottomNy = FireflyJarConstants.jarMassBottomNy;
    const leftNx = FireflyJarConstants.jarMassLeftNx;
    const rightNx = FireflyJarConstants.jarMassRightNx;
    final cols = FireflyJarConstants.jarPlaceCols;
    final rows = FireflyJarConstants.jarPlaceRows;
    final counts = List<int>.filled(cols * rows, 0);
    final bandH = (bottomNy - topNy).clamp(0.05, 1.0);
    final bandW = rightNx - leftNx;

    for (final jarFly in jarFireflies) {
      if (jarFly.ny < topNy - 0.02 || jarFly.ny > bottomNy + 0.02) continue;
      final col = ((jarFly.nx - leftNx) / bandW * cols).floor().clamp(0, cols - 1);
      final row = ((jarFly.ny - topNy) / bandH * rows).floor().clamp(0, rows - 1);
      counts[row * cols + col] += 1;
    }

    var bestIndex = 0;
    var bestCount = counts[0];
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] < bestCount) {
        bestCount = counts[i];
        bestIndex = i;
      }
    }
    final col = bestIndex % cols;
    final row = bestIndex ~/ cols;
    final nx = leftNx + (col + _random.nextDouble()) / cols * bandW;
    final ny = topNy + (row + _random.nextDouble()) / rows * bandH;
    return JarFirefly(
      nx: nx,
      ny: ny,
      phase: _random.nextDouble() * math.pi * 2,
      radius: 1.6 + _random.nextDouble() * 1.4,
    );
  }

  /// Soft-moves older dots into the expanded mass band as fill grows (FU-1).
  void _softRedistributeJarFireflies() {
    final n = jarFireflies.length;
    if (n < 2) return;
    final topNy = _currentJarMassTopNy;
    const bottomNy = FireflyJarConstants.jarMassBottomNy;
    final bandH = (bottomNy - topNy).clamp(0.05, 1.0);
    final blend = FireflyJarConstants.jarRedistributeBlend;

    final ordered = List<JarFirefly>.from(jarFireflies)
      ..sort((a, b) {
        final byNy = a.ny.compareTo(b.ny);
        return byNy != 0 ? byNy : a.nx.compareTo(b.nx);
      });

    final remapped = <JarFirefly>[];
    for (var i = 0; i < ordered.length; i++) {
      final fly = ordered[i];
      final t = (i + 0.5) / n;
      final targetNy = topNy + t * bandH;
      remapped.add(
        JarFirefly(
          nx: fly.nx,
          ny: fly.ny + (targetNy - fly.ny) * blend,
          phase: fly.phase,
          radius: fly.radius,
        ),
      );
    }
    jarFireflies
      ..clear()
      ..addAll(remapped);
  }

  CatchFx _buildCatchFx(Offset origin) {
    final mouth = jarMouth;
    final mid = Offset(
      (origin.dx + mouth.dx) / 2,
      math.min(origin.dy, mouth.dy) - 40 - _random.nextDouble() * 30,
    );
    final rayCount = 6 + _random.nextInt(3);
    final rays = <CatchRay>[
      for (var i = 0; i < rayCount; i++)
        CatchRay(
          angle: (i / rayCount) * math.pi * 2 + _random.nextDouble() * 0.35,
          length: 8 + _random.nextDouble() * 6,
        ),
    ];
    return CatchFx(origin: origin, mouth: mouth, control: mid, rays: rays);
  }

  void _seedStars() {
    final count = FireflyJarConstants.starCountMin +
        _random.nextInt(
          FireflyJarConstants.starCountMax - FireflyJarConstants.starCountMin + 1,
        );
    for (var i = 0; i < count; i++) {
      stars.add(
        NightStar(
          nx: _random.nextDouble(),
          ny: _random.nextDouble() * 0.8,
          radius: 1.0 + _random.nextDouble() * 0.5,
          opacity: 0.2 + _random.nextDouble() * 0.3,
        ),
      );
    }
  }

  void _maintainPopulation() {
    final target = (FireflyJarConstants.baseActiveCount * currentDifficulty)
        .round()
        .clamp(4, 16);
    while (activeFireflies.length < target) {
      activeFireflies.add(_spawnFirefly());
    }
  }

  Firefly _spawnFirefly() {
    final field = fieldBounds;
    final fromLeft = _random.nextBool();
    final x = fromLeft ? field.left : field.right;
    final baseY =
        field.top + _random.nextDouble() * (field.height.clamp(1, field.height));
    final speedMag = (28 + _random.nextDouble() * 55) * currentDifficulty;
    final speedX = fromLeft ? speedMag : -speedMag;
    final speedY = (_random.nextDouble() - 0.5) * 12;
    final periodSpan =
        FireflyJarConstants.pulsePeriodMax - FireflyJarConstants.pulsePeriodMin;
    return Firefly(
      id: _nextId++,
      x: x,
      y: baseY,
      baseY: baseY,
      speedX: speedX,
      speedY: speedY,
      amplitude: 12 + _random.nextDouble() * 36,
      frequency: 0.6 + _random.nextDouble() * 1.8,
      phase: _random.nextDouble() * math.pi * 2,
      pulsePeriod:
          FireflyJarConstants.pulsePeriodMin + _random.nextDouble() * periodSpan,
      pulsePhase: _random.nextDouble() * math.pi * 2,
    );
  }

  void _advanceFireflies(double dt) {
    final field = fieldBounds;
    final motion = endlessMotionScale;
    for (final fly in activeFireflies) {
      fly.phase += fly.frequency * dt;
      fly.pulsePhase += (math.pi * 2 / fly.pulsePeriod) * dt;
      fly.x += fly.speedX * dt * motion;
      fly.baseY += fly.speedY * dt * motion;
      fly.y = fly.baseY + fly.amplitude * math.sin(fly.phase);

      if (fly.baseY < field.top) {
        fly.baseY = field.top;
        fly.speedY = fly.speedY.abs();
      } else if (fly.baseY > field.bottom) {
        fly.baseY = field.bottom;
        fly.speedY = -fly.speedY.abs();
      }
    }
    activeFireflies.removeWhere(
      (fly) => fly.x < field.left - 40 || fly.x > field.right + 40,
    );
  }

  void _advanceJarGlow(double dt) {
    for (final jarFly in jarFireflies) {
      jarFly.phase += dt * 2.4;
    }
  }

  void _advanceCatchFx(double dt) {
    for (final fx in catchEffects) {
      fx.age += dt;
    }
    catchEffects.removeWhere((fx) => fx.isDone);
  }
}
