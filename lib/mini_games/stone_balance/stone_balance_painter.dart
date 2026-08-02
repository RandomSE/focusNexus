import 'package:flutter/material.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_backdrop.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_engine.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_stone_paint.dart';

class StoneBalancePainter extends CustomPainter {
  StoneBalancePainter({required this.engine});

  final StoneBalanceEngine engine;

  static const Color skyBottom = Color(0xFF0D121C);

  double _screenY(double worldY) => worldY - engine.cameraY;

  @override
  void paint(Canvas canvas, Size size) {
    final backdrop = StoneBalanceBackdrop(
      engine: engine,
      elapsed: engine.elapsedSeconds,
    );
    backdrop.paint(canvas, size);

    final grassLine = _screenY(engine.grassLineY);
    if (engine.showGround) {
      backdrop.paintPlatform(canvas, size, grassLine);
    }

    final glow = engine.score >= 60;
    for (final stone in engine.stack) {
      paintCairnStone(
        canvas,
        cx: stone.cx,
        cy: _screenY(stone.cy),
        width: stone.width,
        height: stone.height,
        tilt: stone.tilt,
        shapeSeed: stone.shapeSeed,
        ambientGlow: glow,
      );
    }

    final ghost = engine.ghost;
    if (ghost != null) {
      final gy = size.height * StoneBalanceConstants.spawnYFraction;
      paintCairnStone(
        canvas,
        cx: ghost.cx,
        cy: gy,
        width: ghost.width,
        height: ghost.height,
        tilt: 0,
        shapeSeed: ghost.shapeSeed,
        ghost: true,
      );
      final targetY = engine.stack.isEmpty
          ? _screenY(engine.platformTopY)
          : _screenY(engine.stack.last.cy - engine.stack.last.height / 2);
      _drawDottedLine(
        canvas,
        Offset(ghost.cx, gy + ghost.height / 2),
        Offset(ghost.cx, targetY),
      );
    }

    final fall = engine.falling;
    if (fall != null) {
      paintCairnStone(
        canvas,
        cx: fall.cx,
        cy: fall.screenCy,
        width: fall.width,
        height: fall.height,
        tilt: 0,
        shapeSeed: fall.shapeSeed,
      );
    }

    for (final s in engine.scatter) {
      final isOffender = s.isOffender;
      final opacity = isOffender
          ? 1.0
          : (1.0 - s.age / StoneBalanceConstants.scatterLife).clamp(0.15, 1.0);
      paintCairnStone(
        canvas,
        cx: s.cx,
        cy: _screenY(s.cy),
        width: s.width,
        height: s.height,
        tilt: s.tilt,
        shapeSeed: s.shapeSeed,
        opacity: opacity,
        highlight: isOffender,
      );
    }

    for (final puff in engine.dust) {
      _paintDust(canvas, puff.cx, _screenY(puff.cy), puff.age);
    }
  }

  void _drawDottedLine(Canvas canvas, Offset a, Offset b) {
    final paint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dist = (b - a).distance;
    if (dist < 1) return;
    final dir = (b - a) / dist;
    var d = 0.0;
    var draw = true;
    while (d < dist) {
      final next = (d + 6).clamp(0.0, dist);
      if (draw) {
        canvas.drawLine(a + dir * d, a + dir * next, paint);
      }
      d = next;
      draw = !draw;
    }
  }

  void _paintDust(Canvas canvas, double cx, double cy, double age) {
    final t = (age / DustPuff.life).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Color.fromRGBO(200, 180, 150, (1 - t) * 0.55);
    for (var i = 0; i < 7; i++) {
      final r = 6 + t * 18 + i;
      canvas.drawCircle(
        Offset(cx + r * (i.isEven ? 1 : -1) * 0.4, cy - t * 10 - i),
        2.5 + (1 - t) * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StoneBalancePainter oldDelegate) => true;
}
