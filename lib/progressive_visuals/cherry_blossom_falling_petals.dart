import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'cherry_blossom_stage_catalog.dart';

/// Falling cherry blossom petals from stage 1 upward; rate doubles each stage.
/// Petals settle on the ground strip, then fade out.
class CherryBlossomFallingPetals extends StatefulWidget {
  const CherryBlossomFallingPetals({
    super.key,
    required this.size,
    required this.stageIndex,
    this.animate = true,
    this.compact = false,
    this.sizeMul = 1.0,
  });

  final Size size;
  final int stageIndex;
  final bool animate;

  /// Bonsai pots: half petal radius so leaves match cell scale.
  final bool compact;

  /// Extra scale vs bonsai-garden reference (zen placeables use cellWidth / 72).
  final double sizeMul;

  /// Soft stage-tinted petal fills (tree art stays the hero).
  static Color colorForStage(int stageIndex) {
    return switch (stageIndex) {
      1 => const Color(0xFFFFB7C5),
      2 => const Color(0xFFFFC8D4),
      3 => const Color(0xFFFFD0A8),
      4 => const Color(0xFFE8A0C0),
      5 => const Color(0xFFC8A0E8),
      _ => const Color(0xFFFFB7C5),
    };
  }

  /// Y of the ground top (petals stop here). Matches painted ground strip.
  static double groundTopY(Size size) =>
      size.height * (1.0 - CherryBlossomStageCatalog.groundInsetFraction);

  /// Seconds to fade after landing.
  static const double landFadeSeconds = 0.85;

  @override
  State<CherryBlossomFallingPetals> createState() =>
      _CherryBlossomFallingPetalsState();
}

class _CherryBlossomFallingPetalsState extends State<CherryBlossomFallingPetals>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Petal> _petals = [];
  double _spawnAccumulator = 0;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant CherryBlossomFallingPetals oldWidget) {
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

  double get _spawnInterval {
    if (widget.stageIndex < 1) return double.infinity;
    return 4.0 / math.pow(2, widget.stageIndex - 1);
  }

  void _onTick(Duration elapsed) {
    if (!widget.animate || widget.stageIndex < 1) return;
    final rawDt = _lastElapsed == null
        ? 0.016
        : (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (rawDt <= 0) return;
    // Clamp long frames so catch-up does not freeze or teleport petals.
    final dt = rawDt > 0.1 ? 0.1 : rawDt;
    _spawnAccumulator += dt;
    final interval = _spawnInterval;
    while (_spawnAccumulator >= interval) {
      _spawnAccumulator -= interval;
      _spawnPetal();
    }
    final groundY = CherryBlossomFallingPetals.groundTopY(widget.size);
    setState(() {
      for (final petal in _petals) {
        if (petal.landed) {
          petal.fadeT += dt / CherryBlossomFallingPetals.landFadeSeconds;
          continue;
        }
        petal.y += petal.speed * dt;
        petal.x += petal.drift * dt;
        petal.rotation += petal.spin * dt;
        if (petal.y >= groundY) {
          petal.y = groundY;
          petal.landed = true;
          petal.drift = 0;
          petal.spin *= 0.2;
        }
      }
      _petals.removeWhere((p) => p.landed && p.fadeT >= 1.0);
    });
  }

  void _spawnPetal() {
    final random = math.Random();
    final radiusScale = (widget.compact ? 0.5 : 1.0) * widget.sizeMul;
    _petals.add(
      _Petal(
        x: random.nextDouble() * widget.size.width,
        y: -8,
        speed: widget.size.height * (0.08 + random.nextDouble() * 0.05),
        drift: (random.nextDouble() - 0.5) * 18,
        spin: (random.nextDouble() - 0.5) * 2.5,
        rotation: random.nextDouble() * math.pi,
        radius: (2.5 + random.nextDouble() * 2) * radiusScale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stageIndex < 1) return const SizedBox.shrink();
    return CustomPaint(
      size: widget.size,
      painter: _PetalPainter(
        petals: _petals,
        color: CherryBlossomFallingPetals.colorForStage(widget.stageIndex),
      ),
    );
  }
}

class _Petal {
  _Petal({
    required this.x,
    required this.y,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.rotation,
    required this.radius,
  });

  double x;
  double y;
  final double speed;
  double drift;
  double spin;
  double rotation;
  final double radius;
  bool landed = false;
  double fadeT = 0;
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({required this.petals, required this.color});

  final List<_Petal> petals;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      final alpha = petal.landed
          ? (0.82 * (1.0 - petal.fadeT.clamp(0.0, 1.0)))
          : 0.82;
      if (alpha <= 0.01) continue;
      final paint = Paint()..color = color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(petal.x, petal.y);
      canvas.rotate(petal.rotation);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: petal.radius * 2.2,
          height: petal.radius,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) => true;
}
