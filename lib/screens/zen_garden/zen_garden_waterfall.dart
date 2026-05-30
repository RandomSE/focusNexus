import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'zen_garden_cartoon_style.dart';

/// Animated waterfall — mossy cliff, flowing sheet, pool ripples, soft mist.
class ZenGardenWaterfallLayer extends StatefulWidget {
  const ZenGardenWaterfallLayer({
    super.key,
    required this.size,
    this.reduceMotion = false,
  });

  final Size size;
  final bool reduceMotion;

  @override
  State<ZenGardenWaterfallLayer> createState() => _ZenGardenWaterfallLayerState();
}

class _ZenGardenWaterfallLayerState extends State<ZenGardenWaterfallLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;
  late final Stopwatch _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = Stopwatch();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    );
    if (!widget.reduceMotion) {
      _elapsed.start();
      _flow.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ZenGardenWaterfallLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _flow.stop();
      _elapsed.stop();
    } else {
      if (!_elapsed.isRunning) _elapsed.start();
      if (!_flow.isAnimating) _flow.repeat();
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _flow,
        builder: (context, _) {
          final seconds = widget.reduceMotion
              ? 1.2
              : _elapsed.elapsedMilliseconds / 1000.0;
          return CustomPaint(
            size: widget.size,
            painter: ZenGardenWaterfallPainter(elapsedSeconds: seconds),
          );
        },
      ),
    );
  }
}

class ZenGardenWaterfallPainter extends CustomPainter {
  ZenGardenWaterfallPainter({required this.elapsedSeconds});

  final double elapsedSeconds;

  static const _cliffHi = Color(0xFF9AA890);
  static const _cliffMid = Color(0xFF728068);
  static const _cliffLo = Color(0xFF4F5848);
  static const _waterLite = Color(0xFFCAF0F8);
  static const _waterMid = Color(0xFF48CAE4);
  static const _waterDeep = Color(0xFF0096C7);
  static const _foam = Color(0xFFF0FBFF);
  static const _stoneHi = Color(0xFFE8E2D8);
  static const _stoneMid = Color(0xFFB8AFA4);
  static const _stoneLo = Color(0xFF7A7268);
  @override
  void paint(Canvas canvas, Size size) {
    final cliffTop = size.height * 0.02;
    final cliffBottom = size.height * 0.42;
    final cliffLeft = size.width * 0.72;
    final cliffRight = size.width * 0.99;
    final fallTop = size.height * 0.08;
    final fallBottom = size.height * 0.52;
    final fallCx = size.width * 0.86;

    _drawCliff(canvas, size, cliffTop, cliffBottom, cliffLeft, cliffRight);
    _drawWaterSheet(canvas, fallCx, fallTop, fallBottom, size.width * 0.09);
    _drawFlowStreaks(canvas, fallCx, fallTop, fallBottom, size.width * 0.085);
    final poolCenter = Offset(fallCx, fallBottom + size.height * 0.035);
    _drawAqueductChannel(canvas, fallCx, fallBottom, poolCenter, size);
    _drawPool(canvas, poolCenter, size, fallCx: fallCx);
    _drawMist(canvas, fallCx, fallBottom, size);
  }

  void _drawCliff(
    Canvas canvas,
    Size size,
    double top,
    double bottom,
    double left,
    double right,
  ) {
    final w = size.width;
    final h = size.height;
    final span = bottom - top;
    final bump = w * 0.028;

    // Irregular left-facing profile: 3 subtle convex bulges toward the garden.
    final cliff = Path()
      ..moveTo(right, top)
      ..lineTo(right, bottom)
      ..quadraticBezierTo(
        right - w * 0.02,
        bottom + h * 0.012,
        left + w * 0.05,
        bottom + h * 0.004,
      )
      ..cubicTo(
        left + w * 0.03 - bump * 0.4,
        bottom - span * 0.18,
        left + w * 0.012 - bump,
        bottom - span * 0.34,
        left + w * 0.028 - bump * 0.85,
        bottom - span * 0.48,
      )
      ..cubicTo(
        left - bump * 0.35,
        bottom - span * 0.58,
        left + w * 0.018 - bump * 0.55,
        bottom - span * 0.72,
        left + w * 0.038 - bump * 0.45,
        bottom - span * 0.84,
      )
      ..cubicTo(
        left + w * 0.025,
        top + span * 0.14 - bump * 0.25,
        left + w * 0.048,
        top + span * 0.05,
        left + w * 0.06,
        top,
      )
      ..close();
    final bounds = cliff.getBounds();
    canvas.drawPath(
      cliff,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [_cliffHi, _cliffMid, _cliffLo],
          [0, 0.55, 1],
        ),
    );
    canvas.drawPath(cliff, ZenCartoonStyle.outline(2.8));
  }

  void _drawWaterSheet(
    Canvas canvas,
    double cx,
    double top,
    double bottom,
    double width,
  ) {
    final sheet = Path()
      ..moveTo(cx - width * 0.35, top)
      ..quadraticBezierTo(cx - width * 0.15, (top + bottom) / 2, cx - width * 0.45, bottom)
      ..lineTo(cx + width * 0.45, bottom)
      ..quadraticBezierTo(cx + width * 0.2, (top + bottom) / 2, cx + width * 0.3, top)
      ..close();
    canvas.drawPath(
      sheet,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_waterLite, _waterMid, _waterDeep],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(sheet.getBounds()),
    );
    canvas.drawPath(sheet, ZenCartoonStyle.outline(2.2));
    ZenCartoonStyle.highlightSpot(canvas, Offset(cx - width * 0.1, top + 12), 6);
  }

  void _drawFlowStreaks(
    Canvas canvas,
    double cx,
    double top,
    double bottom,
    double width,
  ) {
    final span = bottom - top;
    const streakCount = 9;
    final scroll = elapsedSeconds * 22.0;
    for (var i = 0; i < streakCount; i++) {
      final t = i / (streakCount - 1);
      final x = cx + (t - 0.5) * width * 0.85;
      final drift = math.sin(elapsedSeconds * 1.6 + t * 4.2) * 2.5;
      final segmentLen = span * 0.18;
      for (var s = -2; s <= 4; s++) {
        final y0 = top + ((scroll + s * segmentLen + i * 7.3) % (span + segmentLen)) - segmentLen * 0.35;
        if (y0 > bottom + 4) continue;
        final y1 = (y0 + segmentLen * 0.72).clamp(top, bottom);
        if (y0 < top - 8) continue;
        canvas.drawLine(
          Offset(x + drift, y0),
          Offset(x + drift * 0.6, y1),
          Paint()
            ..color = _foam.withValues(alpha: 0.35 + t * 0.1)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    final foamY = bottom - 4;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, foamY), width: width * 1.1, height: 10),
      Paint()
        ..color = _foam.withValues(alpha: 0.45 + math.sin(elapsedSeconds * 2.4) * 0.08),
    );
  }

  void _drawAqueductChannel(
    Canvas canvas,
    double cx,
    double fallBottom,
    Offset poolCenter,
    Size size,
  ) {
    final topW = size.width * 0.10;
    final botW = size.width * 0.18;
    final channel = Path()
      ..moveTo(cx - topW * 0.45, fallBottom)
      ..lineTo(cx + topW * 0.45, fallBottom)
      ..lineTo(poolCenter.dx + botW * 0.5, poolCenter.dy - size.height * 0.02)
      ..lineTo(poolCenter.dx - botW * 0.5, poolCenter.dy - size.height * 0.02)
      ..close();
    canvas.drawPath(channel, Paint()..color = _waterMid.withValues(alpha: 0.28));
    canvas.drawPath(
      channel,
      Paint()
        ..color = _waterDeep.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawLine(
      Offset(cx - topW * 0.15, fallBottom + 2),
      Offset(poolCenter.dx - botW * 0.15, poolCenter.dy - size.height * 0.018),
      Paint()
        ..color = _waterMid.withValues(alpha: 0.45)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawPool(Canvas canvas, Offset center, Size size, {required double fallCx}) {
    final pondW = size.width * 0.26;
    final pondH = size.height * 0.075;
    final pond = Path()
      ..moveTo(center.dx - pondW * 0.5, center.dy + pondH * 0.15)
      ..quadraticBezierTo(
        center.dx - pondW * 0.42,
        center.dy - pondH * 0.55,
        center.dx - pondW * 0.08,
        center.dy - pondH * 0.42,
      )
      ..quadraticBezierTo(
        center.dx + pondW * 0.12,
        center.dy - pondH * 0.52,
        center.dx + pondW * 0.38,
        center.dy - pondH * 0.28,
      )
      ..quadraticBezierTo(
        center.dx + pondW * 0.52,
        center.dy + pondH * 0.05,
        center.dx + pondW * 0.44,
        center.dy + pondH * 0.38,
      )
      ..quadraticBezierTo(
        center.dx + pondW * 0.05,
        center.dy + pondH * 0.55,
        center.dx - pondW * 0.5,
        center.dy + pondH * 0.15,
      )
      ..close();

    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(
      pond,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();

    canvas.drawPath(
      pond,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _waterLite,
            _waterMid.withValues(alpha: 0.92),
            _waterDeep.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(pond.getBounds()),
    );

    canvas.drawPath(
      pond,
      Paint()
        ..color = const Color(0x40002850)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(pond, ZenCartoonStyle.outline(2.4));

    final impact = Offset(fallCx, center.dy - pondH * 0.38);
    const rippleDuration = 1.2;
    final ripplePhase = (elapsedSeconds % rippleDuration) / rippleDuration;
    final rippleW = 8.0 + ripplePhase * (35.0 - 8.0);
    final rippleH = rippleW * 0.42;
    canvas.drawOval(
      Rect.fromCenter(center: impact, width: rippleW, height: rippleH),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * (1 - ripplePhase))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    const poolRocks = [
      (-0.42, 0.18, 24.0, -0.3, 0),
      (-0.28, 0.08, 18.0, 0.45, 1),
      (-0.08, 0.28, 20.0, 0.15, 2),
      (0.18, 0.14, 26.0, -0.5, 3),
      (0.34, 0.06, 16.0, 0.65, 4),
      (0.44, 0.22, 22.0, 0.25, 5),
      (-0.35, 0.32, 17.0, -0.15, 6),
    ];
    for (final (nx, ny, px, rot, seed) in poolRocks) {
      _drawOrganicPoolRock(
        canvas,
        Offset(center.dx + pondW * nx, center.dy + pondH * ny),
        px,
        rot,
        seed: seed,
      );
    }
  }

  void _drawOrganicPoolRock(
    Canvas canvas,
    Offset c,
    double sizePx,
    double rot, {
    required int seed,
  }) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final wobble = 0.85 + _rockHash(seed) * 0.3;
    final rw = sizePx * wobble;
    final rh = sizePx * (0.52 + _rockHash(seed + 3) * 0.28);
    final rock = Path()
      ..moveTo(-rw * 0.45, rh * 0.08)
      ..cubicTo(-rw * 0.62, -rh * 0.42, -rw * 0.08, -rh * 0.55, rw * 0.22, -rh * 0.38)
      ..cubicTo(rw * 0.58, -rh * 0.22, rw * 0.52, rh * 0.35, rw * 0.18, rh * 0.42)
      ..cubicTo(-rw * 0.12, rh * 0.52, -rw * 0.55, rh * 0.38, -rw * 0.45, rh * 0.08)
      ..close();
    final bounds = rock.getBounds();
    canvas.drawPath(
      rock,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [_stoneHi, _stoneMid, _stoneLo],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.drawPath(rock, ZenCartoonStyle.outline(1.4));
    canvas.restore();
  }

  double _rockHash(int seed) {
    var h = seed * 374761393 + 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h & 0xFFFFFF) / 0x1000000;
  }

  void _drawMist(Canvas canvas, double cx, double fallBottom, Size size) {
    for (var i = 0; i < 8; i++) {
      final cycle = (elapsedSeconds * 0.14 + i * 0.11) % 1.0;
      final x = cx + math.sin(i * 1.7 + elapsedSeconds * 1.1) * size.width * 0.04;
      final y = fallBottom + cycle * size.height * 0.06;
      final radius = 6 + i * 1.5;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = _foam.withValues(alpha: (1 - cycle) * 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ZenGardenWaterfallPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds;
  }
}
