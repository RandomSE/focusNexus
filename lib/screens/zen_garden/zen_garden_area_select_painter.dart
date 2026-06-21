import 'package:flutter/material.dart';

class ZenGardenAreaSelectBoxPainter extends CustomPainter {
  ZenGardenAreaSelectBoxPainter({
    required this.startNorm,
    required this.endNorm,
    required this.color,
  });

  final Offset startNorm;
  final Offset endNorm;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(
      Offset(startNorm.dx * size.width, startNorm.dy * size.height),
      Offset(endNorm.dx * size.width, endNorm.dy * size.height),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant ZenGardenAreaSelectBoxPainter oldDelegate) {
    return oldDelegate.startNorm != startNorm ||
        oldDelegate.endNorm != endNorm ||
        oldDelegate.color != color;
  }
}
