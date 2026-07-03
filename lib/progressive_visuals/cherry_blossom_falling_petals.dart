import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Falling cherry blossom petals from stage 1 upward; rate doubles each stage.
class CherryBlossomFallingPetals extends StatefulWidget {
  const CherryBlossomFallingPetals({
    super.key,
    required this.size,
    required this.stageIndex,
    this.animate = true,
  });

  final Size size;
  final int stageIndex;
  final bool animate;

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
    final dt = _lastElapsed == null
        ? 0.016
        : (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _spawnAccumulator += dt;
    final interval = _spawnInterval;
    while (_spawnAccumulator >= interval) {
      _spawnAccumulator -= interval;
      _spawnPetal();
    }
    setState(() {
      for (final petal in _petals) {
        petal.y += petal.speed * dt;
        petal.x += petal.drift * dt;
        petal.rotation += petal.spin * dt;
      }
      _petals.removeWhere((p) => p.y > widget.size.height + 12);
    });
  }

  void _spawnPetal() {
    final random = math.Random();
    _petals.add(
      _Petal(
        x: random.nextDouble() * widget.size.width,
        y: -8,
        speed: widget.size.height * (0.08 + random.nextDouble() * 0.05),
        drift: (random.nextDouble() - 0.5) * 18,
        spin: (random.nextDouble() - 0.5) * 2.5,
        rotation: random.nextDouble() * math.pi,
        radius: 2.5 + random.nextDouble() * 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stageIndex < 1) return const SizedBox.shrink();
    return CustomPaint(
      size: widget.size,
      painter: _PetalPainter(petals: _petals),
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
  final double drift;
  final double spin;
  double rotation;
  final double radius;
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({required this.petals});

  final List<_Petal> petals;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB7C5).withValues(alpha: 0.82);
    for (final petal in petals) {
      canvas.save();
      canvas.translate(petal.x, petal.y);
      canvas.rotate(petal.rotation);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: petal.radius * 2.2, height: petal.radius),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) => true;
}
