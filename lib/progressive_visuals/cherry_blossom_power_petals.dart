import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'cherry_blossom_fx_timing.dart';
import 'cherry_blossom_power_petal_spec.dart';

/// Force-fragment petals for Power (Eternal Tree) finale.
class CherryBlossomPowerPetals extends StatefulWidget {
  const CherryBlossomPowerPetals({
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

  /// Scales drawn petal size (bonsai pots use a smaller mul).
  final double sizeMul;

  final int? minConcurrent;
  final int? maxConcurrent;

  /// Skip expensive MaskFilter glows (required for multi-pot bonsai).
  final bool litePaint;

  static const double bonsaiMinSizeScale = 0.275;
  static const double bonsaiSizeMul = bonsaiMinSizeScale;
  static const double bonsaiMaxOverMin = 2.0;
  static double get bonsaiMaxSizeScale =>
      bonsaiMinSizeScale * bonsaiMaxOverMin;

  static double bonsaiSizeScaleForRoll(double roll) {
    final t = roll.clamp(0.0, 1.0);
    return bonsaiMinSizeScale + t * (bonsaiMaxSizeScale - bonsaiMinSizeScale);
  }

  static const int bonsaiMinConcurrent = 4;
  static const int bonsaiMaxConcurrent = 7;

  @override
  State<CherryBlossomPowerPetals> createState() =>
      _CherryBlossomPowerPetalsState();
}

class _CherryBlossomPowerPetalsState extends State<CherryBlossomPowerPetals>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_PowerPetal> _petals = [];
  final math.Random _random = math.Random(13);
  Duration? _lastElapsed;
  double _burstCooldown = 0;
  double _risingCooldown = 0;
  double _lastSilenceSec = -1;
  bool _inBurstWindow = false;
  double _burstWindowRemaining = 0;
  int _burstRemaining = 0;
  late int _targetConcurrent;

  int get _minConcurrent =>
      widget.minConcurrent ?? CherryBlossomPowerPetalSpec.minConcurrent;

  int get _maxConcurrent =>
      widget.maxConcurrent ?? CherryBlossomPowerPetalSpec.maxConcurrent;

  int get _fallingCount => _petals.where((p) => !p.rising).length;

  @override
  void initState() {
    super.initState();
    final span = math.max(0, _maxConcurrent - _minConcurrent);
    _targetConcurrent = _minConcurrent + _random.nextInt(span + 1);
    _risingCooldown = CherryBlossomPowerPetalSpec.risingPetalMinSec +
        _random.nextDouble() *
            (CherryBlossomPowerPetalSpec.risingPetalMaxSec -
                CherryBlossomPowerPetalSpec.risingPetalMinSec);
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
      _beginBurst();
    }
  }

  @override
  void didUpdateWidget(covariant CherryBlossomPowerPetals oldWidget) {
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

    _burstCooldown -= dt;
    _risingCooldown -= dt;

    if (_inBurstWindow) {
      _burstWindowRemaining -= dt;
      if (_burstRemaining > 0 && _fallingCount < _targetConcurrent) {
        _spawnFalling();
        _burstRemaining--;
      }
      if (_burstRemaining <= 0 || _burstWindowRemaining <= 0) {
        _inBurstWindow = false;
        _burstRemaining = 0;
        _burstCooldown = _nextSilence();
      }
    } else if (_burstCooldown <= 0 && _fallingCount < _targetConcurrent) {
      _beginBurst();
    }

    if (_risingCooldown <= 0) {
      _spawnRising();
      _risingCooldown = CherryBlossomPowerPetalSpec.risingPetalMinSec +
          _random.nextDouble() *
              (CherryBlossomPowerPetalSpec.risingPetalMaxSec -
                  CherryBlossomPowerPetalSpec.risingPetalMinSec);
    }

    setState(() {
      for (final petal in _petals) {
        petal.advance(dt, widget.size);
      }
      _petals.removeWhere((p) => p.done);
    });
  }

  double _nextSilence() {
    var silence = CherryBlossomPowerPetalSpec.silenceMinSec +
        _random.nextDouble() *
            (CherryBlossomPowerPetalSpec.silenceMaxSec -
                CherryBlossomPowerPetalSpec.silenceMinSec);
    // Never the same silence interval twice in a row.
    if (_lastSilenceSec >= 0 && (silence - _lastSilenceSec).abs() < 0.35) {
      silence = silence >= 4.0
          ? CherryBlossomPowerPetalSpec.silenceMinSec + 0.4
          : CherryBlossomPowerPetalSpec.silenceMaxSec - 0.4;
    }
    _lastSilenceSec = silence;
    return silence;
  }

  void _beginBurst() {
    final burst = CherryBlossomPowerPetalSpec.burstSizeMin +
        _random.nextInt(
          CherryBlossomPowerPetalSpec.burstSizeMax -
              CherryBlossomPowerPetalSpec.burstSizeMin +
              1,
        );
    final room = _targetConcurrent - _fallingCount;
    _burstRemaining = math.min(burst, math.max(0, room));
    if (_burstRemaining <= 0) {
      _burstCooldown = _nextSilence();
      return;
    }
    _inBurstWindow = true;
    _burstWindowRemaining = CherryBlossomPowerPetalSpec.burstWindowSec;
    _spawnFalling();
    _burstRemaining--;
  }

  double _sizeMulForRoll(double roll) {
    if (widget.litePaint) {
      // Do not multiply [sizeMul] again; bonsaiSizeScaleForRoll already encodes pot size.
      return CherryBlossomPowerPetals.bonsaiSizeScaleForRoll(roll);
    }
    return widget.sizeMul;
  }

  void _spawnFalling() {
    final type = CherryBlossomPowerPetalSpec.typeForRoll(_random.nextDouble());
    final sizePx = CherryBlossomPowerPetalSpec.sizePxForType(
          type,
          _random.nextDouble(),
        ) *
        _sizeMulForRoll(_random.nextDouble());

    final slow =
        _random.nextDouble() < CherryBlossomPowerPetalSpec.slowFallChance;
    final fallDuration = slow
        ? CherryBlossomPowerPetalSpec.slowFallMinSec +
            _random.nextDouble() *
                (CherryBlossomPowerPetalSpec.slowFallMaxSec -
                    CherryBlossomPowerPetalSpec.slowFallMinSec)
        : CherryBlossomPowerPetalSpec.fastFallMinSec +
            _random.nextDouble() *
                (CherryBlossomPowerPetalSpec.fastFallMaxSec -
                    CherryBlossomPowerPetalSpec.fastFallMinSec);

    final zeroDrift =
        _random.nextDouble() < CherryBlossomPowerPetalSpec.zeroDriftChance;
    final driftPeriod = CherryBlossomPowerPetalSpec.driftPeriodMinSec +
        _random.nextDouble() *
            (CherryBlossomPowerPetalSpec.driftPeriodMaxSec -
                CherryBlossomPowerPetalSpec.driftPeriodMinSec);

    final fixedAngle =
        _random.nextDouble() < CherryBlossomPowerPetalSpec.fixedAngleChance;
    final rotation = fixedAngle
        ? (_random.nextDouble() * 2 - 1) *
            CherryBlossomPowerPetalSpec.fixedAngleMaxRad
        : 0.0;
    final spin = fixedAngle
        ? 0.0
        : (CherryBlossomPowerPetalSpec.rotationRadPerSecMin +
                _random.nextDouble() *
                    (CherryBlossomPowerPetalSpec.rotationRadPerSecMax -
                        CherryBlossomPowerPetalSpec.rotationRadPerSecMin)) *
            (_random.nextBool() ? 1.0 : -1.0);

    final baseOpacity = type == PowerPetalType.ash
        ? CherryBlossomPowerPetalSpec.ashOpacityMin +
            _random.nextDouble() *
                (CherryBlossomPowerPetalSpec.ashOpacityMax -
                    CherryBlossomPowerPetalSpec.ashOpacityMin)
        : CherryBlossomPowerPetalSpec.opacityMin +
            _random.nextDouble() *
                (CherryBlossomPowerPetalSpec.opacityMax -
                    CherryBlossomPowerPetalSpec.opacityMin);

    // 70% near upper center (vortex); 30% anywhere in upper 20%.
    final double spawnX;
    final double spawnY;
    if (_random.nextDouble() < 0.70) {
      final half = widget.size.width * 0.35;
      spawnX = widget.size.width * 0.5 +
          (_random.nextDouble() * 2 - 1) * half;
      spawnY = -sizePx;
    } else {
      spawnX = _random.nextDouble() * widget.size.width;
      spawnY = _random.nextDouble() * widget.size.height * 0.20;
    }

    final petal = _PowerPetal(
      originX: spawnX.clamp(0.0, widget.size.width),
      type: type,
      sizePx: sizePx,
      fallDurationSec: fallDuration,
      spin: spin,
      rotation: rotation,
      baseOpacity: baseOpacity,
      rising: false,
      rotating: !fixedAngle,
      zeroDrift: zeroDrift,
      driftPeriodSec: driftPeriod,
      driftPhase: _random.nextDouble() * math.pi * 2,
      driftSign: _random.nextBool() ? 1.0 : -1.0,
      pulsePhase: _random.nextDouble() * math.pi * 2,
      pulsePeriod: CherryBlossomPowerPetalSpec.emberPulsePeriodMinSec +
          _random.nextDouble() *
              (CherryBlossomPowerPetalSpec.emberPulsePeriodMaxSec -
                  CherryBlossomPowerPetalSpec.emberPulsePeriodMinSec),
    );
    petal.x = petal.originX;
    petal.y = spawnY;
    _petals.add(petal);
  }

  void _spawnRising() {
    // Rising signature uses deep violet (mysticism / canopy tie).
    final sizePx = CherryBlossomPowerPetalSpec.sizePxForType(
          PowerPetalType.deepViolet,
          _random.nextDouble(),
        ) *
        _sizeMulForRoll(_random.nextDouble());
    // Use a mid slow-fall duration scaled by risingSpeedFactor.
    final baseFall = CherryBlossomPowerPetalSpec.slowFallMinSec +
        _random.nextDouble() *
            (CherryBlossomPowerPetalSpec.slowFallMaxSec -
                CherryBlossomPowerPetalSpec.slowFallMinSec);
    final duration = baseFall / CherryBlossomPowerPetalSpec.risingSpeedFactor;
    final x = widget.size.width * 0.5 +
        (_random.nextDouble() - 0.5) * widget.size.width * 0.08;

    final petal = _PowerPetal(
      originX: x,
      type: PowerPetalType.deepViolet,
      sizePx: sizePx,
      fallDurationSec: duration,
      spin: 0,
      rotation: 0,
      baseOpacity: CherryBlossomPowerPetalSpec.opacityMax,
      rising: true,
      rotating: false,
      zeroDrift: true,
      driftPeriodSec: 8,
      driftPhase: 0,
      driftSign: 1,
      pulsePhase: 0,
      pulsePeriod: 3,
    );
    petal.x = x;
    petal.y = widget.size.height + sizePx;
    _petals.add(petal);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: _PowerPetalPainter(
        petals: List<_PowerPetal>.from(_petals),
        litePaint: widget.litePaint,
      ),
    );
  }
}

class _PowerPetal {
  _PowerPetal({
    required this.originX,
    required this.type,
    required this.sizePx,
    required this.fallDurationSec,
    required this.spin,
    required this.rotation,
    required this.baseOpacity,
    required this.rising,
    required this.rotating,
    required this.zeroDrift,
    required this.driftPeriodSec,
    required this.driftPhase,
    required this.driftSign,
    required this.pulsePhase,
    required this.pulsePeriod,
  });

  final double originX;
  final PowerPetalType type;
  final double sizePx;
  final double fallDurationSec;
  final double spin;
  double rotation;
  final double baseOpacity;
  final bool rising;
  final bool rotating;
  final bool zeroDrift;
  final double driftPeriodSec;
  final double driftPhase;
  final double driftSign;
  final double pulsePhase;
  final double pulsePeriod;

  double progress = 0;
  double x = 0;
  double y = 0;
  double displayOpacity = 1;
  /// 0..1 fall progress mirrored for color lifecycle in the painter.
  double displayFallProgress = 0;
  /// 0 luminous start, 1 mid-fall ember intensify (before ash).
  double displayIntensify = 0;
  /// 0..1 ash fade near end of fall.
  double displayAsh = 0;
  double displaySizeScale = 1;
  double emberPulse = 0;
  bool done = false;

  void advance(double dt, Size canvas) {
    if (rising) {
      progress += dt / fallDurationSec;
      if (progress >= 1) {
        done = true;
        return;
      }
      y = canvas.height + 10 - progress * (canvas.height + 40);
      x = originX;
      // Fade in / fade out into canopy.
      final fadeIn = CherryBlossomPowerPetalSpec.risingFadeInSec /
          fallDurationSec;
      final fadeOut = CherryBlossomPowerPetalSpec.risingFadeOutSec /
          fallDurationSec;
      var op = baseOpacity;
      if (progress < fadeIn) {
        op *= (progress / fadeIn).clamp(0.0, 1.0);
      } else if (progress > 1.0 - fadeOut) {
        op *= ((1.0 - progress) / fadeOut).clamp(0.0, 1.0);
      }
      displayOpacity = op;
      displayFallProgress = progress;
      displayIntensify = 0.35;
      displayAsh = 0;
      return;
    }

    // Progress maps 0..1 over fallDuration with easeIn acceleration early.
    // Speed starts at 40% and reaches full by 25% progress.
    final accelEnd = CherryBlossomPowerPetalSpec.accelProgressEnd;
    final startF = CherryBlossomPowerPetalSpec.accelStartSpeedFactor;
    double speedFactor(double p) {
      if (p < accelEnd) {
        final u = (p / accelEnd).clamp(0.0, 1.0);
        final eased = Curves.easeIn.transform(u);
        return startF + (1.0 - startF) * eased;
      }
      return 1.0;
    }

    progress += (dt / fallDurationSec) * speedFactor(progress);
    if (progress >= 1) {
      done = true;
      return;
    }

    y = -sizePx + progress * (canvas.height + sizePx * 2);

    if (zeroDrift) {
      x = originX;
    } else {
      final amp =
          canvas.width * CherryBlossomPowerPetalSpec.driftAmplitudeFactor;
      final omega = math.pi * 2 / driftPeriodSec;
      final drift =
          driftSign * amp * math.sin(driftPhase + progress * fallDurationSec * omega);
      x = originX + drift;
    }

    if (rotating) {
      rotation += spin * dt;
    }

    var opacity = baseOpacity;
    if (type.pulses) {
      emberPulse = math.sin(
        pulsePhase + progress * fallDurationSec * (math.pi * 2 / pulsePeriod),
      );
      opacity = (opacity *
              (1.0 +
                  emberPulse * CherryBlossomPowerPetalSpec.emberPulseAmplitude))
          .clamp(0.0, 1.0);
    }

    displayFallProgress = progress.clamp(0.0, 1.0);
    final lumEnd = CherryBlossomPowerPetalSpec.luminousEndProgress;
    final ashStart = CherryBlossomPowerPetalSpec.ashFadeStartProgress;
    if (progress <= lumEnd) {
      displayIntensify = 0;
      displayAsh = 0;
    } else if (progress < ashStart) {
      displayIntensify = Curves.easeInOut.transform(
        ((progress - lumEnd) / (ashStart - lumEnd)).clamp(0.0, 1.0),
      );
      displayAsh = 0;
    } else {
      displayIntensify = 1;
      displayAsh = Curves.easeIn.transform(
        ((progress - ashStart) / (1.0 - ashStart)).clamp(0.0, 1.0),
      );
      // Dim as force collapses into ash.
      opacity *= 1.0 - 0.45 * displayAsh;
    }

    // Bottom 10% of the canvas: dissolve into silence.
    final dissolveStart = canvas.height * 0.90;
    if (y >= dissolveStart) {
      final band = math.max(canvas.height * 0.10, sizePx);
      final dissolve = Curves.easeIn.transform(
        ((y - dissolveStart) / band).clamp(0.0, 1.0),
      );
      opacity *= 1.0 - dissolve;
      displaySizeScale = 1.0 - dissolve;
      displayAsh = math.max(displayAsh, dissolve);
      if (dissolve >= 0.98) {
        done = true;
        return;
      }
    } else {
      displaySizeScale = 1.0;
    }

    displayOpacity = opacity;
  }
}

class _PowerPetalPainter extends CustomPainter {
  _PowerPetalPainter({
    required this.petals,
    this.litePaint = false,
  });

  final List<_PowerPetal> petals;
  final bool litePaint;

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      if (petal.done) continue;
      drawPowerPetal(
        canvas,
        center: Offset(petal.x, petal.y),
        size: petal.sizePx * petal.displaySizeScale,
        angle: petal.rotation,
        type: petal.type,
        opacity: petal.displayOpacity,
        intensify: petal.displayIntensify,
        ash: petal.displayAsh,
        litePaint: litePaint,
        emberPulse: petal.emberPulse,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PowerPetalPainter oldDelegate) => true;
}

/// Sharp teardrop force fragment (pointed bottom, flattened top).
void drawPowerPetal(
  Canvas canvas,
  {
  required Offset center,
  required double size,
  required double angle,
  required PowerPetalType type,
  required double opacity,
  double intensify = 0,
  double ash = 0,
  bool litePaint = false,
  double emberPulse = 0,
}) {
  final op = opacity.clamp(0.0, 1.0);
  if (op <= 0.01 || size <= 0.5) return;
  final intens = intensify.clamp(0.0, 1.0);
  final ashT = ash.clamp(0.0, 1.0);

  final palette = CherryBlossomPowerPetalSpec.paletteFor(type);
  final luminous = palette.$1;
  final core = palette.$2;
  final intense = palette.$3;
  final glow = palette.$4;

  // Luminous detach -> mid-fall ember saturate -> ash silence.
  final Color bodyTop;
  final Color bodyTip;
  if (ashT > 0.001) {
    final hotTop = Color.lerp(core, intense, intens)!;
    final hotTip = Color.lerp(intense, CherryBlossomPowerPetalSpec.ashEndTip, 0.35)!;
    bodyTop = Color.lerp(hotTop, CherryBlossomPowerPetalSpec.ashEnd, ashT)!;
    bodyTip = Color.lerp(hotTip, CherryBlossomPowerPetalSpec.ashEndTip, ashT)!;
  } else {
    bodyTop = Color.lerp(luminous, Color.lerp(core, intense, intens)!, intens)!;
    bodyTip = Color.lerp(core, intense, intens)!;
  }

  // Soft glow strongest at detach, fades as ash takes over.
  final glowStrength = (1.0 - ashT) * (0.55 - 0.20 * intens);
  final glowColor = Color.lerp(glow, intense, intens * 0.5)!;

  final path = powerPetalPath(center, size);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  canvas.translate(-center.dx, -center.dy);

  if (!litePaint && glowStrength > 0.04) {
    final pulse = 1.0 + emberPulse * 0.06;
    canvas.drawPath(
      powerPetalPath(center, size * (1.45 + 0.25 * glowStrength) * pulse),
      Paint()
        ..color = glowColor.withValues(alpha: op * 0.18 * glowStrength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.45),
    );
  }

  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - size * 0.35),
        Offset(center.dx, center.dy + size * 0.65),
        [
          bodyTop.withValues(alpha: op),
          bodyTip.withValues(alpha: op),
        ],
      ),
  );

  // Subtle vein; darkens into ash without a rim highlight.
  final vein = Color.lerp(intense, CherryBlossomPowerPetalSpec.ashEnd, ashT)!;
  canvas.drawLine(
    Offset(center.dx, center.dy - size * 0.28),
    Offset(center.dx, center.dy + size * 0.55),
    Paint()
      ..color = vein.withValues(alpha: op * (0.28 + 0.22 * intens) * (1.0 - 0.5 * ashT))
      ..strokeWidth = 0.55 + 0.35 * intens
      ..style = PaintingStyle.stroke,
  );

  canvas.restore();
}

/// Sharp teardrop path: flattened top, pointed bottom.
Path powerPetalPath(Offset center, double size) {
  final path = Path();
  path.moveTo(center.dx, center.dy - size * 0.35);
  path.cubicTo(
    center.dx + size * 0.55,
    center.dy - size * 0.20,
    center.dx + size * 0.30,
    center.dy + size * 0.30,
    center.dx,
    center.dy + size * 0.65,
  );
  path.cubicTo(
    center.dx - size * 0.30,
    center.dy + size * 0.30,
    center.dx - size * 0.55,
    center.dy - size * 0.20,
    center.dx,
    center.dy - size * 0.35,
  );
  path.close();
  return path;
}
