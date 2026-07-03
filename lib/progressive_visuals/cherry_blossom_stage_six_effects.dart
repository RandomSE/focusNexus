import 'package:flutter/material.dart';

/// Subtle pulse/shimmer for stages 6+ (no painted sky).
class CherryBlossomStageSixEffects extends StatefulWidget {
  const CherryBlossomStageSixEffects({
    super.key,
    required this.size,
    this.animate = true,
  });

  final Size size;
  final bool animate;

  @override
  State<CherryBlossomStageSixEffects> createState() =>
      _CherryBlossomStageSixEffectsState();
}

class _CherryBlossomStageSixEffectsState extends State<CherryBlossomStageSixEffects>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CherryBlossomStageSixEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = widget.animate ? _controller.value : 0.35;
        return CustomPaint(
          size: widget.size,
          painter: _AlivePainter(intensity: t),
        );
      },
    );
  }
}

class _AlivePainter extends CustomPainter {
  _AlivePainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final glow = Paint()
      ..color = const Color(0xFFFFB7C5).withValues(alpha: 0.04 + 0.05 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * (0.55 + 0.05 * intensity),
        height: size.height * (0.35 + 0.04 * intensity),
      ),
      glow,
    );
    final shimmer = Paint()
      ..color = Colors.white.withValues(alpha: 0.04 + 0.06 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.38),
        width: size.width * 0.25,
        height: size.height * 0.12,
      ),
      shimmer,
    );
  }

  @override
  bool shouldRepaint(covariant _AlivePainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}
