import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Programmatic sky/ground backgrounds for cherry blossom stages 0-5.
class CherryBlossomTreeBackground extends StatelessWidget {
  const CherryBlossomTreeBackground({
    super.key,
    required this.stageIndex,
    required this.size,
    this.compact = false,
  });

  final int stageIndex;
  final Size size;

  /// Bonsai pots: skip star speckles that read as noise at cell scale.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (stageIndex < 0 || stageIndex > 5) {
      return const SizedBox.shrink();
    }
    assert(size.width > 0 && size.height > 0);
    // Expand to parent (e.g. Positioned.fill) so sky always covers the viewport.
    return CustomPaint(
      painter: _CherryBlossomBackgroundPainter(
        stageIndex: stageIndex,
        compact: compact,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CherryBlossomBackgroundPainter extends CustomPainter {
  _CherryBlossomBackgroundPainter({
    required this.stageIndex,
    this.compact = false,
  });

  final int stageIndex;
  final bool compact;

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
    // Golden Afternoon: warm supporting sky. Tree is opaque via paper knockout,
    // so chroma can return without washing the canopy.
    _paintMultiStopSky(
      canvas,
      size,
      [
        (0.0, const Color(0xFF7A9BB0)),
        (0.40, const Color(0xFFA8B8C0)),
        (0.72, const Color(0xFFC4B8A4)),
        (1.0, const Color(0xFFC8B090)),
      ],
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.28),
        width: size.width * 0.40,
        height: size.height * 0.26,
      ),
      Paint()
        ..color = const Color(0xFFFFE0B0).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF6B4A24),
      green: const Color(0xFF6B8E4A),
      greenHeight: size.height * 0.028,
    );
  }

  void _paintStage4(Canvas canvas, Size size) {
    // Deep Twilight: indigo -> plum -> mauve dusk. Readable night, not black.
    _paintMultiStopSky(
      canvas,
      size,
      [
        (0.0, const Color(0xFF1A1A36)),
        (0.40, const Color(0xFF2E2248)),
        (0.70, const Color(0xFF4A2F5C)),
        (1.0, const Color(0xFF6A4068)),
      ],
    );
    if (!compact) {
      _paintStars(canvas, size, count: 16, alpha: 0.65);
    }
    _paintMoon(canvas, size, halo: false);
    // Cool separation pocket behind trunk (lavender, not hot pink).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.58),
        width: size.width * 0.48,
        height: size.height * 0.36,
      ),
      Paint()
        ..color = const Color(0xFFB8A0D0).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF3A2410),
      green: Colors.transparent,
      greenHeight: 0,
    );
  }

  void _paintStage5(Canvas canvas, Size size) {
    // Aurora Veil: deep violet with soft teal ribbon; PNG owns neon drama.
    _paintMultiStopSky(
      canvas,
      size,
      [
        (0.0, const Color(0xFF12122A)),
        (0.35, const Color(0xFF241E40)),
        (0.65, const Color(0xFF3A2A55)),
        (1.0, const Color(0xFF524066)),
      ],
    );
    _paintAuroraSoft(canvas, size);
    if (!compact) {
      _paintStars(canvas, size, count: 20, alpha: 0.70, clustered: true);
    }
    _paintMoon(canvas, size, halo: true);
    // Quiet horizon lift so ground line is not a black slab.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.82),
        width: size.width * 0.75,
        height: size.height * 0.16,
      ),
      Paint()
        ..color = const Color(0xFFC87898).withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    _paintGroundStrip(
      canvas,
      size,
      soil: const Color(0xFF3A2410),
      green: Colors.transparent,
      greenHeight: 0,
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

  /// Soft aurora so stage 5 art stays the focal color source.
  void _paintAuroraSoft(Canvas canvas, Size size) {
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
        ..color = const Color(0xFF3AAFA9).withValues(alpha: 0.14)
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
      Paint()..color = const Color(0xFF7A4EB0).withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _CherryBlossomBackgroundPainter oldDelegate) =>
      oldDelegate.stageIndex != stageIndex || oldDelegate.compact != compact;
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
