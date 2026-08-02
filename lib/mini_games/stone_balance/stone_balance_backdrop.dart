import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_engine.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_stone_paint.dart';

/// Phased zen-to-void backdrop driven by [StoneBalanceEngine.backgroundPhase].
class StoneBalanceBackdrop {
  StoneBalanceBackdrop({required this.engine, required this.elapsed});

  final StoneBalanceEngine engine;
  final double elapsed;

  void paint(Canvas canvas, Size size) {
    final phase = engine.backgroundPhase;
    final floor = phase.floor().clamp(1, 5);
    final ceil = phase.ceil().clamp(1, 5);
    final t = (phase - floor).clamp(0.0, 1.0);

    _paintPhase(canvas, size, floor, 1 - t);
    if (ceil != floor) {
      _paintPhase(canvas, size, ceil, t);
    }
  }

  void _paintPhase(Canvas canvas, Size size, int phase, double opacity) {
    if (opacity <= 0.01) return;
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    switch (phase) {
      case 1:
        _phaseGarden(canvas, size);
      case 2:
        _phaseRising(canvas, size);
      case 3:
        _phaseAfternoon(canvas, size);
      case 4:
        _phaseStrato(canvas, size);
      default:
        _phaseVoid(canvas, size);
    }
    canvas.restore();
  }

  void _phaseGarden(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB8D4E8), Color(0xFFD8E8F4)],
        ).createShader(Offset.zero & size),
    );
    _paintGroundBand(canvas, size);
  }

  void _phaseRising(Canvas canvas, Size size) {
    // Simple earthy garden gradient (light green into light brown).
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC8D9B8),
            Color(0xFFB5C9A0),
            Color(0xFFC4A882),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
    if (engine.showGround) {
      // Same grass line as phase 1 so the platform does not jump.
      _paintGroundBand(canvas, size);
    }
  }

  void _paintGroundBand(Canvas canvas, Size size) {
    final sandTop =
        size.height * StoneBalanceConstants.grassLineFraction;
    canvas.drawRect(
      Rect.fromLTRB(0, sandTop, size.width, size.height),
      Paint()..color = const Color(0xFFC4A882),
    );
    final rake = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color.fromRGBO(140, 110, 80, 0.12);
    final c = Offset(size.width * 0.5, size.height * 0.97);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(c, i * 28.0, rake);
    }
    canvas.drawLine(
      Offset(0, sandTop),
      Offset(size.width, sandTop),
      Paint()
        ..strokeWidth = 4
        ..color = const Color(0xFF7A9E5A),
    );
  }

  void _phaseAfternoon(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFF4C98A)],
        ).createShader(Offset.zero & size),
    );
    // Tiny garden remnant only while still fading from phase 2.
    if (engine.showGround) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.96),
            width: size.width * 0.18,
            height: 10,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color.fromRGBO(120, 150, 90, 0.55),
      );
    }
    _softCloud(canvas, Offset(size.width * 0.25, size.height * 0.28), 40);
    _softCloud(canvas, Offset(size.width * 0.7, size.height * 0.22), 32);
    final wind = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.35);
    for (var i = 0; i < 12; i++) {
      final x = (elapsed * 40 + i * 55) % (size.width + 40) - 20;
      final y = size.height * (0.3 + (i % 5) * 0.08);
      canvas.drawCircle(Offset(x, y), 1.2, wind);
    }
  }

  void _phaseStrato(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3A5C), Color(0xFF0A1428)],
        ).createShader(Offset.zero & size),
    );
    final star = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.55);
    final rng = math.Random(42);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.7),
        1,
        star,
      );
    }
    _softCloud(
      canvas,
      Offset(
        (elapsed * 8) % (size.width + 80) - 40,
        size.height * 0.4,
      ),
      50,
      color: const Color.fromRGBO(200, 210, 230, 0.2),
    );
  }

  void _phaseVoid(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF020408));

    // Nebulae.
    final drift = elapsed / 90 * math.pi * 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.5 + math.sin(drift) * 20,
          size.height * 0.28,
        ),
        width: size.width * 1.1,
        height: size.height * 0.45,
      ),
      Paint()
        ..color = const Color.fromRGBO(40, 20, 80, 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.72 + math.cos(drift) * 16,
          size.height * 0.7,
        ),
        width: size.width * 0.7,
        height: size.height * 0.4,
      ),
      Paint()
        ..color = const Color.fromRGBO(20, 50, 40, 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );

    // Galaxy smear.
    canvas.save();
    canvas.translate(size.width * 0.22, size.height * 0.18);
    canvas.rotate(-0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 60, height: 20),
      Paint()..color = const Color.fromRGBO(180, 160, 220, 0.12),
    );
    canvas.restore();

    final rng = math.Random(7);
    for (var i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final kind = i % 3;
      if (kind == 0) {
        canvas.drawCircle(
          Offset(x, y),
          1,
          Paint()
            ..color = Color.fromRGBO(
              255,
              255,
              255,
              0.3 + rng.nextDouble() * 0.3,
            ),
        );
      } else if (kind == 1) {
        final twinkle =
            0.5 + 0.4 * (0.5 + 0.5 * math.sin(elapsed / (3 + i % 5) * math.pi * 2));
        canvas.drawCircle(
          Offset(x, y),
          1.5,
          Paint()..color = Color.fromRGBO(240, 244, 255, twinkle),
        );
      } else {
        final driftX = (elapsed * (2 + i % 3) + x) % (size.width + 40) - 20;
        canvas.drawCircle(
          Offset(driftX, y),
          2.2,
          Paint()..color = const Color(0xFFFFFEF0),
        );
      }
    }
  }

  void _softCloud(
    Canvas canvas,
    Offset c,
    double r, {
    Color color = const Color.fromRGBO(255, 255, 255, 0.45),
  }) {
    final p = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(c + Offset(r * 0.6, 4), r * 0.7, p);
    canvas.drawCircle(c - Offset(r * 0.55, -2), r * 0.65, p);
  }

  /// Draws the three base stones seated on the green grass line.
  /// [grassLineScreenY] is the screen Y of [StoneBalanceConstants.grassLineFraction].
  void paintPlatform(Canvas canvas, Size size, double grassLineScreenY) {
    final h = StoneBalanceConstants.platformStoneHeight;
    // Centers sit half a stone above the green so bottoms rest on the line.
    final cy = grassLineScreenY - h / 2;
    final totalW = size.width * 0.55;
    final left = size.width * 0.5 - totalW / 2;
    final w = totalW / 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, grassLineScreenY + 6),
        width: totalW * 1.05,
        height: 14,
      ),
      Paint()
        ..color = const Color.fromRGBO(0, 0, 0, 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    for (var i = 0; i < 3; i++) {
      paintCairnStone(
        canvas,
        cx: left + w * (i + 0.5),
        cy: cy,
        width: w * 1.05,
        height: h,
        tilt: (i - 1) * 0.03,
        shapeSeed: 9000 + i,
      );
    }
  }
}
