import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_bridge.dart';

Color _invColor(Color c, MutationKind? m) => applyMutationTint(base: c, mutation: m);

double _sandHash(int x, int y) {
  var h = x * 374761393 + y * 668265263;
  h = (h ^ (h >> 13)) * 1274126177;
  return ((h & 0xFFFFFF) / 0x1000000);
}

Offset _pointOnPolyline(List<Offset> pts, List<double> cum, double s) {
  if (pts.isEmpty) return Offset.zero;
  if (s <= 0 || cum.length < 2) return pts.first;
  if (s >= cum.last) return pts.last;
  for (var j = 0; j < cum.length - 1; j++) {
    if (s <= cum[j + 1]) {
      final span = cum[j + 1] - cum[j];
      final t = span <= 1e-6 ? 0.0 : (s - cum[j]) / span;
      return Offset(
        pts[j].dx + (pts[j + 1].dx - pts[j].dx) * t,
        pts[j].dy + (pts[j + 1].dy - pts[j].dy) * t,
      );
    }
  }
  return pts.last;
}

/// Calm dry garden sand: soft light, barely-there texture, very sparse raking.
class RakedSandPainter extends CustomPainter {
  RakedSandPainter({
    required this.line,
    required this.washTop,
    required this.washBottom,
  });

  final Color line;
  final Color washTop;
  final Color washBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final mid = Color.lerp(washTop, washBottom, 0.5)!;
    final deep = Color.lerp(washBottom, const Color(0xFF2A2622), 0.08)!;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(washTop, const Color(0xFFFFFFFF), 0.06)!,
            mid,
            washBottom,
            deep,
          ],
          stops: const [0.0, 0.4, 0.75, 1.0],
        ).createShader(rect),
    );

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.55),
        radius: 0.95,
        colors: [
          washTop.withValues(alpha: 0.22),
          washTop.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    final pool = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.55, 0.45),
        radius: 0.75,
        colors: [
          washBottom.withValues(alpha: 0.0),
          Color.lerp(washBottom, line, 0.12)!.withValues(alpha: 0.09),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, pool);

    const grainStep = 16.0;
    for (var gy = 0.0; gy < size.height; gy += grainStep) {
      for (var gx = 0.0; gx < size.width; gx += grainStep) {
        final h = _sandHash(gx.round(), gy.round());
        final a = 0.012 + h * 0.028;
        final r = 0.45 + h * 0.55;
        final base = Color.lerp(washTop, washBottom, 0.4 + h * 0.45)!;
        canvas.drawCircle(
          Offset(gx + (h - 0.5) * 1.2, gy + (_sandHash(gy.round(), gx.round()) - 0.5) * 1.2),
          r,
          Paint()..color = base.withValues(alpha: a),
        );
      }
    }

    final rake = Paint()
      ..color = line.withValues(alpha: 0.038)
      ..strokeWidth = 0.55
      ..style = PaintingStyle.stroke;
    const step = 30.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      final path = Path()..moveTo(x, 0);
      const seg = 14;
      for (var s = 1; s <= seg; s++) {
        final ty = size.height * (s / seg);
        final wave = math.sin(s * 0.35) * 1.8;
        path.lineTo(x + ty * 0.48 + wave, ty);
      }
      canvas.drawPath(path, rake);
    }

    final edgeFade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          deep.withValues(alpha: 0.0),
          deep.withValues(alpha: 0.12),
        ],
        stops: const [0.0, 0.82, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, edgeFade);
  }

  @override
  bool shouldRepaint(covariant RakedSandPainter oldDelegate) {
    return oldDelegate.line != line ||
        oldDelegate.washTop != washTop ||
        oldDelegate.washBottom != washBottom;
  }
}

/// Soft ring for selection + optional timer arc (0–1 progress filled clockwise from top).
class PlantHaloPainter extends CustomPainter {
  PlantHaloPainter({
    required this.selected,
    required this.primary,
    this.timerProgress,
  });

  final bool selected;
  final Color primary;
  final double? timerProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 1;

    if (timerProgress != null) {
      final track = Paint()
        ..color = primary.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(c, r, track);
      final sweep = 2 * math.pi * timerProgress!.clamp(0.0, 1.0);
      final arc = Paint()
        ..color = primary.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        sweep,
        false,
        arc,
      );
    }

    if (selected) {
      final ring = Paint()
        ..color = primary.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = timerProgress != null ? 2 : 2.5;
      canvas.drawCircle(c, r + (timerProgress != null ? 8 : 6), ring);
    }
  }

  @override
  bool shouldRepaint(covariant PlantHaloPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.primary != primary ||
        oldDelegate.timerProgress != timerProgress;
  }
}

/// Drop preview while dragging.
class DropPreviewPainter extends CustomPainter {
  DropPreviewPainter({required this.center, required this.color});

  final Offset center;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 28, p);
    final fill = Paint()..color = color.withValues(alpha: 0.08);
    canvas.drawCircle(center, 28, fill);
  }

  @override
  bool shouldRepaint(covariant DropPreviewPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.color != color;
  }
}

/// Plant silhouettes; mature stage reads as a small tree (trunk + branches + canopy).
class ZenPlantPainter extends CustomPainter {
  ZenPlantPainter({
    required this.stageIndex,
    required this.fill,
    required this.outline,
    required this.mutation,
  });

  final int stageIndex;
  final Color fill;
  final Color outline;
  final MutationKind? mutation;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final foliage = _invColor(fill, mutation);
    final edge = _invColor(outline, mutation).withValues(alpha: 0.55);
    final trunk = _invColor(const Color(0xFF4E342E), mutation);
    final trunkDark = _invColor(const Color(0xFF3E2723), mutation);

    void trunkRect(double width, double height, double cx, double bottom) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, bottom - height / 2),
          width: width,
          height: height,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(r, Paint()..color = trunk);
      canvas.drawRRect(
        r,
        Paint()
          ..color = trunkDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    void branch(double x0, double y0, double x1, double y1, double sw) {
      canvas.drawLine(
        Offset(x0, y0),
        Offset(x1, y1),
        Paint()
          ..color = trunk
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(x0, y0),
        Offset(x1, y1),
        Paint()
          ..color = trunkDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }

    void leafBlob(double cx, double cy, double rx, double ry, double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final path = Path()
        ..addOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2));
      canvas.drawPath(path, Paint()..color = foliage.withValues(alpha: 0.9));
      canvas.drawPath(
        path,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.restore();
    }

    final cx = w * 0.5;
    final bottom = h * 0.94;

    switch (stageIndex.clamp(0, 4)) {
      case 0:
        final pebble = Path()
          ..addOval(Rect.fromCenter(
            center: Offset(cx, bottom - 10),
            width: w * 0.26,
            height: w * 0.16,
          ));
        canvas.drawPath(pebble, Paint()..color = foliage.withValues(alpha: 0.92));
        canvas.drawPath(
          pebble,
          Paint()
            ..color = edge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      case 1:
        trunkRect(6, h * 0.26, cx, bottom);
        branch(cx, bottom - h * 0.22, cx - w * 0.12, bottom - h * 0.36, 3);
        branch(cx, bottom - h * 0.2, cx + w * 0.1, bottom - h * 0.34, 3);
        leafBlob(cx - w * 0.02, bottom - h * 0.4, w * 0.12, w * 0.07, -0.55);
        leafBlob(cx + w * 0.04, bottom - h * 0.42, w * 0.1, w * 0.06, 0.65);
      case 2:
        trunkRect(7, h * 0.34, cx, bottom);
        branch(cx, bottom - h * 0.28, cx - w * 0.16, bottom - h * 0.44, 3.5);
        branch(cx, bottom - h * 0.26, cx + w * 0.14, bottom - h * 0.42, 3.5);
        leafBlob(cx - w * 0.1, bottom - h * 0.48, w * 0.16, w * 0.09, -0.9);
        leafBlob(cx + w * 0.08, bottom - h * 0.46, w * 0.15, w * 0.08, 0.9);
        leafBlob(cx, bottom - h * 0.52, w * 0.13, w * 0.08, 0);
      case 3:
        trunkRect(8, h * 0.4, cx, bottom);
        branch(cx, bottom - h * 0.32, cx - w * 0.18, bottom - h * 0.5, 4);
        branch(cx, bottom - h * 0.3, cx + w * 0.16, bottom - h * 0.48, 4);
        leafBlob(cx - w * 0.14, bottom - h * 0.52, w * 0.18, w * 0.1, -1.05);
        leafBlob(cx + w * 0.12, bottom - h * 0.5, w * 0.18, w * 0.1, 1.05);
        final bloom = Path()
          ..addOval(Rect.fromCenter(
            center: Offset(cx, bottom - h * 0.62),
            width: w * 0.14,
            height: w * 0.14,
          ));
        canvas.drawPath(bloom, Paint()..color = foliage.withValues(alpha: 0.95));
        canvas.drawPath(
          bloom,
          Paint()
            ..color = edge
            ..style = PaintingStyle.stroke,
        );
      default:
        trunkRect(11, h * 0.36, cx, bottom);
        final joinY = bottom - h * 0.34;
        branch(cx, bottom - h * 0.08, cx - w * 0.06, joinY, 5);
        branch(cx, bottom - h * 0.08, cx + w * 0.06, joinY, 5);
        branch(cx, joinY, cx - w * 0.2, bottom - h * 0.56, 3.5);
        branch(cx, joinY, cx + w * 0.18, bottom - h * 0.54, 3.5);
        branch(cx - w * 0.06, joinY - h * 0.06, cx - w * 0.22, bottom - h * 0.62, 2.8);
        branch(cx + w * 0.05, joinY - h * 0.05, cx + w * 0.2, bottom - h * 0.6, 2.8);
        final canopy = Path();
        canopy.addOval(Rect.fromCenter(
          center: Offset(cx, bottom - h * 0.58),
          width: w * 0.62,
          height: w * 0.44,
        ));
        canvas.drawPath(canopy, Paint()..color = foliage.withValues(alpha: 0.92));
        canvas.drawPath(
          canopy,
          Paint()
            ..color = edge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        leafBlob(cx - w * 0.22, bottom - h * 0.52, w * 0.16, w * 0.11, -0.35);
        leafBlob(cx + w * 0.22, bottom - h * 0.52, w * 0.16, w * 0.11, 0.35);
        leafBlob(cx, bottom - h * 0.72, w * 0.14, w * 0.09, 0);
    }
  }

  @override
  bool shouldRepaint(covariant ZenPlantPainter oldDelegate) {
    return oldDelegate.stageIndex != stageIndex ||
        oldDelegate.fill != fill ||
        oldDelegate.outline != outline ||
        oldDelegate.mutation != mutation;
  }
}

math.Random _decorRng(String kind, String id, int st) =>
    math.Random(kind.hashCode ^ id.hashCode ^ (st * 9176));

void _drawKoi(
  Canvas canvas,
  Offset center,
  double angle,
  double scale,
  Color body,
  Color accent,
  Color edge,
) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  final torso = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(5 * scale, 0), width: 16 * scale, height: 8 * scale),
    Radius.circular(4 * scale),
  );
  canvas.drawRRect(torso, Paint()..color = body);
  canvas.drawRRect(
    torso,
    Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  final tail = Path()
    ..moveTo(-9 * scale, 0)
    ..lineTo(-2 * scale, -5 * scale)
    ..lineTo(-2 * scale, 5 * scale)
    ..close();
  canvas.drawPath(tail, Paint()..color = body);
  canvas.drawPath(
    tail,
    Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(2 * scale, -1.5 * scale), width: 7 * scale, height: 5 * scale),
    Paint()..color = accent.withValues(alpha: 0.92),
  );
  canvas.drawCircle(Offset(10 * scale, -1 * scale), 1.6 * scale, Paint()..color = edge);
  canvas.restore();
}

/// Decor evolves with [stageIndex] (layout + detail, not just “more copies”).
/// All colors go through mutation tint.
class ZenDecorPainter extends CustomPainter {
  ZenDecorPainter({
    required this.item,
    required this.primary,
    required this.secondary,
  });

  final DecorItem item;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final k = item.kind;
    final m = item.mutation;
    final st = item.stageIndex.clamp(0, 4);
    final growth = 1.0 + st * 0.08;

    Color p(Color x) => _invColor(x, m);

    if (k == 'zen.stone_path') {
      final rnd = _decorRng(k, item.id, st);
      const samples = 36;
      final pathPts = <Offset>[];
      for (var i = 0; i <= samples; i++) {
        final t = i / samples;
        final px = (t - 0.5) * size.width * 0.52;
        final py = math.sin(t * math.pi * 0.92) * size.height * 0.12 + (t - 0.48) * size.height * 0.05;
        pathPts.add(Offset(c.dx + px, c.dy + py));
      }
      final cum = <double>[0.0];
      for (var i = 1; i < pathPts.length; i++) {
        cum.add(cum.last + (pathPts[i] - pathPts[i - 1]).distance);
      }
      final pathLen = cum.last;
      final n = 3 + st;
      for (var i = 0; i < n; i++) {
        final s = pathLen * (n == 1 ? 0.5 : i / (n - 1));
        final pt = _pointOnPolyline(pathPts, cum, s);
        final s0 = (s - 5.0).clamp(0.0, pathLen);
        final s1 = (s + 5.0).clamp(0.0, pathLen);
        final back = _pointOnPolyline(pathPts, cum, s0);
        final ahead = _pointOnPolyline(pathPts, cum, s1);
        var ang = math.atan2(ahead.dy - back.dy, ahead.dx - back.dx);
        ang += (rnd.nextDouble() - 0.5) * 0.04;
        final pw = (15.5 + rnd.nextDouble() * 3.5 + st * 0.9) * (0.92 + st * 0.02);
        final ph = (10.5 + rnd.nextDouble() * 2.5 + st * 0.6) * (0.92 + st * 0.02);
        final rad = Radius.circular(math.min(4.5, math.min(pw, ph) * 0.2));
        canvas.save();
        canvas.translate(pt.dx, pt.dy);
        canvas.rotate(ang);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(1.2, 1.6), width: pw, height: ph),
            rad,
          ),
          Paint()..color = const Color(0xFF1A1512).withValues(alpha: 0.11),
        );
        final stoneRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: pw, height: ph),
          rad,
        );
        final light = p(const Color(0xFFD2CEC6));
        final mid = p(const Color(0xFFA8A098));
        final dark = p(const Color(0xFF6F6A62));
        canvas.drawRRect(
          stoneRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [light, mid, dark],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(Rect.fromCenter(center: Offset.zero, width: pw, height: ph)),
        );
        canvas.drawRRect(
          stoneRect,
          Paint()
            ..color = p(const Color(0xFF4A4540)).withValues(alpha: 0.42)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9,
        );
        canvas.drawLine(
          Offset(-pw * 0.22, -ph * 0.28),
          Offset(pw * 0.12, -ph * 0.32),
          Paint()
            ..color = p(const Color(0xFFF8F6F2)).withValues(alpha: 0.38)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
        canvas.restore();
      }
    } else if (k == 'zen.koi_pond') {
      final rnd = _decorRng(k, item.id, st);
      final pondW = size.width * (0.72 + st * 0.06) * growth;
      final pondH = size.height * (0.48 + st * 0.05) * growth;
      final pondRect = Rect.fromCenter(center: c, width: pondW, height: pondH);
      final waterDeep = p(const Color(0xFF3D6B8E));
      final waterMid = p(const Color(0xFF5E8EB8));
      final waterLite = p(const Color(0xFF8FB8D8));
      final waterPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            waterLite.withValues(alpha: 0.55 + st * 0.06),
            waterMid.withValues(alpha: 0.65 + st * 0.04),
            waterDeep.withValues(alpha: 0.75),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(pondRect);
      canvas.drawOval(pondRect, waterPaint);
      canvas.drawOval(
        pondRect,
        Paint()
            ..color = p(const Color(0xFF2C4A5E)).withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 + st * 0.2,
      );
      if (st >= 2) {
        for (var i = 0; i < 1 + st; i++) {
          final a = rnd.nextDouble() * math.pi * 2;
          final rr = 0.2 + rnd.nextDouble() * 0.35;
          final lp = Offset(
            c.dx + math.cos(a) * pondW * 0.32 * rr,
            c.dy + math.sin(a) * pondH * 0.32 * rr,
          );
          canvas.drawOval(
            Rect.fromCenter(center: lp, width: 10 + st * 2.0, height: 8 + st * 1.5),
            Paint()..color = p(const Color(0xFF4A7A4A)).withValues(alpha: 0.55 + st * 0.05),
          );
          canvas.drawOval(
            Rect.fromCenter(center: lp.translate(1, 1), width: 6, height: 5),
            Paint()..color = p(const Color(0xFF3D5C3D)).withValues(alpha: 0.35),
          );
        }
      }
      if (st >= 3) {
        for (var i = 0; i < 6 + st; i++) {
          final ang = i / (6 + st) * math.pi * 2 + rnd.nextDouble() * 0.2;
          final rr = 0.42 + rnd.nextDouble() * 0.12;
          final edge = Offset(
            c.dx + math.cos(ang) * pondW * 0.48 * rr,
            c.dy + math.sin(ang) * pondH * 0.48 * rr,
          );
          canvas.drawCircle(
            edge,
            2.2 + rnd.nextDouble(),
            Paint()..color = p(const Color(0xFF7A7A7A)).withValues(alpha: 0.75),
          );
        }
      }
      final koiBody = p(const Color(0xFFD84315));
      final koiAccent = p(const Color(0xFFFFF8F0));
      final koiEdge = p(const Color(0xFF4E342E)).withValues(alpha: 0.65);
      final fishCount = 1 + (st * 3 ~/ 2) + (st >= 4 ? 1 : 0);
      for (var i = 0; i < fishCount; i++) {
        var fx = (rnd.nextDouble() - 0.5) * pondW * 0.55;
        var fy = (rnd.nextDouble() - 0.5) * pondH * 0.48;
        if ((fx * fx) / (pondW * 0.5 * pondW * 0.5) + (fy * fy) / (pondH * 0.45 * pondH * 0.45) > 0.85) {
          fx *= 0.82;
          fy *= 0.82;
        }
        final pos = Offset(c.dx + fx, c.dy + fy);
        final ang = rnd.nextDouble() * math.pi * 2;
        _drawKoi(canvas, pos, ang, 0.85 + st * 0.05 + rnd.nextDouble() * 0.08, koiBody, koiAccent, koiEdge);
      }
      if (st >= 1) {
        canvas.drawOval(
          pondRect.deflate(4),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.04 + st * 0.015)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    } else if (k == 'zen.stone_lantern') {
      final stone = p(const Color(0xFF9E9E9E));
      final stoneHi = p(const Color(0xFFC4C4C4));
      final stoneLo = p(const Color(0xFF6D6D6D));
      final lift = st * 2.5;
      final base = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 22 - lift), width: 34 * growth, height: 8),
        const Radius.circular(2),
      );
      canvas.drawRRect(base, Paint()..color = stoneLo);
      canvas.drawRRect(
        base,
        Paint()
          ..color = stone.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      final post = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 8 - lift), width: 10 * growth, height: 22),
        const Radius.circular(2),
      );
      canvas.drawRRect(post, Paint()..color = stone);
      canvas.drawRRect(
        post,
        Paint()
          ..color = stoneLo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final boxH = 22.0 + st * 2;
      final boxW = 22.0 + st * 1.5;
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy - 8 - lift), width: boxW * growth, height: boxH),
        const Radius.circular(3),
      );
      canvas.drawRRect(boxRect, Paint()..color = stoneHi.withValues(alpha: 0.95));
      canvas.drawRRect(
        boxRect,
        Paint()
          ..color = stoneLo
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
      );
      final glow = p(const Color(0xFFFFE082));
      final inset = 5.0;
      final win = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - 8 - lift),
          width: boxW * growth - inset * 2,
          height: boxH - inset * 2,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(win, Paint()..color = glow.withValues(alpha: 0.92));
      canvas.drawRRect(
        win,
        Paint()
          ..color = p(const Color(0xFF5D4037)).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      final midX = c.dx;
      final midY = c.dy - 8 - lift;
      canvas.drawLine(
        Offset(midX - boxW * growth / 2 + inset, midY),
        Offset(midX + boxW * growth / 2 - inset, midY),
        Paint()
          ..color = p(const Color(0xFF5D4037)).withValues(alpha: 0.75)
          ..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(midX, midY - boxH / 2 + inset),
        Offset(midX, midY + boxH / 2 - inset),
        Paint()
          ..color = p(const Color(0xFF5D4037)).withValues(alpha: 0.75)
          ..strokeWidth = 1,
      );
      if (st >= 2) {
        for (final dy in [-boxH / 2 + 3, boxH / 2 - 3]) {
          canvas.drawLine(
            Offset(c.dx - boxW * growth / 2, c.dy - 8 - lift + dy),
            Offset(c.dx + boxW * growth / 2, c.dy - 8 - lift + dy),
            Paint()
              ..color = stoneLo.withValues(alpha: 0.8)
              ..strokeWidth = 1,
          );
        }
      }
      final roofW = 28.0 + st * 3;
      final roof = Path()
        ..moveTo(c.dx, c.dy - 26 - lift - st * 2)
        ..lineTo(c.dx - roofW * growth / 2, c.dy - 14 - lift)
        ..lineTo(c.dx + roofW * growth / 2, c.dy - 14 - lift)
        ..close();
      canvas.drawPath(roof, Paint()..color = stoneLo.withValues(alpha: 0.95));
      canvas.drawPath(
        roof,
        Paint()
          ..color = p(const Color(0xFF424242)).withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      if (st >= 3) {
        final cap = Path()
          ..moveTo(c.dx, c.dy - 32 - lift - st * 2)
          ..lineTo(c.dx - 6, c.dy - 26 - lift - st * 2)
          ..lineTo(c.dx + 6, c.dy - 26 - lift - st * 2)
          ..close();
        canvas.drawPath(cap, Paint()..color = stone);
      }
    } else if (k == 'zen.wood_bench') {
      final wood = p(const Color(0xFF7B4F3B));
      final woodHi = p(const Color(0xFFA67C5A));
      final woodDark = p(const Color(0xFF4E342E));
      final seatW = 38.0 + st * 6;
      final seatH = 7.0 + (st >= 2 ? 1.0 : 0);
      final seatY = c.dy - 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, seatY), width: seatW * growth, height: seatH),
          const Radius.circular(2),
        ),
        Paint()..color = woodHi,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, seatY), width: seatW * growth, height: seatH),
          const Radius.circular(2),
        ),
        Paint()
          ..color = woodDark.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (st >= 1) {
        for (final x in [-seatW * growth / 2 + 6, seatW * growth / 2 - 6]) {
          final leg = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(c.dx + x, c.dy + 12), width: 5, height: 14.0 + st),
            const Radius.circular(1),
          );
          canvas.drawRRect(leg, Paint()..color = wood);
          canvas.drawRRect(
            leg,
            Paint()
              ..color = woodDark
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }
      if (st >= 2) {
        final backH = 12.0 + (st - 2) * 4;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(c.dx, c.dy - 14 - st), width: seatW * growth - 4, height: backH),
            const Radius.circular(2),
          ),
          Paint()..color = wood.withValues(alpha: 0.92),
        );
        for (var i = 0; i < 2 + st; i++) {
          final yy = c.dy - 18 - st + i * (backH / (3 + st));
          canvas.drawLine(
            Offset(c.dx - seatW * growth / 2 + 4, yy),
            Offset(c.dx + seatW * growth / 2 - 4, yy),
            Paint()
              ..color = woodDark.withValues(alpha: 0.35)
              ..strokeWidth = 1,
          );
        }
      }
      if (st >= 3) {
        for (final sx in [-seatW * growth / 2 + 2, seatW * growth / 2 - 2]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(c.dx + sx, c.dy + 4), width: 4, height: 18),
              const Radius.circular(2),
            ),
            Paint()..color = woodHi,
          );
        }
      }
      if (st >= 4) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(c.dx, c.dy + 18), width: seatW * growth + 6, height: 4),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.12),
        );
      }
    } else if (k == 'zen.bamboo_fence') {
      final bamboo = p(const Color(0xFF7CB342));
      final bambooDark = p(const Color(0xFF558B2F));
      final poles = 4 + st;
      final span = 44.0 * growth;
      for (var i = 0; i < poles; i++) {
        final x = c.dx - span / 2 + (i / (poles - 1)) * span;
        final h = 34.0 + st * 4 + (i.isEven ? 2.0 : 0);
        final pole = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, c.dy - 2), width: 4.5, height: h),
          const Radius.circular(2),
        );
        canvas.drawRRect(pole, Paint()..color = bamboo);
        canvas.drawRRect(
          pole,
          Paint()
            ..color = bambooDark.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        canvas.drawLine(
          Offset(x, c.dy - h / 2 - 2),
          Offset(x + 1.5, c.dy - h / 2 + 4),
          Paint()..color = bambooDark.withValues(alpha: 0.35)..strokeWidth = 1,
        );
      }
      if (st >= 1) {
        for (var r = 0; r < st.clamp(1, 3); r++) {
          final yy = c.dy - 8 - r * 10.0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(c.dx, yy), width: span + 4, height: 3),
              const Radius.circular(1.5),
            ),
            Paint()..color = bambooDark.withValues(alpha: 0.75),
          );
        }
      }
      if (st >= 3) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(c.dx, c.dy + 14), width: span, height: 3),
            const Radius.circular(1),
          ),
          Paint()..color = p(const Color(0xFF6D4C41)).withValues(alpha: 0.45),
        );
      }
    } else if (k == 'zen.moss_rock') {
      final rnd = _decorRng(k, item.id, st);
      final sc = 1.0 + st * 0.06;
      final rockHi = p(const Color(0xFF9E9A93));
      final rockMid = p(const Color(0xFF6F6B64));
      final rockLo = p(const Color(0xFF4A4742));
      final mossHi = p(const Color(0xFF6B8F5E));
      final mossLo = p(const Color(0xFF3D5A38));
      final mossDeep = p(const Color(0xFF2A3D28));

      canvas.drawOval(
        Rect.fromCenter(center: c.translate(3, 5), width: 52 * sc, height: 28 * sc),
        Paint()..color = const Color(0xFF1A1512).withValues(alpha: 0.14),
      );

      final boulder = Path()
        ..moveTo(c.dx - 24 * sc, c.dy + 10 * sc)
        ..cubicTo(
          c.dx - 32 * sc,
          c.dy - 4 * sc,
          c.dx - 14 * sc,
          c.dy - 20 * sc,
          c.dx + 4 * sc,
          c.dy - 16 * sc,
        )
        ..cubicTo(
          c.dx + 22 * sc,
          c.dy - 12 * sc,
          c.dx + 30 * sc,
          c.dy + 2 * sc,
          c.dx + 20 * sc,
          c.dy + 12 * sc,
        )
        ..cubicTo(
          c.dx + 8 * sc,
          c.dy + 20 * sc,
          c.dx - 10 * sc,
          c.dy + 18 * sc,
          c.dx - 24 * sc,
          c.dy + 10 * sc,
        )
        ..close();

      final bb = boulder.getBounds();
      canvas.drawPath(
        boulder,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [rockHi, rockMid, rockLo],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bb),
      );
      canvas.drawPath(
        boulder,
        Paint()
          ..color = p(const Color(0xFF2C2926)).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );

      void mossClump(double ox, double oy, double w, double h, double rot, double a) {
        canvas.save();
        canvas.translate(c.dx + ox, c.dy + oy);
        canvas.rotate(rot);
        final clump = Path()
          ..addOval(Rect.fromCenter(center: Offset.zero, width: w, height: h));
        canvas.drawPath(
          clump,
          Paint()
            ..shader = RadialGradient(
              colors: [
                mossHi.withValues(alpha: a),
                mossLo.withValues(alpha: a * 0.85),
                mossDeep.withValues(alpha: a * 0.5),
              ],
            ).createShader(Rect.fromCenter(center: Offset.zero, width: w, height: h)),
        );
        canvas.drawPath(
          clump,
          Paint()
            ..color = mossDeep.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6,
        );
        canvas.restore();
      }

      mossClump(-14 * sc, -10 * sc, 16.0 + st * 2.0, 11.0 + st, -0.35, 0.72);
      mossClump(8 * sc, -6 * sc, 14.0 + st * 1.5, 9.0 + st, 0.5, 0.65);
      mossClump(-4 * sc, 4 * sc, 20.0 + st * 2.5, 12.0 + st, 0.1, 0.58 + st * 0.04);
      if (st >= 2) {
        mossClump(16 * sc, 6 * sc, 12.0, 8.0, 0.9, 0.5);
      }
      if (st >= 3) {
        mossClump(-20 * sc, 6 * sc, 10.0, 7.0, -0.8, 0.45);
      }

      for (var i = 0; i < 5 + st; i++) {
        final lx = (rnd.nextDouble() - 0.5) * 28 * sc;
        final ly = (rnd.nextDouble() - 0.5) * 16 * sc;
        canvas.drawCircle(
          Offset(c.dx + lx, c.dy + ly),
          0.8 + rnd.nextDouble(),
          Paint()..color = p(const Color(0xFFC8D4BA)).withValues(alpha: 0.35 + st * 0.03),
        );
      }
    } else {
      final rnd = _decorRng(k, item.id, st);
      final rockDark = p(const Color(0xFF6D6D6D));
      final rockMid = p(const Color(0xFF8A8A8A));
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(2, 4), width: 36 * growth, height: 22 * growth),
        Paint()..color = const Color(0xFF1A1512).withValues(alpha: 0.12),
      );
      final rock = Path()
        ..addOval(Rect.fromCenter(center: c, width: 34 * growth, height: 20 * growth));
      canvas.drawPath(
        rock,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [rockMid.withValues(alpha: 0.95), rockDark.withValues(alpha: 0.9)],
          ).createShader(Rect.fromCenter(center: c, width: 34 * growth, height: 20 * growth)),
      );
      canvas.drawPath(
        rock,
        Paint()
            ..color = p(const Color(0xFF424242)).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
      );
      for (var i = 0; i < 3 + st; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              c.dx + (rnd.nextDouble() - 0.5) * 16,
              c.dy + (rnd.nextDouble() - 0.5) * 10,
            ),
            width: 5 + rnd.nextDouble() * 3,
            height: 4 + rnd.nextDouble() * 2,
          ),
          Paint()..color = p(const Color(0xFF4A6741)).withValues(alpha: 0.4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZenDecorPainter oldDelegate) {
    return oldDelegate.item != item ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}
