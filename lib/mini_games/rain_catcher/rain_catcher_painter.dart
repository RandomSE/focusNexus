import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_engine.dart';

/// Soft storm sky, streak rain, lily pad, catch/miss FX, and glass water gauge.
class RainCatcherPainter extends CustomPainter {
  RainCatcherPainter({required this.engine});

  final RainCatcherEngine engine;

  static const Color dropBody = RainCatcherConstants.dropColor;
  static const Color dropHighlight = RainCatcherConstants.dropHighlight;
  static const Color skyBottom = Color(0xFF0A1828);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintClouds(canvas, size);
    _paintLightning(canvas, size);
    _paintBackgroundRain(canvas);
    _paintPuddle(canvas, size);
    _paintDrops(canvas);
    _paintSplashes(canvas, size);
    _paintCatchParticles(canvas);
    _paintRipples(canvas);
    _paintPad(canvas);
    _paintGauge(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Vertical overcast + subtle horizontal lighting variation.
    final vertical = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0E1E32), Color(0xFF0A1828)],
        stops: [0.0, 0.3],
      ).createShader(rect);
    canvas.drawRect(rect, vertical);

    final horizontal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF0A1828), Color(0xFF0D1E30), Color(0xFF0A1828)],
      ).createShader(rect)
      ..blendMode = BlendMode.softLight;
    canvas.drawRect(rect, horizontal);

    if (engine.lightningFlash > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = Color.fromRGBO(
            200,
            220,
            255,
            0.08 * engine.lightningFlash,
          ),
      );
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x261E3250);
    for (final cloud in engine.clouds) {
      final cx = cloud.nx * size.width;
      final cy = cloud.ny * size.height;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: cloud.radiusX * size.width * 2,
          height: cloud.radiusY * size.height * 2,
        ),
        paint,
      );
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    if (engine.lightningBolt.length < 2) return;
    final paint = Paint()
      ..color = const Color(0x59C8DCFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(engine.lightningBolt.first.dx, engine.lightningBolt.first.dy);
    for (var i = 1; i < engine.lightningBolt.length; i++) {
      path.lineTo(engine.lightningBolt[i].dx, engine.lightningBolt[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintBackgroundRain(Canvas canvas) {
    final paint = Paint()
      ..color = RainCatcherConstants.backgroundRainColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final lean = RainCatcherConstants.backgroundRainLeanRadians;
    final dx = math.sin(lean);
    final dy = math.cos(lean);
    for (final streak in engine.backgroundRain) {
      canvas.drawLine(
        Offset(streak.x, streak.y),
        Offset(
          streak.x + dx * streak.length,
          streak.y + dy * streak.length,
        ),
        paint,
      );
    }
  }

  void _paintPuddle(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 8, size.width, 8),
      Paint()..color = const Color(0x1F64A0C8),
    );
  }

  void _paintDrops(Canvas canvas) {
    for (final drop in engine.drops) {
      _paintTeardrop(canvas, drop);
    }
  }

  void _paintTeardrop(Canvas canvas, Raindrop drop) {
    final w = drop.width;
    final h = drop.height;
    // Motion trails: 3 ghosts behind at 40%/20%/8% opacity, 30%/60%/90% height.
    const trailOps = [0.40, 0.20, 0.08];
    const trailHeights = [0.30, 0.60, 0.90];
    for (var i = 0; i < 3; i++) {
      final trailH = h * trailHeights[i];
      final trailY = drop.y - h * (0.35 + i * 0.28);
      _drawDropShape(
        canvas,
        Offset(drop.x, trailY),
        w * (0.7 + i * 0.05),
        trailH,
        dropBody.withValues(alpha: trailOps[i]),
        withHighlight: false,
      );
    }
    _drawDropShape(
      canvas,
      Offset(drop.x, drop.y),
      w,
      h,
      dropBody,
      withHighlight: true,
    );
  }

  void _drawDropShape(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Color color, {
    required bool withHighlight,
  }) {
    final top = center.dy - height / 2;
    final path = Path()
      ..moveTo(center.dx, top + height)
      ..quadraticBezierTo(
        center.dx + width / 2,
        top + height * 0.45,
        center.dx + width / 2,
        top + height * 0.28,
      )
      ..quadraticBezierTo(
        center.dx + width * 0.35,
        top,
        center.dx,
        top,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.35,
        top,
        center.dx - width / 2,
        top + height * 0.28,
      )
      ..quadraticBezierTo(
        center.dx - width / 2,
        top + height * 0.45,
        center.dx,
        top + height,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    if (withHighlight) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, top + height * 0.22),
          width: width * 0.55,
          height: height * 0.22,
        ),
        Paint()..color = dropHighlight,
      );
    }
  }

  void _paintSplashes(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    for (final splash in engine.splashes) {
      final t = splash.progress;
      final width = 4 + t * 16;
      paint
        ..strokeWidth = 1.5
        ..color = Color.fromRGBO(100, 160, 200, 0.4 * (1 - t));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(splash.origin.dx, size.height - 4),
          width: width,
          height: 4 + t * 4,
        ),
        paint,
      );
    }
  }

  void _paintCatchParticles(Canvas canvas) {
    final paint = Paint()..color = dropBody;
    for (final p in engine.catchParticles) {
      paint.color = dropBody.withValues(alpha: 1 - p.progress);
      canvas.drawCircle(Offset(p.x, p.y), 2, paint);
    }
  }

  void _paintRipples(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final ripple in engine.ripples) {
      final t = ripple.progress;
      paint.color = Colors.white.withValues(alpha: (1 - t) * 0.85);
      canvas.drawCircle(ripple.origin, 6 + t * 22, paint);
    }
  }

  void _paintPad(Canvas canvas) {
    final cx = engine.padCenterX;
    final cy = engine.padCenterY;
    final r = (engine.padRight - engine.padLeft) / 2;
    final halfNotch = RainCatcherConstants.padNotchHalfRadians;
    final tip = Offset(
      cx + r * RainCatcherConstants.padNotchTipInsetFraction,
      cy,
    );

    // Narrow V-notch (~32 deg) on the right - a small slice, not Pac-Man.
    final lily = Path()..moveTo(tip.dx, tip.dy);
    for (var a = halfNotch; a <= math.pi * 2 - halfNotch; a += 0.06) {
      lily.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
    }
    lily.close();

    canvas.drawPath(lily, Paint()..color = const Color(0xFF4A8A3A));

    canvas.save();
    canvas.clipPath(lily);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - r * 0.25),
        width: r * 1.6,
        height: r * 0.9,
      ),
      Paint()..color = const Color(0xFF5AAA48).withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.35),
        width: r * 1.7,
        height: r * 0.85,
      ),
      Paint()..color = const Color(0xFF2A5A22).withValues(alpha: 0.45),
    );

    final veinPaint = Paint()
      ..color = const Color(0x803A7A2A)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final veinSpan = math.pi * 2 - halfNotch * 2;
    for (var i = 0; i < 5; i++) {
      final angle = halfNotch + (i / 4) * veinSpan;
      final end = Offset(
        cx + r * 0.92 * math.cos(angle),
        cy + r * 0.92 * math.sin(angle),
      );
      final mid = Offset(
        cx + r * 0.5 * math.cos(angle + 0.08),
        cy + r * 0.5 * math.sin(angle + 0.08),
      );
      final vein = Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
      canvas.drawPath(vein, veinPaint);
    }
    canvas.restore();

    // Small white cluster at the notch tip (3-4px petals + yellow center).
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * (math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            tip.dx + math.cos(a) * 2.6,
            tip.dy + math.sin(a) * 2.6,
          ),
          width: 3.5,
          height: 2.4,
        ),
        Paint()..color = const Color(0xFFFFFAEE),
      );
    }
    canvas.drawCircle(tip, 1.4, Paint()..color = const Color(0xFFFFE566));
  }

  void _paintGauge(Canvas canvas, Size size) {
    final top = RainCatcherConstants.gaugeVerticalInset;
    final bottom = size.height - RainCatcherConstants.gaugeVerticalInset;
    final trackHeight = (bottom - top).clamp(0.0, double.infinity);
    if (trackHeight <= 0) return;
    final left =
        size.width -
        RainCatcherConstants.gaugeInset -
        RainCatcherConstants.gaugeBarWidth;
    final width = RainCatcherConstants.gaugeBarWidth;
    final track = RRect.fromLTRBR(
      left,
      top,
      left + width,
      top + trackHeight,
      const Radius.circular(8),
    );

    // Glass outline.
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x40FFFFFF),
    );
    // Inner left highlight.
    canvas.drawLine(
      Offset(left + 3, top + 6),
      Offset(left + 3, top + trackHeight - 6),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0x26FFFFFF),
    );

    final gaugeMax = RainCatcherConstants.gaugeMaxFor(endless: engine.endless);
    final marks = RainCatcherConstants.gaugeMarkValuesFor(
      endless: engine.endless,
    );
    final fraction = (engine.gauge / gaugeMax).clamp(0.0, 1.0);
    final fillHeight = trackHeight * fraction;
    final fillTop = top + trackHeight - fillHeight;
    final fillColor = RainCatcherConstants.gaugeFillColor(
      engine.gauge,
      endless: engine.endless,
    );

    canvas.save();
    canvas.clipRRect(track);
    final fillRect = Rect.fromLTRB(left, fillTop, left + width, top + trackHeight);
    canvas.drawRect(fillRect, Paint()..color = fillColor);

    // Gentle wave at fill surface.
    if (fillHeight > 2) {
      final wave = Path()..moveTo(left, fillTop);
      final period = RainCatcherConstants.gaugeWavePeriodSeconds;
      final phase =
          (engine.elapsedSeconds / period) * math.pi * 2;
      const steps = 8;
      for (var i = 0; i <= steps; i++) {
        final nx = i / steps;
        final x = left + width * nx;
        final y =
            fillTop +
            math.sin(phase + nx * math.pi * 2) *
                RainCatcherConstants.gaugeWaveAmplitude *
                (fraction.clamp(0.15, 1.0));
        wave.lineTo(x, y);
      }
      wave
        ..lineTo(left + width, top + trackHeight)
        ..lineTo(left, top + trackHeight)
        ..close();
      canvas.drawPath(
        wave,
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
    }

    if (engine.gaugeFlash > 0) {
      canvas.drawRect(
        fillRect,
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.15 * engine.gaugeFlash),
      );
    }
    canvas.restore();

    // Tier marks + labels.
    final markPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x66FFFFFF);
    for (var i = 0; i < marks.length; i++) {
      final mark = marks[i];
      final markFraction = mark / gaugeMax;
      final y = top + trackHeight * (1 - markFraction);
      final tierColor = RainCatcherConstants.gaugeTierColors[
          ((i / marks.length) * (RainCatcherConstants.gaugeTierColors.length - 1))
              .floor()
              .clamp(0, RainCatcherConstants.gaugeTierColors.length - 1)];
      canvas.drawLine(Offset(left - 2, y), Offset(left + width + 2, y), markPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '$mark',
          style: TextStyle(
            color: tierColor.withValues(alpha: 0.95),
            fontSize: marks.length > 6 ? 8 : 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - 6 - tp.width, y - tp.height / 2));
    }

    // Droplet icon above the gauge.
    final iconCenter = Offset(left + width / 2, top - 14);
    _drawDropShape(
      canvas,
      iconCenter,
      5,
      10,
      const Color(0xFFA8D8F0),
      withHighlight: true,
    );
  }

  @override
  bool shouldRepaint(covariant RainCatcherPainter oldDelegate) => true;
}
