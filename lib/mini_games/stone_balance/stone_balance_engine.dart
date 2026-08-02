import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_seating.dart';

enum StoneBalanceMode { aiming, falling, toppling, finished }

enum ToppleStage {
  none,

  /// Offender slides sideways off the stack top.
  slideOff,

  /// Offender falls slowly down; stones knock off as it passes.
  descent,

  /// Hit ground, dust, bounce, settle.
  finale,

  /// Offender bursts apart, then fail end screen.
  explode,
}

class StackStone {
  StackStone({
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
    required this.tilt,
    required this.hue,
    required this.shapeSeed,
  });

  double cx;
  double cy;
  final double width;
  final double height;
  double tilt;
  final double hue;
  final int shapeSeed;
}

class FallingStone {
  FallingStone({
    required this.cx,
    required this.screenCy,
    required this.width,
    required this.height,
    required this.hue,
    required this.shapeSeed,
    this.vy = 0,
    this.lockedX = true,
  });

  double cx;

  /// Viewport Y (camera-independent) so the drop stays on-screen.
  double screenCy;
  double vy;
  final double width;
  final double height;
  final double hue;
  final int shapeSeed;
  final bool lockedX;

  double worldCy(double cameraY) => screenCy + cameraY;
}

class ScatterStone {
  ScatterStone({
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.hue,
    required this.tilt,
    required this.shapeSeed,
    this.isOffender = false,
    this.hasBounced = false,
  });

  double cx;
  double cy;
  final double width;
  final double height;
  double vx;
  double vy;
  double spin;
  double tilt;
  final double hue;
  final int shapeSeed;
  final bool isOffender;
  bool hasBounced;
  double age = 0;
}

class DustPuff {
  DustPuff({required this.cx, required this.cy});

  final double cx;
  final double cy;
  double age = 0;
  static const double life = 0.55;
}

class GhostStone {
  GhostStone({
    required this.cx,
    required this.width,
    required this.height,
    required this.hue,
    required this.shapeSeed,
  });

  double cx;
  final double width;
  final double height;
  final double hue;
  final int shapeSeed;
}

/// Route B stack game: aim ghost on X, release to drop straight down.
class StoneBalanceEngine {
  StoneBalanceEngine({
    required this.playSize,
    required this.endless,
    required this.baseDifficulty,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    _placeFirstStone();
    _beginAiming();
  }

  Size playSize;
  final bool endless;
  final double baseDifficulty;
  final math.Random _random;

  final List<StackStone> stack = <StackStone>[];
  GhostStone? ghost;
  FallingStone? falling;
  final List<ScatterStone> scatter = <ScatterStone>[];
  final List<DustPuff> dust = <DustPuff>[];

  StoneBalanceMode mode = StoneBalanceMode.aiming;
  ToppleStage toppleStage = ToppleStage.none;

  double elapsedSeconds = 0;
  double _spawnCooldown = 0;
  bool isFinished = false;
  bool toppled = false;

  /// True when the duration timer ended the round (not quit / topple).
  bool finishedByTimeout = false;

  double cameraY = 0;
  double _cameraTarget = 0;

  bool _unstable = false;
  double _unstableTimer = 0;
  double _unstableLeanSign = 1;

  double _toppleTimer = 0;
  int _toppleSide = 1;
  ScatterStone? _offender;
  double _slideTargetX = 0;

  int _lockedScore = 0;
  bool _scoreLocked = false;
  bool _justLanded = false;
  bool _justFailed = false;

  /// Smooth background phase (1-5) for painter cross-fades.
  double backgroundPhase = 1;
  double _backgroundPhaseTarget = 1;

  /// Player height: stack stones minus the auto foundation stone.
  int get score {
    if (_scoreLocked) return _lockedScore;
    return playerHeightFromStackLength(stack.length);
  }

  bool get isUnstable => _unstable;
  bool get isAiming => mode == StoneBalanceMode.aiming && ghost != null;
  bool get canAim => isAiming && !toppled && !isFinished;

  /// Tutorial hint: only before the first player-stacked stone this round.
  bool get showAimHint => canAim && score == 0;

  bool get showGround {
    if (mode == StoneBalanceMode.toppling && _offender != null) {
      return _approxHeightFromWorldY(_offender!.cy) <
          StoneBalanceConstants.groundGoneHeight;
    }
    return score < StoneBalanceConstants.groundGoneHeight;
  }

  /// 1 while high; [StoneBalanceConstants.toppleNearGroundTimeScale] near ground /
  /// finale. Explode runs at full speed for impact.
  double get toppleTimeScale {
    if (mode != StoneBalanceMode.toppling) return 1;
    if (toppleStage == ToppleStage.explode || toppleStage == ToppleStage.none) {
      return 1;
    }
    final offender = _offender;
    if (offender == null) return 1;
    if (toppleStage == ToppleStage.finale) {
      return StoneBalanceConstants.toppleNearGroundTimeScale;
    }
    if (toppleStage == ToppleStage.descent) {
      final bottom = offender.cy + offender.height / 2;
      final band =
          playSize.height * StoneBalanceConstants.toppleNearGroundBandFraction;
      if (groundY - bottom <= band) {
        return StoneBalanceConstants.toppleNearGroundTimeScale;
      }
    }
    return 1;
  }

  int get remainingSeconds {
    if (endless) return 0;
    final left = StoneBalanceConstants.durationSeconds - elapsedSeconds;
    return left < 0 ? 0 : left.ceil();
  }

  double get currentDifficulty =>
      baseDifficulty *
      (1.0 + score * 0.03 + (endless ? elapsedSeconds * 0.002 : 0));

  /// World Y of the green grass line (sand top edge).
  double get grassLineY =>
      playSize.height * StoneBalanceConstants.grassLineFraction;

  /// Collision / bounce floor = grass line.
  double get groundY => grassLineY;

  /// Top face of the three platform stones (just above the green).
  double get platformTopY =>
      grassLineY - StoneBalanceConstants.platformStoneHeight;

  bool consumeJustLanded() {
    final value = _justLanded;
    _justLanded = false;
    return value;
  }

  /// Fires once when the topple finale completes (fail SFX / end screen).
  bool consumeJustFailed() {
    final value = _justFailed;
    _justFailed = false;
    return value;
  }

  @Deprecated('Use consumeJustFailed')
  bool consumeJustToppled() => consumeJustFailed();

  @visibleForTesting
  double get offenderMinVisibleX {
    final offender = _offender;
    if (offender == null) return 0;
    return offender.width / 2;
  }

  @visibleForTesting
  double get offenderMaxVisibleX {
    final offender = _offender;
    if (offender == null) return playSize.width;
    return playSize.width - offender.width / 2;
  }

  @visibleForTesting
  double? get debugSlideTargetX => _offender == null ? null : _slideTargetX;

  double get _aimMinX {
    final margin = playSize.width * StoneBalanceConstants.aimMarginFraction;
    final half = (ghost?.width ?? playSize.width * 0.3) / 2;
    return margin + half;
  }

  double get _aimMaxX {
    final margin = playSize.width * StoneBalanceConstants.aimMarginFraction;
    final half = (ghost?.width ?? playSize.width * 0.3) / 2;
    return playSize.width - margin - half;
  }

  @visibleForTesting
  static int playerHeightFromStackLength(int stackLength) =>
      stackLength <= 1 ? 0 : stackLength - 1;

  @visibleForTesting
  static double overhangFraction({
    required double fallCx,
    required double supportCx,
    required double supportWidth,
  }) {
    if (supportWidth <= 0) return 1;
    return (fallCx - supportCx).abs() / supportWidth;
  }

  /// Target background phase from player height (1 garden .. 5 void).
  /// 0-5 garden, 6-15 earthy garden, 16-30 sky, 31-59 strato, 60+ void.
  static int phaseForScore(int height) {
    if (height >= 60) return 5;
    if (height >= 31) return 4;
    if (height >= 16) return 3;
    if (height >= 6) return 2;
    return 1;
  }

  /// Drag aim: [screenX] is horizontal position in play coordinates.
  void setAimScreenX(double screenX) {
    if (!canAim) return;
    ghost!.cx = screenX.clamp(_aimMinX, _aimMaxX);
  }

  /// Release finger: commit drop with locked X (screen-space fall).
  void releaseDrop() {
    if (!canAim) return;
    final g = ghost!;
    falling = FallingStone(
      cx: g.cx.clamp(_aimMinX, _aimMaxX),
      screenCy: playSize.height * StoneBalanceConstants.spawnYFraction,
      width: g.width,
      height: g.height,
      hue: g.hue,
      shapeSeed: g.shapeSeed,
      vy: 40,
      lockedX: true,
    );
    ghost = null;
    mode = StoneBalanceMode.falling;
  }

  @visibleForTesting
  void forceToppleForTest() {
    if (toppled || isFinished) return;
    if (stack.isEmpty) {
      _placeFirstStone();
    }
    _startToppleSequence(offenderIndex: stack.length - 1);
  }

  void endRound() {
    if (!_scoreLocked) {
      _lockedScore = score;
      _scoreLocked = true;
    }
    mode = StoneBalanceMode.finished;
    isFinished = true;
  }

  void update(double dt) {
    if (isFinished || dt <= 0) return;
    final simDt = dt > 0.05 ? 0.05 : dt;
    elapsedSeconds += dt;

    _updateBackgroundPhase(simDt);
    _advanceDust(simDt);

    if (!endless &&
        elapsedSeconds >= StoneBalanceConstants.durationSeconds &&
        mode != StoneBalanceMode.toppling) {
      elapsedSeconds = StoneBalanceConstants.durationSeconds.toDouble();
      finishedByTimeout = true;
      endRound();
      return;
    }

    if (mode == StoneBalanceMode.toppling) {
      final toppleDt = simDt * toppleTimeScale;
      _updateTopple(toppleDt);
      _updateCamera(toppleDt);
      return;
    }

    _updateCamera(simDt);

    if (_unstable) {
      _advanceUnstable(simDt);
      if (mode == StoneBalanceMode.toppling) return;
    }

    if (mode == StoneBalanceMode.aiming) {
      if (_spawnCooldown > 0) {
        _spawnCooldown -= simDt;
        if (_spawnCooldown <= 0 && ghost == null) {
          _beginAiming();
        }
      }
      return;
    }

    final fall = falling;
    if (fall == null) {
      mode = StoneBalanceMode.aiming;
      _spawnCooldown = StoneBalanceConstants.spawnInterval;
      return;
    }

    fall.vy += StoneBalanceConstants.fallGravity * simDt;
    if (fall.vy > StoneBalanceConstants.fallMaxSpeed) {
      fall.vy = StoneBalanceConstants.fallMaxSpeed;
    }
    if (fall.lockedX) {
      fall.cx = fall.cx.clamp(_aimMinX, _aimMaxX);
    }
    fall.screenCy += fall.vy * simDt;

    final worldCy = fall.worldCy(cameraY);
    final landCy = _landingTargetCy(fall);
    if (worldCy >= landCy) {
      _landStone(fall);
    }
  }

  /// World Y of the falling stone's center when it should seat.
  double _landingTargetCy(FallingStone fall) {
    final support = stack.isEmpty ? null : stack.last;
    if (support == null) {
      return platformTopY - fall.height / 2;
    }
    final leanSign = fall.cx == support.cx ? 1.0 : (fall.cx - support.cx).sign;
    final overhang = overhangFraction(
      fallCx: fall.cx,
      supportCx: support.cx,
      supportWidth: support.width,
    );
    final tilt = StoneBalanceSeating.landingTilt(
      supportTilt: support.tilt,
      overhang: overhang,
      leanSign: leanSign,
    );
    return StoneBalanceSeating.seatedCenter(
      supportCx: support.cx,
      supportCy: support.cy,
      supportHeight: support.height,
      fallHeight: fall.height,
      tilt: tilt,
      aimCx: fall.cx,
    ).dy;
  }

  void _updateBackgroundPhase(double dt) {
    if (mode == StoneBalanceMode.toppling && _offender != null) {
      // Descend through earlier sky/garden phases as the stone falls.
      _backgroundPhaseTarget = phaseForScore(
        _approxHeightFromWorldY(_offender!.cy),
      ).toDouble();
    } else {
      _backgroundPhaseTarget = phaseForScore(score).toDouble();
    }
    final speed = 1 / StoneBalanceConstants.backgroundCrossfadeSeconds;
    if (backgroundPhase < _backgroundPhaseTarget) {
      backgroundPhase = (backgroundPhase + speed * dt).clamp(
        1.0,
        _backgroundPhaseTarget,
      );
    } else if (backgroundPhase > _backgroundPhaseTarget) {
      backgroundPhase = (backgroundPhase - speed * dt).clamp(
        _backgroundPhaseTarget,
        5.0,
      );
    }
  }

  int _approxHeightFromWorldY(double cy) {
    final rise = platformTopY - cy;
    if (rise <= 0) return 0;
    const avgStone = 36.0;
    return (rise / avgStone).floor().clamp(0, 80);
  }

  void _advanceDust(double dt) {
    for (final p in dust) {
      p.age += dt;
    }
    dust.removeWhere((p) => p.age >= DustPuff.life);
  }

  void _advanceUnstable(double dt) {
    _unstableTimer += dt;
    if (stack.isNotEmpty) {
      // Tip the top stone further toward the overhang side until it falls.
      stack.last.tilt += _unstableLeanSign * 2.5 * dt;
    }
    if (_unstableTimer >= StoneBalanceConstants.unstableFallSeconds) {
      _startToppleSequence(offenderIndex: stack.length - 1);
    }
  }

  void _updateCamera(double dt) {
    // Hold still while a stone falls so the drop stays screen-locked.
    if (mode == StoneBalanceMode.falling) {
      return;
    }
    if (mode == StoneBalanceMode.toppling) {
      final offender = _offender;
      if (offender != null && score >= StoneBalanceConstants.groundGoneHeight) {
        var target = math.min(
          0.0,
          offender.cy -
              playSize.height * StoneBalanceConstants.cameraFollowBand,
        );
        final topMargin = offender.height * 0.6;
        final bottomMargin = offender.height * 0.6;
        final minCameraForTop = offender.cy - (playSize.height - topMargin);
        final maxCameraForBottom = offender.cy - bottomMargin;
        if (target < minCameraForTop) {
          target = minCameraForTop;
        }
        if (target > maxCameraForBottom) {
          target = maxCameraForBottom;
        }
        _cameraTarget = math.min(0.0, target);
      } else {
        _cameraTarget = 0;
      }
    } else if (stack.isNotEmpty) {
      _cameraTarget = _desiredCameraForStackTop();
    } else {
      _cameraTarget = 0;
    }
    final alpha = 1 - math.exp(-StoneBalanceConstants.cameraEase * dt);
    cameraY += (_cameraTarget - cameraY) * alpha;
  }

  /// Never raise the ground (positive cameraY). Follow only once height hits
  /// [StoneBalanceConstants.groundGoneHeight] (when the garden floor leaves).
  double _desiredCameraForStackTop() {
    if (score < StoneBalanceConstants.groundGoneHeight) {
      return 0;
    }
    final topStone = stack.last;
    // Visual top of the last stone (local (0, -h/2) under clockwise rotate).
    final top = StoneBalanceSeating.localToWorld(
      cx: topStone.cx,
      cy: topStone.cy,
      tilt: topStone.tilt,
      local: Offset(0, -topStone.height / 2),
    ).dy;
    final desired =
        top - playSize.height * StoneBalanceConstants.cameraFollowBand;
    return math.min(0.0, desired);
  }

  void _snapCameraTowardTarget() {
    _cameraTarget = stack.isEmpty ? 0.0 : _desiredCameraForStackTop();
    final t = StoneBalanceConstants.cameraLandSnap.clamp(0.0, 1.0);
    cameraY += (_cameraTarget - cameraY) * t;
  }

  void _placeFirstStone() {
    final size = _rollStoneSize(firstStone: true);
    final margin =
        playSize.width * StoneBalanceConstants.firstStoneMarginFraction;
    final minX = margin + size.$1 / 2;
    final maxX = playSize.width - margin - size.$1 / 2;
    final cx = minX + _random.nextDouble() * (maxX - minX);
    stack.add(
      StackStone(
        cx: cx,
        cy: platformTopY - size.$2 / 2,
        width: size.$1,
        height: size.$2,
        tilt: 0,
        hue: _random.nextDouble(),
        shapeSeed: _random.nextInt(1 << 30),
      ),
    );
    cameraY = 0;
    _cameraTarget = 0;
    _backgroundPhaseTarget = 1;
    backgroundPhase = 1;
  }

  (double, double) _rollStoneSize({bool firstStone = false}) {
    final wFrac =
        StoneBalanceConstants.stoneWidthMinFraction +
        _random.nextDouble() *
            (StoneBalanceConstants.stoneWidthMaxFraction -
                StoneBalanceConstants.stoneWidthMinFraction);
    var w = playSize.width * wFrac;
    if (firstStone) {
      w =
          playSize.width *
          (StoneBalanceConstants.stoneWidthMinFraction +
              StoneBalanceConstants.stoneWidthMaxFraction) /
          2;
    }
    final h =
        StoneBalanceConstants.stoneHeightMin +
        _random.nextDouble() *
            (StoneBalanceConstants.stoneHeightMax -
                StoneBalanceConstants.stoneHeightMin);
    return (w, h);
  }

  void _beginAiming() {
    final size = _rollStoneSize();
    final cx = playSize.width * 0.5;
    ghost = GhostStone(
      cx: cx.clamp(_aimMinX, _aimMaxX),
      width: size.$1,
      height: size.$2,
      hue: _random.nextDouble(),
      shapeSeed: _random.nextInt(1 << 30),
    );
    ghost!.cx = ghost!.cx.clamp(_aimMinX, _aimMaxX);
    mode = StoneBalanceMode.aiming;
  }

  double _towerCentroidX() {
    if (stack.isEmpty) return playSize.width * 0.5;
    var sum = 0.0;
    for (final s in stack) {
      sum += s.cx;
    }
    return sum / stack.length;
  }

  void _landStone(FallingStone fall) {
    final support = stack.isEmpty ? null : stack.last;

    var overhang = 0.0;
    var leanSign = 1.0;
    if (support != null) {
      overhang = overhangFraction(
        fallCx: fall.cx,
        supportCx: support.cx,
        supportWidth: support.width,
      );
      leanSign = fall.cx == support.cx ? 1.0 : (fall.cx - support.cx).sign;
    }

    final tilt = support == null
        ? 0.0
        : StoneBalanceSeating.landingTilt(
            supportTilt: support.tilt,
            overhang: overhang,
            leanSign: leanSign,
          );

    final seat = support == null
        ? StoneBalanceSeating.seatedOnPlatform(
            platformTopY: platformTopY,
            fallHeight: fall.height,
            aimCx: fall.cx,
          )
        : StoneBalanceSeating.seatedCenter(
            supportCx: support.cx,
            supportCy: support.cy,
            supportHeight: support.height,
            fallHeight: fall.height,
            tilt: tilt,
            aimCx: fall.cx,
          );

    stack.add(
      StackStone(
        cx: seat.dx,
        cy: seat.dy,
        width: fall.width,
        height: fall.height,
        tilt: tilt,
        hue: fall.hue,
        shapeSeed: fall.shapeSeed,
      ),
    );
    falling = null;
    _justLanded = true;
    dust.add(DustPuff(cx: seat.dx, cy: seat.dy + fall.height / 2));
    _snapCameraTowardTarget();

    if (support != null &&
        overhang > StoneBalanceConstants.overhangImmediateTopple) {
      _startToppleSequence(offenderIndex: stack.length - 1);
      return;
    }

    final foundation = stack.first;
    final lean = (_towerCentroidX() - foundation.cx).abs();
    if (lean >
        playSize.width * StoneBalanceConstants.towerLeanMaxScreenFraction) {
      _startToppleSequence(offenderIndex: stack.length - 1);
      return;
    }

    if (support != null && overhang > StoneBalanceConstants.overhangUnstable) {
      _unstable = true;
      _unstableTimer = 0;
      _unstableLeanSign = leanSign;
    }

    mode = StoneBalanceMode.aiming;
    _spawnCooldown =
        StoneBalanceConstants.spawnInterval / (0.85 + 0.15 * currentDifficulty);
  }

  void _startToppleSequence({required int offenderIndex}) {
    if (toppled) return;
    _lockedScore = score;
    _scoreLocked = true;
    toppled = true;
    _unstable = false;
    mode = StoneBalanceMode.toppling;
    toppleStage = ToppleStage.slideOff;
    _toppleTimer = 0;
    ghost = null;
    falling = null;

    final idx = offenderIndex.clamp(0, stack.length - 1);
    final offender = stack.removeAt(idx);
    _toppleSide =
        offender.cx >= (stack.isEmpty ? playSize.width * 0.5 : stack.last.cx)
        ? 1
        : -1;
    _slideTargetX = offender.cx + _toppleSide * (offender.width * 0.85 + 24);
    final minX = offender.width / 2;
    final maxX = playSize.width - offender.width / 2;
    _slideTargetX = _slideTargetX.clamp(minX, maxX);
    _offender = ScatterStone(
      cx: offender.cx,
      cy: offender.cy,
      width: offender.width,
      height: offender.height,
      vx: _toppleSide * 90,
      vy: 0,
      spin: _toppleSide * 1.2,
      hue: offender.hue,
      tilt: offender.tilt,
      shapeSeed: offender.shapeSeed,
      isOffender: true,
    );
    scatter.add(_offender!);
  }

  void _knockStoneAt(int index) {
    if (index < 0 || index >= stack.length) return;
    final stone = stack.removeAt(index);
    final away = -_toppleSide;
    scatter.add(
      ScatterStone(
        cx: stone.cx,
        cy: stone.cy,
        width: stone.width,
        height: stone.height,
        vx:
            away * (90 + _random.nextDouble() * 70) +
            (_random.nextDouble() - 0.5) * 30,
        vy: -20 - _random.nextDouble() * 40,
        spin: away * (2 + _random.nextDouble() * 3),
        hue: stone.hue,
        tilt: stone.tilt,
        shapeSeed: stone.shapeSeed,
      ),
    );
  }

  void _knockStonesPassedByOffender() {
    final offender = _offender;
    if (offender == null) return;
    // Knock from top of remaining stack downward as offender falls past.
    while (stack.isNotEmpty) {
      final top = stack.last;
      if (offender.cy < top.cy) break;
      _knockStoneAt(stack.length - 1);
    }
  }

  void _updateTopple(double dt) {
    switch (toppleStage) {
      case ToppleStage.none:
        _advanceScatterPhysics(dt);
      case ToppleStage.slideOff:
        final offender = _offender;
        if (offender == null) {
          toppleStage = ToppleStage.finale;
          _advanceScatterPhysics(dt);
          break;
        }
        final dx = _slideTargetX - offender.cx;
        if (dx.abs() > 2) {
          offender.cx += dx.sign * math.min(dx.abs(), 220 * dt);
          offender.tilt += _toppleSide * 1.5 * dt;
        } else {
          offender.cx = _slideTargetX;
          offender.vy = 40;
          toppleStage = ToppleStage.descent;
          _toppleTimer = 0;
        }
        _clampOffenderX(offender);
        _advanceScatterPhysics(dt);
      case ToppleStage.descent:
        final offender = _offender;
        if (offender == null) {
          toppleStage = ToppleStage.finale;
          _advanceScatterPhysics(dt);
          break;
        }
        offender.vy += StoneBalanceConstants.toppleFallGravity * dt;
        if (offender.vy > StoneBalanceConstants.toppleFallMaxSpeed) {
          offender.vy = StoneBalanceConstants.toppleFallMaxSpeed;
        }
        offender.vx *= math.pow(0.92, dt * 60).toDouble();
        _advanceScatterPhysics(dt);
        _clampOffenderX(offender);
        _knockStonesPassedByOffender();
        if (offender.cy + offender.height / 2 >= groundY) {
          toppleStage = ToppleStage.finale;
          _toppleTimer = 0;
        }
      case ToppleStage.finale:
        while (stack.isNotEmpty) {
          _knockStoneAt(stack.length - 1);
        }
        _advanceScatterPhysics(dt);
        final offender = _offender;
        if (offender != null &&
            offender.cy + offender.height / 2 >= groundY &&
            !offender.hasBounced) {
          offender.cy = groundY - offender.height / 2;
          offender.vy = -200;
          offender.vx *= 0.35;
          offender.hasBounced = true;
          dust.add(DustPuff(cx: offender.cx, cy: groundY));
        }
        final settled =
            offender == null ||
            (offender.hasBounced &&
                offender.vy >= 0 &&
                offender.cy + offender.height / 2 >= groundY - 4);
        if (settled &&
            _toppleTimer >=
                StoneBalanceConstants.topplePostBounceBeforeExplode) {
          _startOffenderExplode();
        }
        _toppleTimer += dt;
      case ToppleStage.explode:
        _advanceScatterPhysics(dt);
        _toppleTimer += dt;
        if (_toppleTimer >= StoneBalanceConstants.toppleExplodeDuration) {
          _justFailed = true;
          mode = StoneBalanceMode.finished;
          isFinished = true;
        }
    }
  }

  void _startOffenderExplode() {
    final offender = _offender;
    toppleStage = ToppleStage.explode;
    _toppleTimer = 0;
    if (offender == null) return;
    final ox = offender.cx;
    final oy = offender.cy;
    scatter.remove(offender);
    _offender = null;
    dust.add(DustPuff(cx: ox, cy: groundY));
    dust.add(DustPuff(cx: ox, cy: oy));
    for (var i = 0; i < 12; i++) {
      final ang = (i / 12) * math.pi * 2 + _random.nextDouble() * 0.4;
      final speed = 220 + _random.nextDouble() * 280;
      scatter.add(
        ScatterStone(
          cx: ox,
          cy: oy,
          width: offender.width * (0.22 + _random.nextDouble() * 0.28),
          height: offender.height * (0.22 + _random.nextDouble() * 0.28),
          vx: math.cos(ang) * speed,
          vy: math.sin(ang) * speed - 80,
          spin: (_random.nextDouble() - 0.5) * 14,
          hue: offender.hue,
          tilt: offender.tilt,
          shapeSeed: offender.shapeSeed ^ (i + 1) * 17,
        ),
      );
    }
  }

  void _advanceScatterPhysics(double dt) {
    for (final s in scatter) {
      s.age += dt;
      if (s.isOffender && toppleStage == ToppleStage.slideOff) {
        // Horizontal slide is owned by the slideOff stage.
        continue;
      }
      if (s.isOffender && toppleStage == ToppleStage.descent) {
        s.cx += s.vx * dt;
        s.cy += s.vy * dt;
        s.tilt += s.spin * dt;
        _clampOffenderX(s);
        continue;
      }
      s.vy += 900 * dt;
      s.cx += s.vx * dt;
      s.cy += s.vy * dt;
      s.tilt += s.spin * dt;
      if (s.hasBounced && s.cy + s.height / 2 > groundY) {
        s.cy = groundY - s.height / 2;
        s.vy = 0;
        s.vx *= 0.85;
      }
      if (s.isOffender) {
        _clampOffenderX(s);
      }
    }
  }

  void _clampOffenderX(ScatterStone offender) {
    final minX = offender.width / 2;
    final maxX = playSize.width - offender.width / 2;
    offender.cx = offender.cx.clamp(minX, maxX);
  }
}
