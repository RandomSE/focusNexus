import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_engine.dart';

/// Night sky, warm fireflies, mason jar, and catch FX.
class FireflyJarPainter extends CustomPainter {
  FireflyJarPainter({
    required this.engine,
  });

  final FireflyJarEngine engine;

  static const Color skyEdge = Color(0xFF050810);
  static const Color skyMid = Color(0xFF0A1020);
  static const Color skyCenter = Color(0xFF0D1428);
  static const Color outerGlow = Color(0xFFFFE566);
  static const Color midGlow = Color(0xFFFFD700);
  static const Color coreGlow = Color(0xFFFFFACD);
  static const Color jarInterior = Color(0xFF0A1A0A);
  static const Color jarGlass = Color(0xFFB8D0DC);

  /// Scaffold / safe fallback matching the darkest sky edge.
  static const Color sky = skyEdge;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintStars(canvas, size);
    _paintJar(canvas, size);

    for (final fly in engine.activeFireflies) {
      _paintFirefly(
        canvas,
        Offset(fly.x, fly.y),
        FireflyJarConstants.coreRadius,
        fly.pulseScale,
      );
    }

    for (final fx in engine.catchEffects) {
      _paintCatchFx(canvas, fx);
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.42, size.height * 0.45);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: const [skyCenter, skyMid, skyEdge],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.longestSide * 0.85),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintStars(Canvas canvas, Size size) {
    for (final star in engine.stars) {
      canvas.drawCircle(
        Offset(star.nx * size.width, star.ny * size.height),
        star.radius,
        Paint()..color = Colors.white.withValues(alpha: star.opacity),
      );
    }
  }

  void _paintFirefly(
    Canvas canvas,
    Offset center,
    double coreRadius,
    double pulseScale,
  ) {
    final outerR = coreRadius * 3.0 * pulseScale;
    final midR = coreRadius * 1.8 * pulseScale;
    final coreR = coreRadius * pulseScale;

    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = outerGlow.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      midR,
      Paint()
        ..color = midGlow.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center,
      coreR,
      Paint()..color = coreGlow,
    );
  }

  void _paintCatchFx(Canvas canvas, CatchFx fx) {
    if (fx.showBurst) {
      final opacity = fx.burstOpacity;
      final stroke = Paint()
        ..color = outerGlow.withValues(alpha: opacity)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (final ray in fx.rays) {
        final end = fx.origin +
            Offset(math.cos(ray.angle), math.sin(ray.angle)) * ray.length;
        canvas.drawLine(fx.origin, end, stroke);
      }
    }

    final scale = fx.travelGlowScale;
    if (scale > 0.02) {
      _paintFirefly(
        canvas,
        fx.streakPos,
        FireflyJarConstants.coreRadius,
        scale,
      );
    }
  }

  void _paintJar(Canvas canvas, Size size) {
    final body = engine.jarBodyRect;
    final boost = engine.jarBoostStrength;
    final cx = body.center.dx;
    final neckW = body.width * 0.42;
    final neckH = body.height * 0.12;
    final neckTop = body.top - neckH * 0.55;
    final neck = Rect.fromCenter(
      center: Offset(cx, neckTop + neckH / 2),
      width: neckW,
      height: neckH,
    );
    final lid = Rect.fromCenter(
      center: Offset(cx, neck.top - 4),
      width: neckW * 1.15,
      height: 10,
    );

    final jarPath = Path()
      ..moveTo(body.left + body.width * 0.12, body.top + 8)
      ..quadraticBezierTo(body.left, body.top + body.height * 0.35, body.left, body.bottom - 18)
      ..quadraticBezierTo(body.left, body.bottom, cx, body.bottom)
      ..quadraticBezierTo(body.right, body.bottom, body.right, body.bottom - 18)
      ..quadraticBezierTo(
        body.right,
        body.top + body.height * 0.35,
        body.right - body.width * 0.12,
        body.top + 8,
      )
      ..close();

    // Dark empty interior.
    canvas.drawPath(jarPath, Paint()..color = jarInterior.withValues(alpha: 0.92));
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, const Radius.circular(6)),
      Paint()..color = jarInterior.withValues(alpha: 0.85),
    );

    final fill = engine.jarFillFraction;
    if (fill > 0.01) {
      final massTop =
          body.top + body.height * FireflyJarConstants.jarMassTopNy(fill);
      final glowCenter = Offset(cx, (massTop + body.bottom) / 2);
      final glowRadius = body.width * (0.55 + 0.2 * fill) * (1 + 0.15 * boost);

      canvas.save();
      canvas.clipPath(jarPath);
      canvas.drawCircle(
        glowCenter,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              outerGlow.withValues(alpha: 0.55 + 0.25 * boost),
              outerGlow.withValues(alpha: 0.22),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
      );

      // Soft meniscus curve at top of firefly mass.
      final meniscus = Path()
        ..moveTo(body.left + 6, massTop + 10)
        ..quadraticBezierTo(cx, massTop - 8, body.right - 6, massTop + 10)
        ..lineTo(body.right - 6, body.bottom)
        ..lineTo(body.left + 6, body.bottom)
        ..close();
      canvas.drawPath(
        meniscus,
        Paint()..color = outerGlow.withValues(alpha: 0.12 + 0.1 * boost),
      );

      for (final jarFly in engine.jarFireflies) {
        final pos = Offset(
          body.left + jarFly.nx * body.width,
          body.top + jarFly.ny * body.height,
        );
        final blink = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(jarFly.phase));
        canvas.drawCircle(
          pos,
          jarFly.radius * 2.2,
          Paint()
            ..color = outerGlow.withValues(alpha: 0.18 * blink)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          pos,
          jarFly.radius,
          Paint()..color = coreGlow.withValues(alpha: 0.85 * blink),
        );
      }
      canvas.restore();

      // Faint outer reflection of internal glow.
      canvas.drawPath(
        jarPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = outerGlow.withValues(alpha: 0.06 + 0.08 * boost)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Glass rim + cylindrical depth.
    final glassStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = jarGlass.withValues(alpha: 0.7);
    canvas.drawPath(jarPath, glassStroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, const Radius.circular(6)),
      glassStroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(5)),
      glassStroke,
    );
    canvas.drawLine(
      Offset(lid.left + 4, lid.center.dy),
      Offset(lid.right - 4, lid.center.dy),
      Paint()
        ..color = jarGlass.withValues(alpha: 0.45)
        ..strokeWidth = 1,
    );

    // Left highlight / right shadow for cylindrical depth.
    final highlight = Path()
      ..moveTo(body.left + body.width * 0.18, body.top + 14)
      ..quadraticBezierTo(
        body.left + 4,
        body.center.dy,
        body.left + body.width * 0.2,
        body.bottom - 22,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color.fromRGBO(255, 255, 255, 0.4)
        ..strokeCap = StrokeCap.round,
    );
    final shadow = Path()
      ..moveTo(body.right - body.width * 0.16, body.top + 16)
      ..quadraticBezierTo(
        body.right - 2,
        body.center.dy,
        body.right - body.width * 0.18,
        body.bottom - 24,
      );
    canvas.drawPath(
      shadow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = const Color.fromRGBO(0, 0, 0, 0.3)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant FireflyJarPainter oldDelegate) => true;
}
