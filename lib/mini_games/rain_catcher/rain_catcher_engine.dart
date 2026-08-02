import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';

/// Catchable raindrop with visual scale and fall speed.
class Raindrop {
  Raindrop({
    required this.id,
    required this.x,
    required this.y,
    required this.vy,
    required this.scale,
    required this.height,
  }) : prevY = y;

  final int id;
  final double x;
  double y;
  double prevY;
  final double vy;
  final double scale;
  final double height;

  double get hitRadius => RainCatcherConstants.dropHitRadius * scale;
  double get width => RainCatcherConstants.dropBaseWidth * scale;
}

/// Distant non-interactive rain streak.
class BackgroundRainStreak {
  BackgroundRainStreak({
    required this.x,
    required this.y,
    required this.vy,
    required this.length,
  });

  double x;
  double y;
  final double vy;
  final double length;
}

/// Soft drifting cloud ellipse (normalized coords).
class DriftCloud {
  DriftCloud({
    required this.nx,
    required this.ny,
    required this.radiusX,
    required this.radiusY,
    required this.driftSeconds,
  });

  double nx;
  final double ny;
  final double radiusX;
  final double radiusY;
  final double driftSeconds;
}

/// Catch ripple ring on the lily pad.
class RippleFx {
  RippleFx({required this.origin, this.age = 0});

  final Offset origin;
  double age;

  bool get isDone => age >= RainCatcherConstants.rippleLifeSeconds;

  double get progress =>
      (age / RainCatcherConstants.rippleLifeSeconds).clamp(0.0, 1.0);
}

/// Miss ripple ellipse on the ground puddle.
class SplashFx {
  SplashFx({required this.origin, this.age = 0});

  final Offset origin;
  double age;

  bool get isDone => age >= RainCatcherConstants.missRippleLifeSeconds;

  double get progress =>
      (age / RainCatcherConstants.missRippleLifeSeconds).clamp(0.0, 1.0);
}

/// Tiny catch splash particle arcing upward then down.
class CatchParticle {
  CatchParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });

  double x;
  double y;
  double vx;
  double vy;
  double age = 0;

  bool get isDone => age >= RainCatcherConstants.catchParticleLifeSeconds;

  double get progress =>
      (age / RainCatcherConstants.catchParticleLifeSeconds).clamp(0.0, 1.0);
}

/// Pure playfield simulation: spawn, fall, pad collision, gauge, streak, timer.
class RainCatcherEngine {
  RainCatcherEngine({
    required Size playSize,
    required this.endless,
    required this.baseDifficulty,
    math.Random? random,
  }) : _playSize = playSize,
       _random = random ?? math.Random(),
       padCenterX = playSize.width / 2,
       gauge = RainCatcherConstants.gaugeStartFor(endless: endless) {
    _seedAtmosphere();
    _nextLightningAt =
        RainCatcherConstants.lightningIntervalMin +
        _random.nextDouble() *
            (RainCatcherConstants.lightningIntervalMax -
                RainCatcherConstants.lightningIntervalMin);
  }

  Size _playSize;
  final bool endless;
  final double baseDifficulty;
  final math.Random _random;

  Size get playSize => _playSize;
  set playSize(Size value) {
    _playSize = value;
    padCenterX = padCenterX.clamp(
      _padRadius,
      math.max(_padRadius, value.width - _padRadius),
    );
    if (backgroundRain.isEmpty || clouds.isEmpty) {
      _seedAtmosphere();
    }
  }

  final List<Raindrop> drops = <Raindrop>[];
  final List<BackgroundRainStreak> backgroundRain = <BackgroundRainStreak>[];
  final List<DriftCloud> clouds = <DriftCloud>[];
  final List<RippleFx> ripples = <RippleFx>[];
  final List<SplashFx> splashes = <SplashFx>[];
  final List<CatchParticle> catchParticles = <CatchParticle>[];

  double padCenterX;

  int score = 0;
  int streak = 0;
  int bestStreak = 0;
  double gauge;

  double elapsedSeconds = 0;
  bool isFinished = false;
  bool failed = false;
  bool finishedByTimeout = false;

  /// 1 while a catch flash is active, else ages down.
  double gaugeFlash = 0;

  /// 0-1 lightning screen flash intensity.
  double lightningFlash = 0;

  /// Lightning bolt polyline in play coords (empty when hidden).
  final List<Offset> lightningBolt = <Offset>[];
  double _lightningBoltAge = 999;
  double _nextLightningAt = 20;

  double _spawnAccumulator = 0;
  int _nextId = 0;
  double _nextLandingEarliest = 0;
  bool _seededCatchable = false;

  bool _justCaught = false;
  bool _justMissed = false;
  bool _justFailed = false;

  /// When true, skip catchable spawn/seed (test isolation).
  @visibleForTesting
  bool suppressSpawning = false;

  int get remainingSeconds {
    if (endless) return 0;
    final left = RainCatcherConstants.durationSeconds - elapsedSeconds;
    return left < 0 ? 0 : left.ceil();
  }

  double get _padRadius =>
      playSize.width * RainCatcherConstants.padDiameterFraction / 2;

  double get padTop =>
      playSize.height -
      RainCatcherConstants.padBottomInset -
      _padRadius * 2;

  double get padBottom =>
      playSize.height - RainCatcherConstants.padBottomInset;

  double get padLeft => padCenterX - _padRadius;

  double get padRight => padCenterX + _padRadius;

  double get padCenterY => (padTop + padBottom) / 2;

  double get gaugeCeiling =>
      RainCatcherConstants.gaugeMaxFor(endless: endless);

  void setPadX(double x) {
    padCenterX = x.clamp(
      _padRadius,
      math.max(_padRadius, playSize.width - _padRadius),
    );
  }

  void endRound() {
    isFinished = true;
  }

  bool consumeJustCatch() {
    if (!_justCaught) return false;
    _justCaught = false;
    return true;
  }

  bool consumeJustMiss() {
    if (!_justMissed) return false;
    _justMissed = false;
    return true;
  }

  bool consumeJustFailed() {
    if (!_justFailed) return false;
    _justFailed = false;
    return true;
  }

  void update(double dt) {
    if (isFinished || dt <= 0) return;
    var remaining = dt;
    while (remaining > 0 && !isFinished) {
      final step = remaining > 0.1 ? 0.1 : remaining;
      _advance(step);
      remaining -= step;
    }
  }

  void _advance(double dt) {
    elapsedSeconds += dt;
    if (!endless && elapsedSeconds >= RainCatcherConstants.durationSeconds) {
      elapsedSeconds = RainCatcherConstants.durationSeconds.toDouble();
      isFinished = true;
      finishedByTimeout = true;
      return;
    }

    if (!_seededCatchable && !suppressSpawning) {
      _seedCatchableRain();
      _seededCatchable = true;
    }

    if (!suppressSpawning) {
      _spawnDrops(dt);
    }
    _moveDrops(dt);
    _moveBackground(dt);
    _resolveCollisions();
    _ageFx(dt);
    _applyGaugeRegen(dt);
    _updateLightning(dt);
    _driftClouds(dt);

    if (gaugeFlash > 0) {
      gaugeFlash =
          (gaugeFlash - dt / RainCatcherConstants.gaugeFlashSeconds).clamp(
            0.0,
            1.0,
          );
    }

    // Duration may sit at empty gauge; only Endless ends the round at 0.
    if (endless && gauge <= RainCatcherConstants.gaugeMin) {
      gauge = RainCatcherConstants.gaugeMin;
      isFinished = true;
      failed = true;
      _justFailed = true;
    }
  }

  void _seedAtmosphere() {
    backgroundRain.clear();
    clouds.clear();
    final count =
        RainCatcherConstants.backgroundRainMin +
        _random.nextInt(
          RainCatcherConstants.backgroundRainMax -
              RainCatcherConstants.backgroundRainMin +
              1,
        );
    for (var i = 0; i < count; i++) {
      backgroundRain.add(_makeBackgroundStreak(randomY: true));
    }
    for (var i = 0; i < 3; i++) {
      clouds.add(
        DriftCloud(
          nx: _random.nextDouble(),
          ny: 0.06 + _random.nextDouble() * 0.22,
          radiusX: 0.18 + _random.nextDouble() * 0.16,
          radiusY: 0.04 + _random.nextDouble() * 0.03,
          driftSeconds: 20 + _random.nextDouble() * 10,
        ),
      );
    }
  }

  BackgroundRainStreak _makeBackgroundStreak({required bool randomY}) {
    final speedMul = RainCatcherConstants.speedMultiplier(
      elapsedSeconds,
      endless: endless,
    );
    final base =
        RainCatcherConstants.dropSpeedMin +
        _random.nextDouble() *
            (RainCatcherConstants.dropSpeedMax -
                RainCatcherConstants.dropSpeedMin);
    return BackgroundRainStreak(
      x: _random.nextDouble() * playSize.width,
      y: randomY
          ? _random.nextDouble() * playSize.height
          : -_random.nextDouble() * 40,
      vy: base * RainCatcherConstants.backgroundSpeedFactor * speedMul,
      length: 8 + _random.nextDouble() * 7,
    );
  }

  void _seedCatchableRain() {
    // Force-spawn a full rainy field, then place Y so pad landings are spaced.
    final target =
        RainCatcherConstants.targetActiveDropsMin +
        _random.nextInt(
          RainCatcherConstants.targetActiveDropsMax -
              RainCatcherConstants.targetActiveDropsMin +
              1,
        );
    drops.clear();
    _nextLandingEarliest = 0;
    for (var i = 0; i < target; i++) {
      if (!_forceSpawnDrop()) break;
    }
    if (drops.isEmpty) return;
    final gap = RainCatcherConstants.minLandingIntervalSeconds;
    final firstLanding = 0.35 + _random.nextDouble() * 0.2;
    for (var i = 0; i < drops.length; i++) {
      final drop = drops[i];
      final landingAt = firstLanding + i * gap;
      final travel = math.max(0.05, landingAt - elapsedSeconds);
      drop.y = padTop - drop.vy * travel;
    }
    _nextLandingEarliest = firstLanding + drops.length * gap;
  }

  /// Spawns one drop without the landing-time gate (used for initial density).
  bool _forceSpawnDrop() {
    final maxX = RainCatcherConstants.spawnMaxX(playSize.width);
    if (maxX <= RainCatcherConstants.dropHitRadius * 2) return false;
    final scale =
        RainCatcherConstants.dropScaleMin +
        _random.nextDouble() *
            (RainCatcherConstants.dropScaleMax -
                RainCatcherConstants.dropScaleMin);
    final height =
        (RainCatcherConstants.dropBaseHeightMin +
            _random.nextDouble() *
                (RainCatcherConstants.dropBaseHeightMax -
                    RainCatcherConstants.dropBaseHeightMin)) *
        scale;
    final hitR = RainCatcherConstants.dropHitRadius * scale;
    final x = hitR + _random.nextDouble() * (maxX - hitR * 2);
    final speedMul = RainCatcherConstants.speedMultiplier(
      elapsedSeconds,
      endless: endless,
    );
    final speedMin = RainCatcherConstants.dropSpeedMin * speedMul;
    final speedMax = RainCatcherConstants.dropSpeedMax * speedMul;
    final speed = speedMin + _random.nextDouble() * (speedMax - speedMin);
    final speedT =
        ((speed - speedMin) / (speedMax - speedMin + 1e-6)).clamp(0.0, 1.0);
    drops.add(
      Raindrop(
        id: _nextId++,
        x: x,
        y: -hitR - height,
        vy: speed,
        scale: scale,
        height: height * (0.85 + 0.3 * speedT),
      ),
    );
    return true;
  }

  void _spawnDrops(double dt) {
    final rate = RainCatcherConstants.spawnRatePerSecond(
      elapsedSeconds,
      endless: endless,
    );
    if (rate <= 0) return;
    _spawnAccumulator += rate * dt;
    while (_spawnAccumulator >= 1 &&
        drops.length < RainCatcherConstants.targetActiveDropsMax) {
      if (!_trySpawnOneDrop()) break;
      _spawnAccumulator -= 1;
    }
  }

  bool _trySpawnOneDrop() {
    final maxX = RainCatcherConstants.spawnMaxX(playSize.width);
    if (maxX <= RainCatcherConstants.dropHitRadius * 2) return false;

    final scale =
        RainCatcherConstants.dropScaleMin +
        _random.nextDouble() *
            (RainCatcherConstants.dropScaleMax -
                RainCatcherConstants.dropScaleMin);
    final height =
        (RainCatcherConstants.dropBaseHeightMin +
            _random.nextDouble() *
                (RainCatcherConstants.dropBaseHeightMax -
                    RainCatcherConstants.dropBaseHeightMin)) *
        scale;
    final hitR = RainCatcherConstants.dropHitRadius * scale;
    final x = hitR + _random.nextDouble() * (maxX - hitR * 2);

    final speedMul = RainCatcherConstants.speedMultiplier(
      elapsedSeconds,
      endless: endless,
    );
    final speedMin = RainCatcherConstants.dropSpeedMin * speedMul;
    final speedMax = RainCatcherConstants.dropSpeedMax * speedMul;
    // Spawn above the playfield; travel must match the real center-to-pad path.
    final spawnY = -hitR - height;
    final fallDistance = padTop - spawnY;
    if (fallDistance <= 0 || speedMax <= 0) return false;

    var preferredSpeed =
        speedMin + _random.nextDouble() * (speedMax - speedMin);
    preferredSpeed =
        speedMin +
        (preferredSpeed - speedMin) * (0.55 + 0.45 * ((scale - 0.6) / 0.8));

    var travel = fallDistance / preferredSpeed;
    var landingAt = elapsedSeconds + travel;
    if (landingAt < _nextLandingEarliest) {
      landingAt = _nextLandingEarliest;
      travel = landingAt - elapsedSeconds;
      if (travel < fallDistance / speedMax) return false;
    }
    final speed = fallDistance / travel;
    if (speed < speedMin * 0.85 || speed > speedMax * 1.15) {
      return false;
    }

    final clampedSpeed = speed.clamp(speedMin * 0.85, speedMax * 1.15);
    final speedT =
        ((clampedSpeed - speedMin) / (speedMax - speedMin + 1e-6)).clamp(
          0.0,
          1.0,
        );
    // Recompute landing from the speed we actually store so the gate stays exact.
    final actualLanding = elapsedSeconds + fallDistance / clampedSpeed;
    drops.add(
      Raindrop(
        id: _nextId++,
        x: x,
        y: spawnY,
        vy: clampedSpeed,
        scale: scale,
        height: height * (0.85 + 0.3 * speedT),
      ),
    );
    _nextLandingEarliest =
        actualLanding + RainCatcherConstants.minLandingIntervalSeconds;
    return true;
  }

  void _moveDrops(double dt) {
    for (final drop in drops) {
      drop.prevY = drop.y;
      drop.y += drop.vy * dt;
    }
  }

  void _moveBackground(double dt) {
    final lean = RainCatcherConstants.backgroundRainLeanRadians;
    final driftX = math.tan(lean);
    for (final streak in backgroundRain) {
      streak.y += streak.vy * dt;
      streak.x += streak.vy * dt * driftX;
      if (streak.y - streak.length > playSize.height) {
        streak.y = -streak.length - _random.nextDouble() * 30;
        streak.x = _random.nextDouble() * playSize.width;
      } else if (streak.x < -20) {
        streak.x += playSize.width + 40;
      } else if (streak.x > playSize.width + 20) {
        streak.x -= playSize.width + 40;
      }
    }
  }

  void _driftClouds(double dt) {
    for (final cloud in clouds) {
      cloud.nx -= dt / cloud.driftSeconds;
      if (cloud.nx < -0.35) cloud.nx += 1.7;
    }
  }

  void _resolveCollisions() {
    if (drops.isEmpty) return;
    final caught = <Raindrop>[];
    final missed = <Raindrop>[];
    for (final drop in drops) {
      if (_dropCaught(drop)) {
        caught.add(drop);
      } else if (drop.y - drop.hitRadius > playSize.height) {
        missed.add(drop);
      }
    }
    for (final drop in caught) {
      _catchDrop(drop);
    }
    for (final drop in missed) {
      _missDrop(drop);
    }
  }

  bool _dropCaught(Raindrop drop) {
    final withinX =
        (drop.x + drop.hitRadius) >= padLeft &&
        (drop.x - drop.hitRadius) <= padRight;
    if (!withinX) return false;
    final bandTop = padTop - drop.hitRadius;
    final bandBottom = padBottom + drop.hitRadius;
    final lo = math.min(drop.prevY, drop.y);
    final hi = math.max(drop.prevY, drop.y);
    return hi >= bandTop && lo <= bandBottom;
  }

  void _catchDrop(Raindrop drop) {
    drops.remove(drop);
    score += 1;
    streak += 1;
    if (streak > bestStreak) bestStreak = streak;
    gauge = (gauge + RainCatcherConstants.gaugeCatchFill).clamp(
      RainCatcherConstants.gaugeMin,
      gaugeCeiling,
    );
    final impact = Offset(drop.x, padTop + 4);
    ripples.add(RippleFx(origin: impact));
    _spawnCatchParticles(impact);
    gaugeFlash = 1;
    _justCaught = true;
  }

  void _spawnCatchParticles(Offset origin) {
    final count = 4 + _random.nextInt(3);
    for (var i = 0; i < count; i++) {
      final angle = -math.pi * 0.15 - _random.nextDouble() * math.pi * 0.7;
      final speed = 40 + _random.nextDouble() * 50;
      catchParticles.add(
        CatchParticle(
          x: origin.dx,
          y: origin.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
        ),
      );
    }
  }

  void _missDrop(Raindrop drop) {
    drops.remove(drop);
    streak = 0;
    gauge = (gauge - RainCatcherConstants.gaugeMissDrain).clamp(
      RainCatcherConstants.gaugeMin,
      gaugeCeiling,
    );
    splashes.add(SplashFx(origin: Offset(drop.x, playSize.height - 4)));
    _justMissed = true;
  }

  void _ageFx(double dt) {
    for (final ripple in ripples) {
      ripple.age += dt;
    }
    ripples.removeWhere((r) => r.isDone);

    for (final splash in splashes) {
      splash.age += dt;
    }
    splashes.removeWhere((s) => s.isDone);

    for (final p in catchParticles) {
      p.age += dt;
      p.vy += 220 * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    catchParticles.removeWhere((p) => p.isDone);
  }

  void _applyGaugeRegen(double dt) {
    if (streak < RainCatcherConstants.gaugeRegenStreakMin) return;
    gauge = (gauge + RainCatcherConstants.gaugeRegenPerSecond * dt).clamp(
      RainCatcherConstants.gaugeMin,
      gaugeCeiling,
    );
  }

  void _updateLightning(double dt) {
    if (lightningFlash > 0) {
      lightningFlash =
          (lightningFlash - dt / RainCatcherConstants.lightningFlashSeconds)
              .clamp(0.0, 1.0);
    }
    _lightningBoltAge += dt;
    if (_lightningBoltAge > RainCatcherConstants.lightningBoltSeconds) {
      lightningBolt.clear();
    }
    if (elapsedSeconds < _nextLightningAt) return;
    _nextLightningAt =
        elapsedSeconds +
        RainCatcherConstants.lightningIntervalMin +
        _random.nextDouble() *
            (RainCatcherConstants.lightningIntervalMax -
                RainCatcherConstants.lightningIntervalMin);
    lightningFlash = 1;
    _lightningBoltAge = 0;
    lightningBolt
      ..clear()
      ..addAll(_buildLightningPath());
  }

  List<Offset> _buildLightningPath() {
    final startX = playSize.width * (0.2 + _random.nextDouble() * 0.45);
    var x = startX;
    var y = 0.0;
    final points = <Offset>[Offset(x, y)];
    final segments = 5 + _random.nextInt(3);
    final midY = playSize.height * (0.28 + _random.nextDouble() * 0.18);
    for (var i = 0; i < segments; i++) {
      y += midY / segments;
      x += (_random.nextDouble() - 0.5) * 36;
      points.add(Offset(x, y));
    }
    return points;
  }
}
