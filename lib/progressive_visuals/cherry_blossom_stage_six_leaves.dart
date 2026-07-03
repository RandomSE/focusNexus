import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Stage 6 side leaves: white on the lit side, black on the shadow side.
class CherryBlossomStageSixLeaves extends StatefulWidget {
  const CherryBlossomStageSixLeaves({
    super.key,
    required this.size,
    this.animate = true,
  });

  final Size size;
  final bool animate;

  @override
  State<CherryBlossomStageSixLeaves> createState() =>
      _CherryBlossomStageSixLeavesState();
}

class _CherryBlossomStageSixLeavesState extends State<CherryBlossomStageSixLeaves>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Leaf> _leaves = [];
  double _spawnAccumulator = 0;

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
    const dt = 0.016;
    _spawnAccumulator += dt;
    while (_spawnAccumulator >= 0.55) {
      _spawnAccumulator -= 0.55;
      _spawnLeaf();
    }
    setState(() {
      for (final leaf in _leaves) {
        leaf.y += leaf.speed * dt;
        leaf.x += leaf.drift * dt;
        leaf.rotation += leaf.spin * dt;
      }
      _leaves.removeWhere((l) => l.y > widget.size.height + 16);
    });
  }

  void _spawnLeaf() {
    final random = math.Random();
    final fromLeft = random.nextBool();
    _leaves.add(
      _Leaf(
        x: fromLeft ? -6 : widget.size.width + 6,
        y: widget.size.height * (0.22 + random.nextDouble() * 0.42),
        speed: widget.size.height * (0.03 + random.nextDouble() * 0.02),
        drift: fromLeft ? 22 + random.nextDouble() * 16 : -(22 + random.nextDouble() * 16),
        spin: (random.nextDouble() - 0.5) * 3,
        rotation: random.nextDouble() * math.pi,
        lightSide: fromLeft,
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
  });

  double x;
  double y;
  final double speed;
  final double drift;
  final double spin;
  double rotation;
  final bool lightSide;
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
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(5, -3, 10, 0)
        ..quadraticBezierTo(5, 3, 0, 0);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) => true;
}
