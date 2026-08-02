import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'cherry_blossom_fx_timing.dart';

/// Stage 6 side petals: white on the lit (right) side, black on the shadow (left).
/// Concurrent count grows 1:1 with display level (1 -> 2 -> 3 ...).
class CherryBlossomStageSixLeaves extends StatefulWidget {
  const CherryBlossomStageSixLeaves({
    super.key,
    required this.size,
    required this.displayLevel,
    this.maxConcurrent,
    this.animate = true,
    this.sizeScale = 1.0,
  });

  final Size size;

  /// HUD level within stage 6 (1..25).
  final int displayLevel;

  /// Optional cap for small surfaces (e.g. bonsai pots).
  final int? maxConcurrent;
  final bool animate;

  /// Drawn leaf scale (bonsai pots use 0.5).
  final double sizeScale;

  /// Target petals on screen for [displayLevel], optionally capped for small pots.
  static int targetConcurrentCount(int displayLevel, {int? maxConcurrent}) {
    final n = displayLevel.clamp(1, 25);
    if (maxConcurrent == null) return n;
    return n.clamp(1, maxConcurrent);
  }

  /// Concurrent petals inside a bonsai pot (stage 6).
  static const int bonsaiPotConcurrent = 3;

  /// Leaf size multiplier for bonsai pots.
  static const double bonsaiSizeScale = 0.5;

  /// Stage 6 canopy is brighter on the right; white flutters from that side.
  static bool isLitSide({required bool fromLeft}) => !fromLeft;

  @override
  State<CherryBlossomStageSixLeaves> createState() =>
      _CherryBlossomStageSixLeavesState();
}

class _CherryBlossomStageSixLeavesState extends State<CherryBlossomStageSixLeaves>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Leaf> _leaves = [];
  double _spawnAccumulator = 0;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant CherryBlossomStageSixLeaves oldWidget) {
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

    final target = CherryBlossomStageSixLeaves.targetConcurrentCount(
      widget.displayLevel,
      maxConcurrent: widget.maxConcurrent,
    );
    // Spawn faster when below target; base interval shortens with higher levels.
    final interval = math.max(0.12, 0.55 / math.max(1, target / 3));
    _spawnAccumulator += dt;
    while (_spawnAccumulator >= interval && _leaves.length < target) {
      _spawnAccumulator -= interval;
      _spawnLeaf();
    }

    setState(() {
      for (final leaf in _leaves) {
        leaf.y += leaf.speed * dt;
        leaf.x += leaf.drift * dt;
        leaf.rotation += leaf.spin * dt;
      }
      _leaves.removeWhere(
        (l) =>
            l.y > widget.size.height + 16 ||
            l.x < -40 ||
            l.x > widget.size.width + 40,
      );
    });
  }

  void _spawnLeaf() {
    final random = math.Random();
    // Prefer spawning from the correct color side; slight mix for life.
    final preferLit = random.nextDouble() < 0.72;
    final fromLeft = preferLit ? false : true;
    final lit = CherryBlossomStageSixLeaves.isLitSide(fromLeft: fromLeft);
    _leaves.add(
      _Leaf(
        x: fromLeft ? -6 : widget.size.width + 6,
        y: widget.size.height * (0.18 + random.nextDouble() * 0.48),
        speed: widget.size.height * (0.028 + random.nextDouble() * 0.024),
        drift: fromLeft
            ? 18 + random.nextDouble() * 18
            : -(18 + random.nextDouble() * 18),
        spin: (random.nextDouble() - 0.5) * 2.8,
        rotation: random.nextDouble() * math.pi,
        lightSide: lit,
        size: (0.75 + random.nextDouble() * 0.7) * widget.sizeScale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: _LeafPainter(leaves: _leaves),
    );
  }
}

class _Leaf {
  _Leaf({
    required this.x,
    required this.y,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.rotation,
    required this.lightSide,
    required this.size,
  });

  double x;
  double y;
  final double speed;
  final double drift;
  final double spin;
  double rotation;
  final bool lightSide;
  final double size;
}

class _LeafPainter extends CustomPainter {
  _LeafPainter({required this.leaves});

  final List<_Leaf> leaves;

  @override
  void paint(Canvas canvas, Size size) {
    for (final leaf in leaves) {
      final paint = Paint()
        ..color = leaf.lightSide
            ? const Color(0xFFF8F8F8).withValues(alpha: 0.9)
            : const Color(0xFF101010).withValues(alpha: 0.85);
      canvas.save();
      canvas.translate(leaf.x, leaf.y);
      canvas.rotate(leaf.rotation);
      final s = leaf.size;
      // Soft teardrop petal (wider top, rounded tip).
      final path = Path()
        ..moveTo(0, 6 * s)
        ..cubicTo(5.5 * s, 2.5 * s, 5.5 * s, -3 * s, 0, -6 * s)
        ..cubicTo(-5.5 * s, -3 * s, -5.5 * s, 2.5 * s, 0, 6 * s)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) => true;
}
