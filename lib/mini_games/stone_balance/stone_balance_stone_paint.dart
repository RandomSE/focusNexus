import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Deterministic irregular cairn outline for a stone of [width] x [height].
Path cairnStonePath(double width, double height, int seed) {
  final r = math.Random(seed);
  final hw = width / 2;
  final hh = height / 2;

  Offset jx(double x, double y, double amount) {
    return Offset(x + (r.nextDouble() * 2 - 1) * amount, y);
  }

  // Flat top/bottom (same Y) so stacked edges meet with two contact points /
  // a continuous edge; only horizontal jitter. Wilder sides keep the cairn look.
  final topL = jx(-hw * 0.72, -hh, 4);
  final topR = jx(hw * 0.72, -hh, 4);
  final midR = Offset(hw + (r.nextDouble() * 2 - 1) * 8, 0);
  final botR = jx(hw * 0.7, hh, 4);
  final botL = jx(-hw * 0.7, hh, 4);
  final midL = Offset(-hw + (r.nextDouble() * 2 - 1) * 8, 0);

  return Path()
    ..moveTo(topL.dx, topL.dy)
    ..lineTo(topR.dx, topR.dy)
    ..lineTo(midR.dx, midR.dy)
    ..lineTo(botR.dx, botR.dy)
    ..lineTo(botL.dx, botL.dy)
    ..lineTo(midL.dx, midL.dy)
    ..close();
}

List<Path> cairnGrainLines(double width, double height, int seed) {
  final r = math.Random(seed ^ 0x9E3779B9);
  final count = 2 + r.nextInt(2);
  final lines = <Path>[];
  for (var i = 0; i < count; i++) {
    final x0 = (r.nextDouble() - 0.5) * width * 0.55;
    final y0 = (r.nextDouble() - 0.5) * height * 0.45;
    final len = 3.0 + r.nextDouble() * 3.0;
    final ang = r.nextDouble() * math.pi;
    final path = Path()
      ..moveTo(x0, y0)
      ..quadraticBezierTo(
        x0 + math.cos(ang) * len * 0.5 + (r.nextDouble() - 0.5) * 2,
        y0 + math.sin(ang) * len * 0.5 + (r.nextDouble() - 0.5) * 2,
        x0 + math.cos(ang) * len,
        y0 + math.sin(ang) * len,
      );
    lines.add(path);
  }
  return lines;
}

void paintCairnStone(
  Canvas canvas, {
  required double cx,
  required double cy,
  required double width,
  required double height,
  required double tilt,
  required int shapeSeed,
  double opacity = 1,
  bool ghost = false,
  bool ambientGlow = false,
  bool highlight = false,
}) {
  canvas.save();
  canvas.translate(cx, cy);
  canvas.rotate(tilt);

  if (ambientGlow || highlight) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: width * (highlight ? 1.55 : 1.35),
        height: height * (highlight ? 1.85 : 1.6),
      ),
      Paint()
        ..color = highlight
            ? const Color.fromRGBO(255, 210, 90, 0.35)
            : const Color.fromRGBO(255, 200, 120, 0.08)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          highlight ? 16 : 12,
        ),
    );
  }

  final path = cairnStonePath(width, height, shapeSeed);
  final top = Color.fromRGBO(
    highlight ? 0xFF : 0xC8,
    highlight ? 0xE0 : 0xB8,
    highlight ? 0x90 : 0x9A,
    opacity * (ghost ? 0.55 : 1),
  );
  final side = Color.fromRGBO(
    highlight ? 0xE0 : 0x8A,
    highlight ? 0xB0 : 0x7A,
    highlight ? 0x50 : 0x62,
    opacity * (ghost ? 0.45 : 1),
  );
  final bounds = path.getBounds();
  final fill = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, side],
    ).createShader(bounds);
  canvas.drawPath(path, fill);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlight ? 2.5 : 1
      ..color = highlight
          ? Color.fromRGBO(255, 230, 120, opacity)
          : Color.fromRGBO(0x6A, 0x5A, 0x48, opacity * (ghost ? 0.5 : 1)),
  );

  if (!ghost) {
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color.fromRGBO(
        0x9A,
        0x8A,
        0x72,
        (highlight ? 0.55 : 0.4) * opacity,
      );
    for (final line in cairnGrainLines(width, height, shapeSeed)) {
      canvas.drawPath(line, grainPaint);
    }
  }

  canvas.restore();
}
