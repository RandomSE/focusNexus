import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rich ambient backdrop for Living Canopy (stage 6) and finale (stage 7).
class CherryBlossomLivingCanopyBackground extends StatelessWidget {
  const CherryBlossomLivingCanopyBackground({
    super.key,
    required this.size,
    required this.stageIndex,
    this.animate = true,
  });

  final Size size;
  final int stageIndex;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _LivingCanopyBackgroundPainter(
        stageIndex: stageIndex,
        animate: animate,
      ),
    );
  }
}

class _LivingCanopyBackgroundPainter extends CustomPainter {
  _LivingCanopyBackgroundPainter({
    required this.stageIndex,
    required this.animate,
  }) : _time = animate ? DateTime.now().millisecondsSinceEpoch / 3200.0 : 0.35;

  final int stageIndex;
  final bool animate;
  final double _time;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pulse = 0.5 + 0.5 * math.sin(_time * math.pi * 2);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF050510),
            Color.lerp(
              const Color(0xFF1A0A28),
              const Color(0xFF2A1440),
              pulse,
            )!,
            const Color(0xFF3D1C4A),
            const Color(0xFF8A4068),
          ],
          stops: const [0.0, 0.35, 0.68, 1.0],
        ).createShader(rect),
    );

    void nebula(Offset c, Color color, double w, double h) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w, height: h),
        Paint()
          ..color = color.withValues(alpha: 0.14 + 0.06 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
    }

    nebula(
      Offset(size.width * 0.22, size.height * 0.18),
      const Color(0xFF4EC9B0),
      size.width * 0.55,
      size.height * 0.22,
    );
    nebula(
      Offset(size.width * 0.78, size.height * 0.24),
      const Color(0xFFB84E8A),
      size.width * 0.48,
      size.height * 0.18,
    );
    nebula(
      Offset(size.width * 0.5, size.height * 0.72),
      const Color(0xFFFFB7C5),
      size.width * 0.7,
      size.height * 0.28,
    );

    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 + 0.25 * pulse);
    final random = math.Random(29);
    for (var i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.72;
      canvas.drawCircle(Offset(x, y), i % 6 == 0 ? 1.8 : 1.0, starPaint);
    }

    final haloCenter = Offset(size.width * 0.5, size.height * 0.42);
    canvas.drawOval(
      Rect.fromCenter(
        center: haloCenter,
        width: size.width * (0.75 + 0.08 * pulse),
        height: size.height * (0.5 + 0.06 * pulse),
      ),
      Paint()
        ..color = const Color(0xFFFFE0C2).withValues(alpha: 0.1 + 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42),
    );

    if (stageIndex >= 7) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF1A1020).withValues(alpha: 0.65),
            ],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LivingCanopyBackgroundPainter oldDelegate) =>
      oldDelegate.stageIndex != stageIndex || oldDelegate.animate != animate;
}
