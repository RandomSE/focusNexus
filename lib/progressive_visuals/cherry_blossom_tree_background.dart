import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Programmatic sky/ground backgrounds for cherry blossom stages 0–5.
class CherryBlossomTreeBackground extends StatelessWidget {
  const CherryBlossomTreeBackground({
    super.key,
    required this.stageIndex,
    required this.size,
  });

  final int stageIndex;
  final Size size;

  @override
  Widget build(BuildContext context) {
    if (stageIndex < 0 || stageIndex > 5) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      size: size,
      painter: _CherryBlossomBackgroundPainter(stageIndex: stageIndex),
    );
  }
}

class _CherryBlossomBackgroundPainter extends CustomPainter {
  _CherryBlossomBackgroundPainter({required this.stageIndex});

  final int stageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    switch (stageIndex) {
      case 0:
        _paintStage0(canvas, size);
      case 1:
        _paintStage1(canvas, size);
      case 2:
        _paintStage2(canvas, size);
      case 3:
        _paintStage3(canvas, size);
      case 4:
        _paintStage4(canvas, size);
      case 5:
        _paintStage5(canvas, size);
      default:
        break;
    }
  }

  void _paintStage0(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFC8D8E0),
    );
    final groundH = size.height * 0.14;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - groundH, size.width, groundH),
      Paint()..color = const Color(0xFF6B4F2A),
    );
  }

  void _paintStage1(Canvas canvas, Size size) {
    _paintVerticalGradient(
      canvas,
      size,
      const Color(0xFFB8D4E8),
      const Color(0xFFD4E8F0),
    );
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF7A5C32),
      green: const Color(0xFF8A9E6A),
      greenHeight: size.height * 0.02,
    );
  }

  void _paintStage2(Canvas canvas, Size size) {
    _paintVerticalGradient(
      canvas,
      size,
      const Color(0xFFA8CCEA),
      const Color(0xFFC8E4F4),
    );
    final glow = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.42),
      radius: size.width * 0.28,
    );
    canvas.drawOval(
      glow,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF8A6A3A),
      green: const Color(0xFF8A9E6A),
      greenHeight: size.height * 0.035,
    );
  }

  void _paintStage3(Canvas canvas, Size size) {
    _paintVerticalGradient(
      canvas,
      size,
      const Color(0xFF87CEEB),
      const Color(0xFFE8C090),
    );
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF6B4A24),
      green: const Color(0xFF6B8E4A),
      greenHeight: size.height * 0.04,
    );
  }

  void _paintStage4(Canvas canvas, Size size) {
    _paintMultiStopSky(
      canvas,
      size,
      [
        (0.0, const Color(0xFF1A1A2E)),
        (0.55, const Color(0xFF4A2060)),
        (1.0, const Color(0xFFC4547A)),
      ],
    );
    _paintStars(canvas, size, count: 18, alpha: 0.75);
    _paintMoon(canvas, size, halo: false);
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF3A2410),
      green: Colors.transparent,
      greenHeight: 0,
    );
  }

  void _paintStage5(Canvas canvas, Size size) {
    _paintMultiStopSky(
      canvas,
      size,
      [
        (0.0, const Color(0xFF0D0D1F)),
        (0.45, const Color(0xFF3B1C4A)),
        (1.0, const Color(0xFFC4547A)),
      ],
    );
    _paintAurora(canvas, size);
    _paintNebula(canvas, size);
    _paintStars(canvas, size, count: 26, alpha: 0.95, clustered: true);
    _paintMoon(canvas, size, halo: true);
    final horizonGlow = Offset(size.width * 0.5, size.height * 0.78);
    final gradient = RadialGradient(
      colors: [
        const Color(0xFFFF8C69).withValues(alpha: 0.55),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Rect.fromCircle(center: horizonGlow, radius: size.width * 0.55),
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: horizonGlow, radius: size.width * 0.55),
        ),
    );
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF3A2410),
      green: Colors.transparent,
      greenHeight: 0,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.9),
        width: size.width * 0.62,
        height: size.height * 0.1,
      ),
      Paint()
        ..color = const Color(0xFFFFB7C5).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  void _paintVerticalGradient(
    Canvas canvas,
    Size size,
    Color top,
    Color bottom,
  ) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
  }

  void _paintMultiStopSky(
    Canvas canvas,
    Size size,
    List<(double, Color)> stops,
  ) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: stops.map((s) => s.$1).toList(),
          colors: stops.map((s) => s.$2).toList(),
        ).createShader(rect),
    );
  }

  void _paintGroundStrip(
    Canvas canvas,
    Size size, {
    required Color soil,
    required Color green,
    required double greenHeight,
  }) {
    final groundH = size.height * 0.14;
    final top = size.height - groundH;
    if (greenHeight > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, top - greenHeight, size.width, greenHeight),
        Paint()..color = green,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, groundH),
      Paint()..color = soil,
    );
  }


  void _paintStars(
    Canvas canvas,
    Size size, {
    required int count,
    required double alpha,
    bool clustered = false,
  }) {
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    final random = math.Random(11);
    for (var i = 0; i < count; i++) {
      var x = random.nextDouble() * size.width;
      var y = random.nextDouble() * size.height * 0.55;
      if (clustered && i % 7 == 0) {
        x = size.width * (0.2 + random.nextDouble() * 0.15);
        y = size.height * (0.08 + random.nextDouble() * 0.12);
      }
      final r = i % 5 == 0 ? 2.2 : 1.2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _paintMoon(Canvas canvas, Size size, {required bool halo}) {
    final center = Offset(size.width * 0.82, size.height * 0.14);
    if (halo) {
      canvas.drawCircle(
        center,
        size.width * 0.08,
        Paint()
          ..color = const Color(0xFFFFE0C2).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
    canvas.drawCircle(
      center,
      size.width * 0.045,
      Paint()..color = const Color(0xFFF5F0E8),
    );
  }

  void _paintAurora(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.08,
        size.width * 0.7,
        size.height * 0.2,
      )
      ..lineTo(size.width, size.height * 0.28)
      ..lineTo(size.width, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.22,
        0,
        size.height * 0.3,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3AAFA9).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    final path2 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.04,
        size.width,
        size.height * 0.16,
      )
      ..lineTo(size.width, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.16,
        size.width * 0.05,
        size.height * 0.22,
      )
      ..close();
    canvas.drawPath(
      path2,
      Paint()..color = const Color(0xFF7A4EB0).withValues(alpha: 0.18),
    );
  }

  void _paintNebula(Canvas canvas, Size size) {
    void wisp(Offset c, Color color) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: size.width * 0.35, height: size.height * 0.12),
        Paint()
          ..color = color.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }

    wisp(Offset(size.width * 0.25, size.height * 0.28), const Color(0xFFB84E8A));
    wisp(Offset(size.width * 0.68, size.height * 0.22), const Color(0xFF4EC9B0));
  }

  @override
  bool shouldRepaint(covariant _CherryBlossomBackgroundPainter oldDelegate) =>
      oldDelegate.stageIndex != stageIndex;
}

/// Scaffold color behind stages without painted sky (6+).
Color cherryBlossomScaffoldColor(int stageIndex) {
  if (stageIndex <= 5) {
    return const Color(0xFF1A1A2E);
  }
  return const Color(0xFF0D0D1F);
}

double? cherryBlossomLerpDouble(double? a, double? b, double t) =>
    lerpDouble(a, b, t);
