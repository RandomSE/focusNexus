import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Shared ids and tunables for Meteor Catch.
abstract final class MeteorCatchConstants {
  static const String gameId = 'meteor_catch';
  static const String title = 'Meteor Catch';
  static const String description =
      'Draw a swipe, then lift to leave a brief barrier that catches meteors.';

  static const int durationSeconds = 90;
  static const int waveSeconds = 15;

  static const int unlockCost = 250;
  static const int playCost = 90;
  static const int endlessCost = 130;
  static const double baseDifficulty = 1.0;

  static const double meteorHeadRadius = 5.0;
  static const double trailFractionMin = 0.35;
  static const double trailFractionMax = 0.45;

  /// Drawn barrier stroke width (must match the play painter).
  static const double barrierStrokeWidth = 2;

  /// Contact uses meteor head radius + half stroke so the hitbox matches the
  /// drawn line (no extra catch padding beyond the visible stroke).
  static double contactRadius({double headScale = 1.0}) =>
      meteorHeadRadius * headScale + barrierStrokeWidth / 2;

  /// Lead-in warning before a meteor becomes tangible / visible as a streak.
  static const double approachWarningSeconds = 0.7;

  /// Tangible barrier lifetime after finger lift (seconds).
  static const double swipeTrailLife = 0.5;

  /// Minimum drag length to commit a tangible barrier (~meteor diameter).
  static const double minTangibleSwipeLength = meteorHeadRadius * 2;

  static const double catchFxLife = 0.4;
  static const double scorePopLife = 0.35;
  static const double sparkLife = 0.5;

  static const double headFlareScale = 2.5;
  static const int starburstParticleCount = 10;
  static const Color starburstColor = Color(0xFFFFE566);

  static const int decoyPenalty = 2;
  static const int goldenWorth = 10;
  static const int fireWorth = 3;
  static const int standardWorth = 1;
  static const int iceWorth = 1;

  static const double waveSpeedStep = 0.12;
  static const int durationMaxSimultaneous = 2;

  static const double parallelAngleThresholdDeg = 12;
  static const double parallelOffsetMinDeg = 15;
  static const double parallelOffsetMaxDeg = 25;

  /// Endless phase thresholds (seconds).
  static const double endlessEscalationStart = 90;
  static const double endlessEscalationStepSeconds = 30;
  static const double endlessEscalationStepFactor = 0.08;
  static const double endlessClusterPhaseStart = 180;
  static const double endlessClusterPhaseEnd = 360;
  static const double endlessDecoyPhaseStart = 360;
  static const double endlessDecoyPhaseEnd = 600;
  static const double endlessGoldenPhaseStart = 600;
  static const double endlessClusterWindow = 1.5;
  static const double endlessClusterSpawnGap = 0.5;
  static const double endlessDecoyInterval = 60;
  static const double endlessGoldenIntervalMin = 120;
  static const double endlessGoldenIntervalSpan = 60;
  static const double starRotationDegPerEightSeconds = 1;

  static const double spawnMargin = 32;

  static const int starCountMin = 24;
  static const int starCountMax = 36;

  static const String clickSoundAsset = 'sounds/meteor_click.mp3';
}

enum MeteorKind { standard, ice, fire, decoy, golden }

enum TrajectoryFamily {
  leftRightDown,
  rightLeftDown,
  steepVertical,
  nearlyHorizontal,
  upward,
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

/// Diagonal streaking meteor with kind-specific scoring and trail.
class Meteor {
  Meteor({
    required this.id,
    required this.kind,
    required this.pointsValue,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.family,
    required this.baseCrossingSeconds,
    required this.trailLengthFactor,
    this.headScale = 1.0,
    this.glowPulse = false,
    List<FireSpark>? sparks,
  }) : sparks = sparks ?? <FireSpark>[],
       prevX = x,
       prevY = y;

  final int id;
  final MeteorKind kind;
  final int pointsValue;
  double x;
  double y;

  /// Head position before the latest motion step (for swept contact).
  double prevX;
  double prevY;
  double vx;
  double vy;
  final TrajectoryFamily family;
  final double baseCrossingSeconds;
  final double trailLengthFactor;
  final double headScale;
  final bool glowPulse;
  final List<FireSpark> sparks;
  bool catchFxActive = false;

  Offset get head => Offset(x, y);

  double get speed => math.sqrt(vx * vx + vy * vy);

  Offset get velocityUnit {
    final s = speed;
    if (s <= 0.001) return Offset.zero;
    return Offset(vx / s, vy / s);
  }

  double get angleRadians => math.atan2(vy, vx);

  /// Maps the requested crossing-time bands to tail proportions.
  ///
  /// Ice crossing times include a 0.15s type adjustment, so normalize that
  /// before classifying slow, normal, and fast bands.
  double get baseTailFraction {
    final normalizedCrossing =
        baseCrossingSeconds - (kind == MeteorKind.ice ? 0.15 : 0);
    if (normalizedCrossing >= 1.25) {
      return MeteorCatchConstants.trailFractionMin;
    }
    if (normalizedCrossing <= 0.85) {
      return MeteorCatchConstants.trailFractionMax;
    }
    return 0.40;
  }

  /// Approximate remaining travel distance to leave [playSize] along velocity.
  double remainingPathDistance(Size playSize) {
    final unit = velocityUnit;
    if (unit == Offset.zero) return playSize.longestSide;
    const margin = MeteorCatchConstants.spawnMargin;
    final w = playSize.width;
    final h = playSize.height;
    var tExit = double.infinity;
    if (unit.dx > 0.001) {
      tExit = math.min(tExit, (w + margin - x) / unit.dx);
    } else if (unit.dx < -0.001) {
      tExit = math.min(tExit, (-margin - x) / unit.dx);
    }
    if (unit.dy > 0.001) {
      tExit = math.min(tExit, (h + margin - y) / unit.dy);
    } else if (unit.dy < -0.001) {
      tExit = math.min(tExit, (-margin - y) / unit.dy);
    }
    if (!tExit.isFinite || tExit <= 0) return 0;
    return tExit;
  }

  /// True when the head has already crossed the exit plane for [playSize].
  bool hasLeftPlayPath(Size playSize) => remainingPathDistance(playSize) <= 0;

  /// Tail tip: 35-45% of remaining canvas path, scaled by kind factor.
  Offset trailEndFor(Size playSize, {double? fraction}) {
    final unit = velocityUnit;
    final remaining = remainingPathDistance(playSize);
    if (remaining <= 0 || unit == Offset.zero) {
      return Offset(x, y);
    }
    final clampedFraction = (fraction ?? baseTailFraction).clamp(
      MeteorCatchConstants.trailFractionMin,
      MeteorCatchConstants.trailFractionMax,
    );
    final len = (remaining * clampedFraction * trailLengthFactor).clamp(
      remaining >= 40 ? 20.0 : 0.0,
      math.max(0.0, remaining * 0.95),
    );
    if (len < 1.0) {
      return Offset(x, y);
    }
    return Offset(x - unit.dx * len, y - unit.dy * len);
  }

  Offset get tail => trailEndFor(const Size(400, 700));

  bool isOffscreenFor(Size playSize) {
    const margin = 64;
    return x < -margin ||
        y < -margin ||
        x > playSize.width + margin ||
        y > playSize.height + margin;
  }
}

/// Tangible swipe barrier (polyline) that can catch meteors until it expires.
class SwipeTrailSegment {
  SwipeTrailSegment({required List<Offset> points, this.age = 0})
    : assert(points.length >= 2),
      points = List<Offset>.unmodifiable(List<Offset>.from(points));

  final List<Offset> points;
  double age;

  bool get isDone => age >= MeteorCatchConstants.swipeTrailLife;

  /// Sum of consecutive segment lengths.
  static double pathLength(List<Offset> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }
}

/// Starburst catch feedback at intercept point.
class CatchBurst {
  CatchBurst({
    required this.origin,
    required this.particleAngles,
    required this.kind,
    required this.travelUnit,
    this.age = 0,
  });

  final Offset origin;
  final List<double> particleAngles;
  final MeteorKind kind;

  /// Unit vector opposite travel (tail direction behind the head).
  final Offset travelUnit;
  double age;

  bool get isDone => age >= MeteorCatchConstants.catchFxLife;

  double get opacity {
    final t = (age / MeteorCatchConstants.catchFxLife).clamp(0.0, 1.0);
    return 1.0 - t;
  }

  double get headFlare {
    final t = (age / MeteorCatchConstants.catchFxLife).clamp(0.0, 1.0);
    return MeteorCatchConstants.headFlareScale * (1.0 - t * 0.6);
  }

  /// Tail elongates toward 80% of [canvasWidth] over the FX life.
  double elongatedTailLength(double canvasWidth) {
    final t = (age / MeteorCatchConstants.catchFxLife).clamp(0.0, 1.0);
    return canvasWidth * 0.8 * t;
  }
}

/// Floating score delta after a catch.
class ScorePop {
  ScorePop({required this.delta, this.age = 0});

  final int delta;
  double age;

  bool get isDone => age >= MeteorCatchConstants.scorePopLife;
}

/// Perpendicular spark left behind when a fire meteor is caught.
class FireSpark {
  FireSpark({required this.offset, this.age = 0});

  final Offset offset;
  double age;

  bool get isDone => age >= MeteorCatchConstants.sparkLife;
}

/// Lead-in marker at the screen edge before a meteor becomes active.
class ApproachWarning {
  ApproachWarning({
    required this.anchor,
    required this.direction,
    required this.kind,
    required this.baseCrossingSeconds,
    this.age = 0,
  });

  /// On-screen edge point where the meteor will enter.
  final Offset anchor;

  /// Unit travel direction (arrow points this way).
  final Offset direction;
  final MeteorKind kind;

  /// Crossing-time band used to size the warning arrow (faster = longer).
  final double baseCrossingSeconds;
  double age;

  bool get isDone => age >= MeteorCatchConstants.approachWarningSeconds;

  double get opacity {
    final life = MeteorCatchConstants.approachWarningSeconds;
    final t = (age / life).clamp(0.0, 1.0);
    // Ease in, hold, soft fade out in the last 20%.
    if (t < 0.15) return (t / 0.15) * 0.9;
    if (t > 0.8) return ((1.0 - t) / 0.2) * 0.9;
    return 0.9;
  }

  /// Longer arrow = faster meteor (lower [baseCrossingSeconds]).
  double get arrowLengthScale {
    final t = baseCrossingSeconds.clamp(0.5, 1.5);
    return 1.6 - (t - 0.5) * 1.05;
  }
}

/// Queued meteor waiting for its approach warning to finish.
class PendingApproach {
  PendingApproach({required this.meteor, this.age = 0});

  final Meteor meteor;
  double age;

  bool get isReady => age >= MeteorCatchConstants.approachWarningSeconds;
}

/// Pure playfield simulation: spawn, swipe intercept, catch FX, waves, endless phases.
class MeteorCatchEngine {
  MeteorCatchEngine({
    required this.playSize,
    required this.endless,
    required this.baseDifficulty,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    _seedStars();
  }

  Size playSize;
  final bool endless;
  final double baseDifficulty;
  final math.Random _random;

  final List<Meteor> meteors = <Meteor>[];
  final List<PendingApproach> pendingApproaches = <PendingApproach>[];
  final List<ApproachWarning> approachWarnings = <ApproachWarning>[];
  final List<NightStar> stars = <NightStar>[];
  final List<SwipeTrailSegment> swipeTrails = <SwipeTrailSegment>[];

  /// Finger-down preview polyline (not collidable).
  final List<Offset> swipePreview = <Offset>[];
  final List<CatchBurst> catchBursts = <CatchBurst>[];
  final List<ScorePop> scorePops = <ScorePop>[];
  final List<FireSpark> fireSparks = <FireSpark>[];

  int score = 0;
  int catchCount = 0;

  /// Consecutive non-decoy catches without a scoring meteor escaping.
  int catchStreak = 0;

  /// Peak [catchStreak] this round (for achievements; does not affect score).
  int bestCatchStreak = 0;

  /// Monotonic catch events (includes decoys) for SFX / haptic polling.
  int catchEventCount = 0;

  /// Parallel to [catchEventCount] for per-event feedback (golden haptic).
  final List<MeteorKind> catchEventKinds = <MeteorKind>[];
  double elapsedSeconds = 0;
  bool isFinished = false;
  double starfieldRotationRadians = 0;

  double _spawnCooldown = 0;
  int _nextId = 0;

  double _nextClusterAt = double.infinity;
  int _clusterRemaining = 0;
  double _clusterTimer = 0;

  double _nextDecoyAt = double.infinity;
  double _nextGoldenAt = double.infinity;

  MeteorKind? _forceNextKind;

  double get remainingSeconds {
    if (endless) return double.infinity;
    final left = MeteorCatchConstants.durationSeconds - elapsedSeconds;
    return left <= 0 ? 0 : left;
  }

  int get waveIndex =>
      (elapsedSeconds / MeteorCatchConstants.waveSeconds).floor();

  double get waveSpeedMultiplier =>
      1.0 + MeteorCatchConstants.waveSpeedStep * waveIndex;

  double get currentDifficulty => baseDifficulty * waveSpeedMultiplier;

  int get maxSimultaneous {
    if (!endless) return MeteorCatchConstants.durationMaxSimultaneous;
    if (elapsedSeconds < 90) return 2;
    if (elapsedSeconds < 360) return 3;
    return 4;
  }

  int get _activeSlotCount => meteors.length + pendingApproaches.length;

  void _enqueueApproach(Meteor meteor) {
    final anchor = _approachAnchorFor(meteor);
    approachWarnings.add(
      ApproachWarning(
        anchor: anchor,
        direction: meteor.velocityUnit == Offset.zero
            ? const Offset(0, 1)
            : meteor.velocityUnit,
        kind: meteor.kind,
        baseCrossingSeconds: meteor.baseCrossingSeconds,
      ),
    );
    pendingApproaches.add(PendingApproach(meteor: meteor));
  }

  /// Visible edge point where [meteor] will cross into the playfield.
  Offset _approachAnchorFor(Meteor meteor) {
    final unit = meteor.velocityUnit;
    final hit = _rayHitsPlayRect(meteor.head, unit, playSize);
    if (hit == null) {
      return Offset(
        meteor.x.clamp(12.0, playSize.width - 12.0),
        meteor.y.clamp(12.0, playSize.height - 12.0),
      );
    }
    // Nudge slightly inside so the arrow sits on-screen.
    return Offset(
      (hit.dx + unit.dx * 14).clamp(10.0, playSize.width - 10.0),
      (hit.dy + unit.dy * 14).clamp(10.0, playSize.height - 10.0),
    );
  }

  double get scorePopScale {
    if (scorePops.isEmpty) return 1.0;
    final newest = scorePops.last;
    final t = (newest.age / MeteorCatchConstants.scorePopLife).clamp(0.0, 1.0);
    final bounce = math.sin(t * math.pi);
    return 1.0 + bounce * 0.35;
  }

  void update(double dt) {
    if (isFinished || dt <= 0) return;

    // Catch up in fixed substeps so schedulers, motion, and FX age stay
    // consistent when a frame (or test) delivers a large dt.
    var remaining = dt;
    while (remaining > 0 && !isFinished) {
      final step = remaining > 0.1 ? 0.1 : remaining;
      elapsedSeconds += step;

      if (!endless && elapsedSeconds >= MeteorCatchConstants.durationSeconds) {
        elapsedSeconds = MeteorCatchConstants.durationSeconds.toDouble();
        isFinished = true;
        return;
      }

      _advanceStarfield(step);
      _advanceMeteors(step);
      _resolveTangibleHits();
      _cullOffscreenMeteors();
      _ageEffects(step);
      _tickEndlessSchedulers(step);
      _maintainPopulation(step);
      remaining -= step;
    }
  }

  void endRound() {
    isFinished = true;
  }

  void beginSwipePreview(Offset point) {
    if (isFinished) return;
    swipePreview
      ..clear()
      ..add(point);
  }

  void extendSwipePreview(Offset point) {
    if (isFinished) return;
    if (swipePreview.isEmpty) {
      swipePreview.add(point);
      return;
    }
    if ((swipePreview.last - point).distance >= 1) {
      swipePreview.add(point);
    }
  }

  void clearSwipePreview() {
    swipePreview.clear();
  }

  /// Commits the current preview polyline as a tangible barrier on lift.
  /// Returns false when the path is too short. Clears the preview either way.
  bool commitTangiblePreview() {
    final points = List<Offset>.from(swipePreview);
    clearSwipePreview();
    return commitTangiblePolyline(points);
  }

  /// Commits [points] as a tangible barrier when total path length qualifies.
  bool commitTangiblePolyline(List<Offset> points) {
    if (isFinished) return false;
    if (points.length < 2) return false;
    if (SwipeTrailSegment.pathLength(points) <
        MeteorCatchConstants.minTangibleSwipeLength) {
      return false;
    }
    swipeTrails.add(SwipeTrailSegment(points: points));
    return true;
  }

  /// Two-point convenience for tests; prefer [commitTangiblePreview] in play.
  bool commitTangibleSwipe(Offset from, Offset to) {
    return commitTangiblePolyline(<Offset>[from, to]);
  }

  /// Commits from-to if long enough, then resolves contact hits once.
  /// Prefer [commitTangiblePreview] + [update] in production.
  bool trySwipe(Offset from, Offset to) {
    if (!commitTangibleSwipe(from, to)) return false;
    final beforeBursts = catchBursts.length;
    _resolveTangibleHits();
    return catchBursts.length > beforeBursts;
  }

  /// Adds a tangible trail when length qualifies (same as commit).
  void addSwipeTrail(Offset from, Offset to) {
    commitTangibleSwipe(from, to);
  }

  void _resolveTangibleHits() {
    if (isFinished || swipeTrails.isEmpty || meteors.isEmpty) return;

    final toCatch = <Meteor>[];
    for (final meteor in List<Meteor>.of(meteors)) {
      for (final trail in swipeTrails) {
        if (_meteorContactsBarrier(meteor, trail)) {
          toCatch.add(meteor);
          break;
        }
      }
    }
    for (final meteor in toCatch) {
      if (meteors.contains(meteor)) {
        _catchMeteor(meteor);
      }
    }
  }

  /// Contact catch: head path this tick overlaps the drawn barrier stroke.
  bool _meteorContactsBarrier(Meteor meteor, SwipeTrailSegment barrier) {
    final prev = Offset(meteor.prevX, meteor.prevY);
    final curr = meteor.head;
    final hitR = MeteorCatchConstants.contactRadius(headScale: meteor.headScale);
    final pts = barrier.points;
    for (var i = 1; i < pts.length; i++) {
      if (_sweptHeadHitsSegment(prev, curr, pts[i - 1], pts[i], hitR)) {
        return true;
      }
    }
    return false;
  }

  /// True when the disk of radius [hitR] sweeping from [prev] to [curr]
  /// intersects segment [a]-[b] (covers tunneling between ticks).
  bool _sweptHeadHitsSegment(
    Offset prev,
    Offset curr,
    Offset a,
    Offset b,
    double hitR,
  ) {
    if (_segmentsIntersectOrTouch(prev, curr, a, b)) return true;
    final dPrev = (_closestPointOnSegment(a, b, prev) - prev).distance;
    final dCurr = (_closestPointOnSegment(a, b, curr) - curr).distance;
    final dA = (_closestPointOnSegment(prev, curr, a) - a).distance;
    final dB = (_closestPointOnSegment(prev, curr, b) - b).distance;
    return dPrev <= hitR || dCurr <= hitR || dA <= hitR || dB <= hitR;
  }

  @visibleForTesting
  Meteor spawnForTest({
    MeteorKind kind = MeteorKind.standard,
    TrajectoryFamily family = TrajectoryFamily.leftRightDown,
    double crossingSeconds = 1.0,
  }) {
    final meteor = _buildMeteor(
      kind: kind,
      family: family,
      crossingSeconds: crossingSeconds,
    );
    meteors.add(meteor);
    return meteor;
  }

  @visibleForTesting
  void forceKind(MeteorKind kind) {
    _forceNextKind = kind;
  }

  /// Test seam: jump clock without simulating intervening frames.
  @visibleForTesting
  void debugSetElapsedSeconds(double value) {
    elapsedSeconds = value;
  }

  /// Test seam: schedule next cluster burst at [atSeconds] (endless only).
  @visibleForTesting
  void debugScheduleClusterAt(double atSeconds) {
    _nextClusterAt = atSeconds;
  }

  /// Test seam: schedule next decoy at [atSeconds] (endless only).
  @visibleForTesting
  void debugScheduleDecoyAt(double atSeconds) {
    _nextDecoyAt = atSeconds;
  }

  /// Test seam: schedule next golden at [atSeconds] (endless only).
  @visibleForTesting
  void debugScheduleGoldenAt(double atSeconds) {
    _nextGoldenAt = atSeconds;
  }

  @visibleForTesting
  double get debugMotionMultiplier => _motionMultiplier;

  @visibleForTesting
  bool debugIsDirectionParallelToActive(double angleRadians) =>
      _isParallelToActive(angleRadians);

  @visibleForTesting
  MeteorKind debugPickKind() => _pickKind();

  @visibleForTesting
  double debugPickCrossingSeconds(MeteorKind kind) =>
      _pickCrossingSeconds(kind);

  void _catchMeteor(Meteor meteor) {
    final origin = meteor.head;
    meteors.remove(meteor);
    catchEventCount += 1;
    catchEventKinds.add(meteor.kind);

    if (meteor.kind == MeteorKind.decoy) {
      catchStreak = 0;
      score = math.max(0, score - MeteorCatchConstants.decoyPenalty);
      catchBursts.add(_buildCatchBurst(origin, meteor));
      scorePops.add(ScorePop(delta: -MeteorCatchConstants.decoyPenalty));
      return;
    }

    catchStreak += 1;
    if (catchStreak > bestCatchStreak) {
      bestCatchStreak = catchStreak;
    }
    score += meteor.pointsValue;
    catchCount += 1;
    catchBursts.add(_buildCatchBurst(origin, meteor));
    scorePops.add(ScorePop(delta: meteor.pointsValue));

    if (meteor.kind == MeteorKind.fire) {
      final unit = meteor.velocityUnit;
      final perp = Offset(-unit.dy, unit.dx);
      for (var i = 0; i < 4; i++) {
        final sign = i.isEven ? 1.0 : -1.0;
        final dist = 6 + _random.nextDouble() * 14;
        fireSparks.add(FireSpark(offset: origin + perp * dist * sign));
      }
    }
  }

  void _advanceMeteors(double dt) {
    final motion = _motionMultiplier;
    for (final meteor in meteors) {
      meteor.prevX = meteor.x;
      meteor.prevY = meteor.y;
      meteor.x += meteor.vx * motion * dt;
      meteor.y += meteor.vy * motion * dt;
    }
  }

  void _cullOffscreenMeteors() {
    meteors.removeWhere((m) {
      if (!m.isOffscreenFor(playSize)) return false;
      // Escaping scoring meteors break the catch streak; decoys do not.
      if (m.kind != MeteorKind.decoy) {
        catchStreak = 0;
      }
      return true;
    });
  }

  void _ageEffects(double dt) {
    for (final trail in swipeTrails) {
      trail.age += dt;
    }
    swipeTrails.removeWhere((t) => t.isDone);

    for (final burst in catchBursts) {
      burst.age += dt;
    }
    catchBursts.removeWhere((b) => b.isDone);

    for (final pop in scorePops) {
      pop.age += dt;
    }
    scorePops.removeWhere((p) => p.isDone);

    for (final spark in fireSparks) {
      spark.age += dt;
    }
    fireSparks.removeWhere((s) => s.isDone);

    for (final warning in approachWarnings) {
      warning.age += dt;
    }
    approachWarnings.removeWhere((w) => w.isDone);

    for (final pending in pendingApproaches) {
      pending.age += dt;
    }
    final ready = pendingApproaches.where((p) => p.isReady).toList();
    for (final pending in ready) {
      pendingApproaches.remove(pending);
      pending.meteor
        ..prevX = pending.meteor.x
        ..prevY = pending.meteor.y;
      meteors.add(pending.meteor);
    }
  }

  void _advanceStarfield(double dt) {
    if (!endless ||
        elapsedSeconds < MeteorCatchConstants.endlessGoldenPhaseStart) {
      return;
    }
    // 1 degree every 8 seconds.
    starfieldRotationRadians +=
        (MeteorCatchConstants.starRotationDegPerEightSeconds * math.pi / 180) /
        8 *
        dt;
  }

  double get _motionMultiplier {
    var mul = waveSpeedMultiplier;
    if (endless &&
        elapsedSeconds >= MeteorCatchConstants.endlessEscalationStart) {
      final steps =
          ((elapsedSeconds - MeteorCatchConstants.endlessEscalationStart) /
                  MeteorCatchConstants.endlessEscalationStepSeconds)
              .floor();
      mul *= 1.0 + MeteorCatchConstants.endlessEscalationStepFactor * steps;
    }
    return mul;
  }

  void _tickEndlessSchedulers(double dt) {
    if (!endless) return;

    final inClusterPhase =
        elapsedSeconds >= MeteorCatchConstants.endlessClusterPhaseStart &&
        elapsedSeconds < MeteorCatchConstants.endlessClusterPhaseEnd;

    if (inClusterPhase) {
      if (elapsedSeconds >= _nextClusterAt) {
        _clusterRemaining = 3;
        _clusterTimer = 0;
        _nextClusterAt = elapsedSeconds + 45 + _random.nextDouble() * 15;
      }
      if (_clusterRemaining > 0) {
        _clusterTimer += dt;
        if (_clusterTimer >= MeteorCatchConstants.endlessClusterSpawnGap &&
            _activeSlotCount < maxSimultaneous) {
          // forceEdge 3/2/1 map to distinct screen edges via _edgeEntry.
          _enqueueApproach(_spawnMeteor(forceEdge: _clusterRemaining));
          _clusterRemaining -= 1;
          _clusterTimer = 0;
        }
      }
    } else {
      _clusterRemaining = 0;
    }

    final inDecoyPhase =
        elapsedSeconds >= MeteorCatchConstants.endlessDecoyPhaseStart &&
        elapsedSeconds < MeteorCatchConstants.endlessDecoyPhaseEnd;
    if (inDecoyPhase && elapsedSeconds >= _nextDecoyAt) {
      if (_activeSlotCount < maxSimultaneous) {
        _enqueueApproach(
          _buildMeteor(
            kind: MeteorKind.decoy,
            family: _pickFamily(excludeUpward: true),
            crossingSeconds: _pickCrossingSeconds(MeteorKind.decoy),
          ),
        );
      }
      _nextDecoyAt = elapsedSeconds + MeteorCatchConstants.endlessDecoyInterval;
    }

    if (elapsedSeconds >= MeteorCatchConstants.endlessGoldenPhaseStart &&
        elapsedSeconds >= _nextGoldenAt) {
      if (_activeSlotCount < maxSimultaneous) {
        _enqueueApproach(
          _buildMeteor(
            kind: MeteorKind.golden,
            family: _pickFamily(excludeUpward: true),
            crossingSeconds: _pickCrossingSeconds(MeteorKind.golden),
          ),
        );
      }
      _nextGoldenAt =
          elapsedSeconds +
          MeteorCatchConstants.endlessGoldenIntervalMin +
          _random.nextDouble() * MeteorCatchConstants.endlessGoldenIntervalSpan;
    }
  }

  void _maintainPopulation(double dt) {
    if (_clusterRemaining > 0) return;

    _spawnCooldown -= dt;
    while (_activeSlotCount < maxSimultaneous && _spawnCooldown <= 0) {
      _enqueueApproach(_spawnMeteor());
      _spawnCooldown = _spawnInterval();
    }
  }

  double _spawnInterval() {
    final scaled = 1.4 / waveSpeedMultiplier;
    return scaled.clamp(0.45, 1.8);
  }

  Meteor _spawnMeteor({int? forceEdge}) {
    var family = _pickFamily();
    late MeteorKind kind;
    if (family == TrajectoryFamily.upward) {
      kind = MeteorKind.ice;
    } else {
      kind = _forceNextKind ?? _pickKind();
      _forceNextKind = null;
    }

    final crossing = _pickCrossingSeconds(kind);
    return _buildMeteor(
      kind: kind,
      family: family,
      crossingSeconds: crossing,
      forceEdge: forceEdge,
    );
  }

  MeteorKind _pickKind() {
    if (!endless ||
        elapsedSeconds < MeteorCatchConstants.endlessClusterPhaseStart) {
      final roll = _random.nextDouble();
      if (roll < 0.70) return MeteorKind.standard;
      if (roll < 0.90) return MeteorKind.ice;
      return MeteorKind.fire;
    }
    // Post-3m mix: 60 / 25 / 15.
    final roll = _random.nextDouble();
    if (roll < 0.60) return MeteorKind.standard;
    if (roll < 0.85) return MeteorKind.ice;
    return MeteorKind.fire;
  }

  double _pickCrossingSeconds(MeteorKind kind) {
    final roll = _random.nextDouble();
    double base;
    if (roll < 0.60) {
      base = 0.9 + _random.nextDouble() * 0.2;
    } else if (roll < 0.85) {
      base = 1.3 + _random.nextDouble() * 0.1;
    } else {
      base = 0.7 + _random.nextDouble() * 0.1;
    }
    if (kind == MeteorKind.ice) {
      base += 0.15;
    } else if (kind == MeteorKind.fire) {
      base = math.max(0.5, base - 0.1);
    }
    return base;
  }

  TrajectoryFamily _pickFamily({bool excludeUpward = false}) {
    final roll = _random.nextDouble();
    if (roll < 0.35) return TrajectoryFamily.leftRightDown;
    if (roll < 0.60) return TrajectoryFamily.rightLeftDown;
    if (roll < 0.80) return TrajectoryFamily.steepVertical;
    if (roll < 0.95) return TrajectoryFamily.nearlyHorizontal;
    if (excludeUpward) return TrajectoryFamily.steepVertical;
    return TrajectoryFamily.upward;
  }

  Meteor _buildMeteor({
    required MeteorKind kind,
    required TrajectoryFamily family,
    required double crossingSeconds,
    int? forceEdge,
  }) {
    final points = switch (kind) {
      MeteorKind.standard => MeteorCatchConstants.standardWorth,
      MeteorKind.ice => MeteorCatchConstants.iceWorth,
      MeteorKind.fire => MeteorCatchConstants.fireWorth,
      MeteorKind.decoy => 0,
      MeteorKind.golden => MeteorCatchConstants.goldenWorth,
    };

    final trailFactor = switch (kind) {
      MeteorKind.fire => 1.5,
      MeteorKind.golden => 2.5,
      _ => 1.0,
    };

    final headScale = kind == MeteorKind.golden ? 2.0 : 1.0;
    final glowPulse = kind == MeteorKind.decoy;

    var resolvedFamily = family;
    if (resolvedFamily == TrajectoryFamily.upward && kind != MeteorKind.ice) {
      resolvedFamily = TrajectoryFamily.leftRightDown;
    }

    final path = _resolveTrajectory(resolvedFamily, forceEdge: forceEdge);
    var entry = path.entry;
    var exit = _exitInOppositeQuadrant(entry);

    var dx = exit.dx - entry.dx;
    var dy = exit.dy - entry.dy;
    var angle = math.atan2(dy, dx);

    for (var attempt = 0; attempt < 8; attempt++) {
      if (!_isParallelToActive(angle)) break;
      final offsetDeg =
          MeteorCatchConstants.parallelOffsetMinDeg +
          _random.nextDouble() *
              (MeteorCatchConstants.parallelOffsetMaxDeg -
                  MeteorCatchConstants.parallelOffsetMinDeg);
      final sign = _random.nextBool() ? 1.0 : -1.0;
      angle += sign * offsetDeg * math.pi / 180;
      final length = math.sqrt(dx * dx + dy * dy);
      final candidate = Offset(
        entry.dx + math.cos(angle) * length,
        entry.dy + math.sin(angle) * length,
      );
      // Keep anti-parallel jitter, but never leave the opposite quadrant.
      exit = _exitInOppositeQuadrant(entry, preferred: candidate);
      dx = exit.dx - entry.dx;
      dy = exit.dy - entry.dy;
      angle = math.atan2(dy, dx);
    }

    final dist = math.sqrt(dx * dx + dy * dy);
    final speed = dist / crossingSeconds;
    final vx = (dx / dist) * speed;
    final vy = (dy / dist) * speed;

    return Meteor(
      id: _nextId++,
      kind: kind,
      pointsValue: points,
      x: entry.dx,
      y: entry.dy,
      vx: vx,
      vy: vy,
      family: resolvedFamily,
      baseCrossingSeconds: crossingSeconds,
      trailLengthFactor: trailFactor,
      headScale: headScale,
      glowPulse: glowPulse,
    );
  }

  bool _isParallelToActive(double angle) {
    final threshold =
        MeteorCatchConstants.parallelAngleThresholdDeg * math.pi / 180;
    Iterable<Meteor> candidates = meteors;
    if (pendingApproaches.isNotEmpty) {
      candidates = [
        ...meteors,
        ...pendingApproaches.map((p) => p.meteor),
      ];
    }
    for (final meteor in candidates) {
      var delta = (angle - meteor.angleRadians).abs();
      if (delta > math.pi) delta = 2 * math.pi - delta;
      // Same direction or anti-parallel (opposite travel) both count as parallel.
      final acute = math.min(delta, math.pi - delta);
      if (acute <= threshold) return true;
    }
    return false;
  }

  /// Exit point off-screen in the quadrant opposite the entry's screen quadrant.
  ///
  /// Quadrants: 0=TL, 1=TR, 2=BL, 3=BR. Opposite pairs are 0<->3 and 1<->2.
  Offset _exitInOppositeQuadrant(Offset entry, {Offset? preferred}) {
    final w = playSize.width;
    final h = playSize.height;
    final m = MeteorCatchConstants.spawnMargin;
    final midX = w * 0.5;
    final midY = h * 0.5;
    final entryQ = _quadrantIndex(entry, w, h);
    final targetQ = entryQ ^ 3;

    if (preferred != null && _quadrantIndex(preferred, w, h) == targetQ) {
      // Nudge preferred onto an exterior edge while staying in target quadrant.
      return _projectExitToEdge(preferred, targetQ, w, h, m);
    }

    final targetLeft = targetQ == 0 || targetQ == 2;
    final targetTop = targetQ == 0 || targetQ == 1;
    final xMin = targetLeft ? 0.0 : midX;
    final xMax = targetLeft ? midX : w;
    final yMin = targetTop ? 0.0 : midY;
    final yMax = targetTop ? midY : h;

    // Pick a random point in the target quadrant, then push it off that edge.
    final inner = Offset(
      xMin + _random.nextDouble() * (xMax - xMin).clamp(1.0, w),
      yMin + _random.nextDouble() * (yMax - yMin).clamp(1.0, h),
    );
    return _projectExitToEdge(inner, targetQ, w, h, m);
  }

  /// Pushes [point] just outside the playfield on an edge of [quadrant].
  Offset _projectExitToEdge(
    Offset point,
    int quadrant,
    double w,
    double h,
    double m,
  ) {
    final left = quadrant == 0 || quadrant == 2;
    final top = quadrant == 0 || quadrant == 1;
    final midX = w * 0.5;
    final midY = h * 0.5;
    final xMin = left ? 0.0 : midX;
    final xMax = left ? midX : w;
    final yMin = top ? 0.0 : midY;
    final yMax = top ? midY : h;
    final cx = point.dx.clamp(xMin, xMax);
    final cy = point.dy.clamp(yMin, yMax);

    // Prefer the outer edges of the quadrant (away from center).
    final useVerticalEdge = _random.nextBool();
    if (useVerticalEdge) {
      return Offset(left ? -m : w + m, cy);
    }
    return Offset(cx, top ? -m : h + m);
  }

  /// Screen quadrant for [p] (clamped into the play rect). 0=TL 1=TR 2=BL 3=BR.
  int _quadrantIndex(Offset p, double w, double h) {
    final x = p.dx.clamp(0.0, w);
    final y = p.dy.clamp(0.0, h);
    final left = x < w * 0.5;
    final top = y < h * 0.5;
    if (top && left) return 0;
    if (top && !left) return 1;
    if (!top && left) return 2;
    return 3;
  }

  @visibleForTesting
  int debugQuadrantIndex(Offset p) =>
      _quadrantIndex(p, playSize.width, playSize.height);

  @visibleForTesting
  Offset debugExitInOppositeQuadrant(Offset entry) =>
      _exitInOppositeQuadrant(entry);

  _TrajectoryEndpoints _resolveTrajectory(
    TrajectoryFamily family, {
    int? forceEdge,
  }) {
    final w = playSize.width;
    final h = playSize.height;
    final m = MeteorCatchConstants.spawnMargin;

    switch (family) {
      case TrajectoryFamily.leftRightDown:
        if (forceEdge != null) {
          return _TrajectoryEndpoints(
            entry: _edgeEntry(forceEdge, w, h, m),
            exit: Offset(w + m, h * 0.55 + _random.nextDouble() * h * 0.45),
          );
        }
        return _TrajectoryEndpoints(
          entry: Offset(-m, m + _random.nextDouble() * h * 0.35),
          exit: Offset(w + m, h * 0.55 + _random.nextDouble() * h * 0.45),
        );
      case TrajectoryFamily.rightLeftDown:
        if (forceEdge != null) {
          return _TrajectoryEndpoints(
            entry: _edgeEntry(forceEdge, w, h, m),
            exit: Offset(-m, h * 0.55 + _random.nextDouble() * h * 0.45),
          );
        }
        return _TrajectoryEndpoints(
          entry: Offset(w + m, m + _random.nextDouble() * h * 0.35),
          exit: Offset(-m, h * 0.55 + _random.nextDouble() * h * 0.45),
        );
      case TrajectoryFamily.steepVertical:
        if (forceEdge != null) {
          return _TrajectoryEndpoints(
            entry: _edgeEntry(forceEdge, w, h, m),
            exit: Offset(w + m, h * 0.55 + _random.nextDouble() * h * 0.45),
          );
        }
        // Left/right only (never top/bottom). Steep path from upper side band.
        final fromLeft = _random.nextBool();
        final entryY = m + _random.nextDouble() * h * 0.40;
        return _TrajectoryEndpoints(
          entry: Offset(fromLeft ? -m : w + m, entryY),
          exit: Offset(
            fromLeft ? w + m : -m,
            h * 0.55 + _random.nextDouble() * h * 0.40,
          ),
        );
      case TrajectoryFamily.nearlyHorizontal:
        final fromTop = _random.nextBool();
        final y = fromTop ? m + h * 0.08 : h - m - h * 0.08;
        final leftToRight = _random.nextBool();
        return _TrajectoryEndpoints(
          entry: Offset(leftToRight ? -m : w + m, y),
          exit: Offset(leftToRight ? w + m : -m, y + h * 0.06),
        );
      case TrajectoryFamily.upward:
        // Left/right only (never bottom). Climb from lower side band.
        final fromLeft = _random.nextBool();
        final entryY = h * 0.45 + _random.nextDouble() * h * 0.40;
        return _TrajectoryEndpoints(
          entry: Offset(fromLeft ? -m : w + m, entryY),
          exit: Offset(
            fromLeft ? w * 0.35 + _random.nextDouble() * w * 0.30 : w * 0.35,
            -m,
          ),
        );
    }
  }

  CatchBurst _buildCatchBurst(Offset origin, Meteor meteor) {
    final angles = <double>[
      for (var i = 0; i < MeteorCatchConstants.starburstParticleCount; i++)
        (i / MeteorCatchConstants.starburstParticleCount) * math.pi * 2 +
            _random.nextDouble() * 0.25,
    ];
    final unit = meteor.velocityUnit;
    return CatchBurst(
      origin: origin,
      particleAngles: angles,
      kind: meteor.kind,
      travelUnit: unit == Offset.zero ? const Offset(1, 0) : unit,
    );
  }

  void _seedStars() {
    final count =
        MeteorCatchConstants.starCountMin +
        _random.nextInt(
          MeteorCatchConstants.starCountMax -
              MeteorCatchConstants.starCountMin +
              1,
        );
    for (var i = 0; i < count; i++) {
      stars.add(
        NightStar(
          nx: _random.nextDouble(),
          ny: _random.nextDouble(),
          radius: 0.6 + _random.nextDouble() * 1.4,
          opacity: 0.2 + _random.nextDouble() * 0.45,
        ),
      );
    }

    if (endless) {
      _nextClusterAt =
          MeteorCatchConstants.endlessClusterPhaseStart +
          45 +
          _random.nextDouble() * 15;
      // First decoy eligible at 6m; then every 60s through 10m.
      _nextDecoyAt = MeteorCatchConstants.endlessDecoyPhaseStart;
      _nextGoldenAt =
          MeteorCatchConstants.endlessGoldenPhaseStart +
          MeteorCatchConstants.endlessGoldenIntervalMin +
          _random.nextDouble() * MeteorCatchConstants.endlessGoldenIntervalSpan;
    }
  }
}

class _TrajectoryEndpoints {
  const _TrajectoryEndpoints({required this.entry, required this.exit});

  final Offset entry;
  final Offset exit;
}

Offset _closestPointOnSegment(Offset a, Offset b, Offset p) {
  final ab = b - a;
  final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (len2 <= 0.0001) return a;
  final t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
  final clamped = t.clamp(0.0, 1.0);
  return Offset(a.dx + ab.dx * clamped, a.dy + ab.dy * clamped);
}

bool _segmentsIntersectOrTouch(Offset a, Offset b, Offset c, Offset d) {
  final d1 = _orient(a, b, c);
  final d2 = _orient(a, b, d);
  final d3 = _orient(c, d, a);
  final d4 = _orient(c, d, b);
  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }
  // Colinear touches: endpoint on the other segment.
  if (d1.abs() <= 1e-9 && _onSegment(a, b, c)) return true;
  if (d2.abs() <= 1e-9 && _onSegment(a, b, d)) return true;
  if (d3.abs() <= 1e-9 && _onSegment(c, d, a)) return true;
  if (d4.abs() <= 1e-9 && _onSegment(c, d, b)) return true;
  return false;
}

double _orient(Offset a, Offset b, Offset c) {
  return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
}

bool _onSegment(Offset a, Offset b, Offset p) {
  return p.dx >= math.min(a.dx, b.dx) - 1e-6 &&
      p.dx <= math.max(a.dx, b.dx) + 1e-6 &&
      p.dy >= math.min(a.dy, b.dy) - 1e-6 &&
      p.dy <= math.max(a.dy, b.dy) + 1e-6;
}

/// First intersection of ray [origin]+t*[dir] (t>=0) with the play rect boundary.
Offset? _rayHitsPlayRect(Offset origin, Offset dir, Size size) {
  if (dir == Offset.zero) return null;
  var bestT = double.infinity;
  Offset? hit;

  void consider(double t, double x, double y) {
    if (t < 0 || t >= bestT) return;
    if (x < -1e-6 ||
        y < -1e-6 ||
        x > size.width + 1e-6 ||
        y > size.height + 1e-6) {
      return;
    }
    bestT = t;
    hit = Offset(
      x.clamp(0.0, size.width),
      y.clamp(0.0, size.height),
    );
  }

  if (dir.dx.abs() > 0.001) {
    final tLeft = (0 - origin.dx) / dir.dx;
    consider(tLeft, 0, origin.dy + dir.dy * tLeft);
    final tRight = (size.width - origin.dx) / dir.dx;
    consider(tRight, size.width, origin.dy + dir.dy * tRight);
  }
  if (dir.dy.abs() > 0.001) {
    final tTop = (0 - origin.dy) / dir.dy;
    consider(tTop, origin.dx + dir.dx * tTop, 0);
    final tBottom = (size.height - origin.dy) / dir.dy;
    consider(tBottom, origin.dx + dir.dx * tBottom, size.height);
  }
  return hit;
}

Offset _edgeEntry(int edge, double w, double h, double m) {
  // Cluster forceEdge values must stay on left/right only (never top/bottom).
  switch (edge % 4) {
    case 0:
      return Offset(-m, h * 0.22);
    case 1:
      return Offset(w + m, h * 0.28);
    case 2:
      return Offset(-m, h * 0.55);
    default:
      return Offset(w + m, h * 0.62);
  }
}
