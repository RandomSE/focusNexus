import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'cherry_blossom_fx_timing.dart';
import 'cherry_blossom_peace_petal_spec.dart';

// Curves lives in flutter/animation.dart (exported by widgets).

/// Luminous falling petals for Serenity (peace) finale stage.
class CherryBlossomPeacePetals extends StatefulWidget {
  const CherryBlossomPeacePetals({
    super.key,
    required this.size,
    this.animate = true,
    this.sizeMul = 1.0,
    this.minConcurrent,
    this.maxConcurrent,
    this.litePaint = false,
  });

  final Size size;
  final bool animate;

  /// Scales drawn petal size (bonsai pots use a larger mul for prominence).
  final double sizeMul;

  /// Optional concurrent overrides (defaults to [CherryBlossomPeacePetalSpec]).
  final int? minConcurrent;
  final int? maxConcurrent;

  /// Skip expensive MaskFilter glows (required for multi-pot bonsai).
  final bool litePaint;

  /// Bonsai: half of prior pot baseline (~1x Power pot leaf after half).
  static const double bonsaiMinSizeScale = 0.55;

  /// Passed into pots; equals the small-leaf baseline.
  static const double bonsaiSizeMul = bonsaiMinSizeScale;

  /// Largest bonsai Peace leaf is 2x the small (same span ratio as Power pots).
  static const double bonsaiMaxOverMin = 2.0;

  static double get bonsaiMaxSizeScale =>
      bonsaiMinSizeScale * bonsaiMaxOverMin;

  /// Linear size between small and 1.5x small (ignores main-tree layer extremes).
  static double bonsaiSizeScaleForRoll(double roll) {
    final t = roll.clamp(0.0, 1.0);
    return bonsaiMinSizeScale +
        t * (bonsaiMaxSizeScale - bonsaiMinSizeScale);
  }

  static const int bonsaiMinConcurrent = 6;
  static const int bonsaiMaxConcurrent = 10;

  @override
  State<CherryBlossomPeacePetals> createState() =>
      _CherryBlossomPeacePetalsState();
}

class _CherryBlossomPeacePetalsState extends State<CherryBlossomPeacePetals>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_PeacePetal> _petals = [];
  final math.Random _random = math.Random(7);
  Duration? _lastElapsed;
  double _clusterCooldown = 0;
  int _spawnedCount = 0;
  int _targetConcurrent = CherryBlossomPeacePetalSpec.minConcurrent;

  int get _minConcurrent =>
      widget.minConcurrent ?? CherryBlossomPeacePetalSpec.minConcurrent;

  int get _maxConcurrent =>
      widget.maxConcurrent ?? CherryBlossomPeacePetalSpec.maxConcurrent;

  @override
  void initState() {
    super.initState();
    final span = math.max(0, _maxConcurrent - _minConcurrent);
    _targetConcurrent = _minConcurrent + _random.nextInt(span + 1);
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
      // First cluster immediately so petals are visible without waiting.
      final cluster = CherryBlossomPeacePetalSpec.clusterSizeMin +
          _random.nextInt(
            CherryBlossomPeacePetalSpec.clusterSizeMax -
                CherryBlossomPeacePetalSpec.clusterSizeMin +
                1,
          );
      for (var i = 0; i < cluster; i++) {
        _spawnPetal();
      }
      _clusterCooldown = CherryBlossomPeacePetalSpec.clusterPauseMinSec +
          _random.nextDouble() *
              (CherryBlossomPeacePetalSpec.clusterPauseMaxSec -
                  CherryBlossomPeacePetalSpec.clusterPauseMinSec);
    }
  }

  @override
  void didUpdateWidget(covariant CherryBlossomPeacePetals oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!widget.animate) return;
    var dt = _lastElapsed == null
        ? 0.016
        : (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    dt = CherryBlossomFxTiming.clampSimulationDt(dt);
    if (dt <= 0) return;

    _clusterCooldown -= dt;
    if (_clusterCooldown <= 0 && _petals.length < _targetConcurrent) {
      final cluster = CherryBlossomPeacePetalSpec.clusterSizeMin +
          _random.nextInt(
            CherryBlossomPeacePetalSpec.clusterSizeMax -
                CherryBlossomPeacePetalSpec.clusterSizeMin +
                1,
          );
      final room = _targetConcurrent - _petals.length;
      final n = math.min(cluster, room);
      for (var i = 0; i < n; i++) {
        _spawnPetal();
      }
      _clusterCooldown = CherryBlossomPeacePetalSpec.clusterPauseMinSec +
          _random.nextDouble() *
              (CherryBlossomPeacePetalSpec.clusterPauseMaxSec -
                  CherryBlossomPeacePetalSpec.clusterPauseMinSec);
    }

    setState(() {
      for (final petal in _petals) {
        petal.advance(dt, widget.size);
      }
      _petals.removeWhere((p) => p.progress >= 1.0);
    });
  }

  void _spawnPetal() {
    _spawnedCount++;
    final type = CherryBlossomPeacePetalSpec.typeForRoll(_random.nextDouble());
    final layer = CherryBlossomPeacePetalSpec.layerForRoll(_random.nextDouble());
    final double sizeScale;
    if (widget.litePaint) {
      sizeScale = CherryBlossomPeacePetals.bonsaiSizeScaleForRoll(
        _random.nextDouble(),
      );
    } else {
      var s =
          CherryBlossomPeacePetalSpec.sizeScaleForRoll(_random.nextDouble()) *
              type.sizeBias *
              layer.scaleMul *
              widget.sizeMul;
      if (type == PeacePetalType.goldKissed) {
        s *= 0.92;
      }
      sizeScale = s;
    }

    // Weighted toward center 60% of width.
    final centerBias = _random.nextDouble();
    final double spawnX;
    if (centerBias < 0.75) {
      final left = widget.size.width * 0.20;
      spawnX = left + _random.nextDouble() * widget.size.width * 0.60;
    } else {
      spawnX = _random.nextDouble() * widget.size.width;
    }

    final fallSec = CherryBlossomPeacePetalSpec.fallDurationMinSec +
        _random.nextDouble() *
            (CherryBlossomPeacePetalSpec.fallDurationMaxSec -
                CherryBlossomPeacePetalSpec.fallDurationMinSec);
    final driftPeriod = CherryBlossomPeacePetalSpec.driftPeriodMinSec +
        _random.nextDouble() *
            (CherryBlossomPeacePetalSpec.driftPeriodMaxSec -
                CherryBlossomPeacePetalSpec.driftPeriodMinSec);
    final spin = CherryBlossomPeacePetalSpec.rotationRadPerSecMin +
        _random.nextDouble() *
            (CherryBlossomPeacePetalSpec.rotationRadPerSecMax -
                CherryBlossomPeacePetalSpec.rotationRadPerSecMin);
    final opacity = type.opacityMin +
        _random.nextDouble() * (type.opacityMax - type.opacityMin);

    final hasPause =
        _spawnedCount % CherryBlossomPeacePetalSpec.pauseEveryNthPetal == 0;
    final pauseAt = hasPause ? 0.25 + _random.nextDouble() * 0.45 : -1.0;
    final pauseDur = hasPause
        ? CherryBlossomPeacePetalSpec.pauseDurationMinSec +
            _random.nextDouble() *
                (CherryBlossomPeacePetalSpec.pauseDurationMaxSec -
                    CherryBlossomPeacePetalSpec.pauseDurationMinSec)
        : 0.0;

    _petals.add(
      _PeacePetal(
        originX: spawnX,
        type: type,
        layer: layer,
        sizeScale: sizeScale,
        fallDurationSec: fallSec / layer.speedMul,
        driftPeriodSec: driftPeriod,
        driftPhase: _random.nextDouble() * math.pi * 2,
        driftSign: _random.nextBool() ? 1.0 : -1.0,
        spin: spin * (_random.nextBool() ? 1.0 : -1.0),
        rotation: _random.nextDouble() * math.pi,
        baseOpacity: opacity * layer.opacityMul,
        pauseAtProgress: pauseAt,
        pauseDurationSec: pauseDur,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: _PeacePetalPainter(
        petals: List<_PeacePetal>.from(_petals),
        litePaint: widget.litePaint,
      ),
    );
  }
}

class _PeacePetal {
  _PeacePetal({
    required this.originX,
    required this.type,
    required this.layer,
    required this.sizeScale,
    required this.fallDurationSec,
    required this.driftPeriodSec,
    required this.driftPhase,
    required this.driftSign,
    required this.spin,
    required this.rotation,
    required this.baseOpacity,
    required this.pauseAtProgress,
    required this.pauseDurationSec,
  });

  final double originX;
  final PeacePetalType type;
  final PeacePetalLayer layer;
  final double sizeScale;
  final double fallDurationSec;
  final double driftPeriodSec;
  final double driftPhase;
  final double driftSign;
  final double spin;
  double rotation;
  final double baseOpacity;
  final double pauseAtProgress;
  final double pauseDurationSec;

  double progress = 0;
  double pauseRemaining = 0;
  bool pauseTriggered = false;
  double x = 0;
  double y = 0;
  double displayOpacity = 1;

  void advance(double dt, Size canvas) {
    if (!pauseTriggered &&
        pauseAtProgress >= 0 &&
        progress >= pauseAtProgress) {
      pauseTriggered = true;
      pauseRemaining = pauseDurationSec;
    }
    if (pauseRemaining > 0) {
      pauseRemaining -= dt;
      // Near-zero vertical during updraft; still allow tiny drift/spin.
      final amp = canvas.width * CherryBlossomPeacePetalSpec.driftAmplitudeFactor;
      final driftT = progress * fallDurationSec;
      final easeDrift = Curves.easeInOut.transform(
        ((driftT % driftPeriodSec) / driftPeriodSec).clamp(0.0, 1.0),
      );
      x = originX +
          driftSign *
              amp *
              math.sin(driftPhase + easeDrift * math.pi * 2) *
              0.35;
      rotation += spin * dt * 0.25;
      displayOpacity = baseOpacity;
      return;
    }

    progress += dt / fallDurationSec;
    if (progress > 1) progress = 1;

    // Vertical: slight ease-in over full fall (mostly linear).
    final verticalT = Curves.easeIn.transform(progress * 0.15 + progress * 0.85);
    y = -20 + verticalT * (canvas.height + 40);

    final amp = canvas.width * CherryBlossomPeacePetalSpec.driftAmplitudeFactor;
    final driftT = progress * fallDurationSec;
    final phase = (driftT / driftPeriodSec) % 1.0;
    final easeDrift = Curves.easeInOut.transform(phase);
    // Horizontal ease slows vertical feel at drift apex via coupled opacity of motion.
    x = originX +
        driftSign * amp * math.sin(driftPhase + easeDrift * math.pi * 2);
    rotation += spin * dt;

    final fadeStart = 1.0 - CherryBlossomPeacePetalSpec.groundFadeTravelFraction;
    if (progress >= fadeStart) {
      final fadeT = ((progress - fadeStart) /
              CherryBlossomPeacePetalSpec.groundFadeTravelFraction)
          .clamp(0.0, 1.0);
      displayOpacity = baseOpacity * (1.0 - fadeT);
    } else {
      displayOpacity = baseOpacity;
    }
  }
}

class _PeacePetalPainter extends CustomPainter {
  _PeacePetalPainter({required this.petals, this.litePaint = false});

  final List<_PeacePetal> petals;
  final bool litePaint;

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      _paintPetal(canvas, petal);
    }
  }

  void _paintPetal(Canvas canvas, _PeacePetal petal) {
    final w = CherryBlossomPeacePetalSpec.baseWidth * petal.sizeScale;
    final h = CherryBlossomPeacePetalSpec.baseHeight * petal.sizeScale;
    final opacity = petal.displayOpacity.clamp(0.0, 1.0);
    if (opacity <= 0.01) return;

    canvas.save();
    canvas.translate(petal.x, petal.y);
    canvas.rotate(petal.rotation);

    final path = _teardropPath(w, h);
    final fill = petal.type.fillTop.withValues(alpha: opacity);
    final tip = petal.type.fillTip.withValues(alpha: opacity);

    if (!litePaint) {
      // Outer glow
      final glowRadius = math.max(w, h);
      final outerPaint = Paint()
        ..color = fill.withValues(alpha: opacity * 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 1.25);
      canvas.drawPath(
        _teardropPath(w * 2.5, h * 2.5),
        outerPaint,
      );

      // Mid glow
      final midPaint = Paint()
        ..color = fill.withValues(alpha: opacity * 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.55);
      canvas.drawPath(
        _teardropPath(w * 1.4, h * 1.4),
        midPaint,
      );
    }

    // Fill with tip gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, -h / 2),
        Offset(0, h / 2),
        [fill, tip],
      );
    canvas.drawPath(path, fillPaint);

    // Warm blush at wide top for luminous white
    final blush = petal.type.blushEdge;
    if (blush != null) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -h * 0.28),
          width: w * 0.85,
          height: h * 0.35,
        ),
        Paint()..color = blush.withValues(alpha: opacity * 0.40),
      );
    }

    // Inner highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -h * 0.22),
        width: w * 0.30,
        height: h * 0.22,
      ),
      Paint()
        ..color =
            const Color(0xFFFFFFFF).withValues(alpha: opacity * 0.45),
    );

    // Stronger front-layer glow pass
    if (!litePaint && petal.layer.strongGlow) {
      final glowRadius = math.max(w, h);
      canvas.drawPath(
        path,
        Paint()
          ..color = fill.withValues(alpha: opacity * 0.20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    canvas.restore();
  }

  Path _teardropPath(double w, double h) {
    // Soft teardrop: wider at top, rounded point at bottom.
    final path = Path();
    path.moveTo(0, h / 2);
    path.cubicTo(w * 0.55, h * 0.25, w * 0.55, -h * 0.15, 0, -h / 2);
    path.cubicTo(-w * 0.55, -h * 0.15, -w * 0.55, h * 0.25, 0, h / 2);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _PeacePetalPainter oldDelegate) => true;
}
