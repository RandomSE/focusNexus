import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_engine.dart';

class BreathPacerPainter extends CustomPainter {
  BreathPacerPainter({required this.engine});

  final BreathPacerEngine engine;

  static const Color skyTop = Color(0xFF10192A);
  static const Color skyBottom = Color(0xFF1B2A3D);

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);

    final center = size.center(Offset.zero);
    final radius = engine.circleRadiusPx;
    final now = engine.elapsedSeconds;

    _paintIncomingTransitionCue(canvas, center, radius);
    _paintOuterRing(canvas, center, radius, now);
    _paintInnerRing(canvas, center, radius, now);
    _paintCircle(canvas, center, radius);
    _paintRipples(canvas, center, radius, now);
    _paintFloatingCues(canvas, center, radius, now);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    Color top = skyTop;
    Color bottom = skyBottom;

    if (engine.endless) {
      final day = engine.endlessDayCycle;
      if (day < 0.35) {
        final t = day / 0.35;
        top = Color.lerp(const Color(0xFF0A1020), const Color(0xFF2A3A5A), t)!;
        bottom =
            Color.lerp(const Color(0xFF121A2C), const Color(0xFF5A4A3A), t)!;
      } else if (day < 0.55) {
        final t = (day - 0.35) / 0.20;
        top = Color.lerp(const Color(0xFF2A3A5A), const Color(0xFF7EB6D9), t)!;
        bottom =
            Color.lerp(const Color(0xFF5A4A3A), const Color(0xFFC8D8E8), t)!;
      } else if (day < 0.80) {
        final t = (day - 0.55) / 0.25;
        top = Color.lerp(const Color(0xFF7EB6D9), const Color(0xFF3A2A4A), t)!;
        bottom =
            Color.lerp(const Color(0xFFC8D8E8), const Color(0xFF6A3A4A), t)!;
      } else {
        final t = (day - 0.80) / 0.20;
        top = Color.lerp(const Color(0xFF3A2A4A), const Color(0xFF0D0818), t)!;
        bottom =
            Color.lerp(const Color(0xFF6A3A4A), const Color(0xFF1A0A20), t)!;
      }
    }

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    if (!engine.endless && engine.dawnStrength > 0) {
      final alpha = 0.04 + 0.08 * engine.dawnStrength;
      final dawn = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(255, 180, 100, alpha),
            Colors.transparent,
          ],
        ).createShader(rect);
      canvas.drawRect(rect, dawn);
    }
  }

  void _paintCircle(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..color = const Color.fromRGBO(100, 200, 220, 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius + 7.5, glowPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          engine.circleCenterColor().withValues(alpha: engine.circleOpacity),
          engine.circleEdgeColor().withValues(alpha: engine.circleOpacity),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, fill);
  }

  void _paintOuterRing(
    Canvas canvas,
    Offset center,
    double radius,
    double now,
  ) {
    final ringR = radius * 1.55;
    final flash = engine.particlesFlashing;
    final markerAngle = engine.outerMarkerAngle;

    for (final p in engine.outerParticles) {
      final point = Offset(
        center.dx + math.cos(p.angle) * ringR,
        center.dy + math.sin(p.angle) * ringR,
      );
      final opacity = flash ? 1.0 : 0.55 + p.seed * 0.25;
      canvas.drawCircle(
        point,
        p.size,
        Paint()..color = const Color(0xFFB8A4E8).withValues(alpha: opacity),
      );
    }

    final marker = Offset(
      center.dx + math.cos(markerAngle) * ringR,
      center.dy + math.sin(markerAngle) * ringR,
    );
    canvas.drawCircle(
      marker,
      6,
      Paint()
        ..color = const Color(0xFFB8A4E8).withValues(alpha: flash ? 1.0 : 1.0),
    );
    for (var i = 1; i <= 4; i++) {
      final trailAngle = markerAngle - i * 0.08;
      final trail = Offset(
        center.dx + math.cos(trailAngle) * ringR,
        center.dy + math.sin(trailAngle) * ringR,
      );
      canvas.drawCircle(
        trail,
        (6 - i).clamp(1.5, 5).toDouble(),
        Paint()..color = const Color(0xFFB8A4E8).withValues(alpha: 0.35 / i),
      );
    }
  }

  void _paintInnerRing(
    Canvas canvas,
    Offset center,
    double radius,
    double now,
  ) {
    final ringR = radius * 1.18;
    final flash = engine.particlesFlashing;
    final waveBoost = engine.transitionWaves.isEmpty
        ? 0.0
        : (1.0 -
                (engine.transitionWaves.last.age(now) /
                    TransitionWaveFx.life))
            .clamp(0.0, 1.0);

    for (final p in engine.innerParticles) {
      final ang = engine.innerAngle(p) + now * 0.08 * engine.orbitSpeedScale;
      final point = Offset(
        center.dx + math.cos(ang) * ringR,
        center.dy + math.sin(ang) * ringR,
      );
      final size = p.size * (1 + waveBoost * 0.5);
      final paint = Paint()
        ..color = const Color(0xFF64C8C8)
            .withValues(alpha: flash ? 1.0 : 0.55 + p.seed * 0.3);
      canvas.drawCircle(point, size, paint);
    }
  }

  void _paintIncomingTransitionCue(
    Canvas canvas,
    Offset center,
    double radius,
  ) {
    final progress = engine.incomingTransitionCueProgress;
    if (progress == null) return;
    final cueRadius = radius * (2.0 - progress * 0.95);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 + progress * 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, cueRadius, paint);
  }

  void _paintRipples(Canvas canvas, Offset center, double radius, double now) {
    for (final ripple in engine.ripples) {
      final t = (ripple.age(now) / RippleFx.life).clamp(0.0, 1.0);
      final peak = ripple.grade == TapGrade.perfect ? 1.4 : 1.2;
      final r = radius * (1 + (peak - 1) * t);
      final color = ripple.grade == TapGrade.perfect
          ? Color.fromRGBO(100, 255, 200, (1 - t) * 0.6)
          : Color.fromRGBO(100, 200, 255, (1 - t) * 0.4);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _paintFloatingCues(
    Canvas canvas,
    Offset center,
    double radius,
    double now,
  ) {
    for (final cue in engine.floatingCues) {
      final t = (cue.age(now) / FloatingCueFx.life).clamp(0.0, 1.0);
      final color = cue.label == 'Perfect'
          ? const Color(0xFF64FFC8)
          : const Color(0xFF64C8FF);
      final tp = TextPainter(
        text: TextSpan(
          text: cue.label,
          style: TextStyle(
            color: color.withValues(alpha: 1 - t),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - radius - 28 - t * 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BreathPacerPainter oldDelegate) => true;
}
