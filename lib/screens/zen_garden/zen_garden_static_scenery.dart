import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'zen_garden_cartoon_style.dart';
import 'zen_garden_painters.dart';

/// Fixed garden scenery painted above sand, below interactive placeables.
class ZenGardenStaticSceneryPainter extends CustomPainter {
  ZenGardenStaticSceneryPainter._(this.palette);

  factory ZenGardenStaticSceneryPainter.harmonized({
    Color? themePrimary,
    Color? themeSecondary,
  }) =>
      ZenGardenStaticSceneryPainter._(
        ZenGardenBackgroundPalette.harmonized(
          themePrimary: themePrimary,
          themeSecondary: themeSecondary,
        ),
      );

  final ZenGardenBackgroundPalette palette;

  static const _stoneHi = Color(0xFFF0EBE2);
  static const _stoneMid = Color(0xFFC8BFB4);
  static const _stoneLo = Color(0xFF8A8278);
  static const _bamboo = Color(0xFF6B8F5A);
  static const _bambooDark = Color(0xFF556B48);
  static const _bambooLeaf = Color(0xFF7A9467);
  static const _sandRockTint = Color(0x1FB49664);
  static const _shrubOutline = Color(0xFF5A7A4A);
  static const _wood = Color(0xFF8B5E3C);
  static const _shrub = Color(0xFF7A9467);
  static const _shrubHi = Color(0xFF8FA37D);
  static const _shrubShadow = Color(0xFF556B48);
  static const _moss = Color(0xFF6FA858);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackdropBamboo(canvas, size);
    _drawLeftFence(canvas, size);
    _drawCornerShrubs(canvas, size);
    _drawEdgeBoulders(canvas, size);
    _drawFlatRockCluster(canvas, size);
    _drawCenterBottomShrub(canvas, size);
    _drawSteppingStones(canvas, size);
    _drawBorderAccents(canvas, size);
  }

  void _drawBackdropBamboo(Canvas canvas, Size size) {
    final baseY = size.height * 0.06;
    const count = 7;
    for (var i = 0; i < count; i++) {
      final t = i / (count - 1);
      final x = size.width * (0.08 + t * 0.84);
      var h = size.height * (0.22 + _hash(i, 3) * 0.08);
      if (i % 3 == 2) {
        h *= 0.88 + _hash(i, 11) * 0.04;
      }
      _drawBambooStalk(
        canvas,
        Offset(x, baseY + h),
        h,
        0.9 + _hash(i, 9) * 0.2,
        showLeaf: i.isEven,
        leafDir: i <= count ~/ 2 ? 1.0 : -1.0,
      );
    }
  }

  void _drawBambooStalk(
    Canvas canvas,
    Offset base,
    double height,
    double scale, {
    bool showLeaf = false,
    double leafDir = 1.0,
  }) {
    const w = 3.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - height / 2),
        width: w,
        height: height,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rect, Paint()..color = _bamboo);
    _drawBambooNodeRings(canvas, base.dx, base.dy, height);
    if (showLeaf) {
      final ly = base.dy - height * 0.42;
      _drawBambooLeaf(canvas, Offset(base.dx + leafDir * 6, ly), leafDir, scale * 0.75);
    }
  }

  void _drawSandTint(Canvas canvas, Path shape) {
    canvas.drawPath(shape, Paint()..color = _sandRockTint);
  }

  void _drawBambooNodeRings(
    Canvas canvas,
    double x,
    double baseY,
    double height,
  ) {
    const nodeSpacing = 35.0;
    const stalkWidth = 3.0;
    var yy = baseY - nodeSpacing;
    final topY = baseY - height;
    while (yy > topY) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, yy), width: stalkWidth, height: 2),
        Paint()..color = _bambooDark.withValues(alpha: 0.85),
      );
      yy -= nodeSpacing;
    }
  }

  void _drawBambooLeaf(Canvas canvas, Offset origin, double dir, double scale) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(
        origin.dx + dir * 18 * scale,
        origin.dy - 8 * scale,
        origin.dx + dir * 28 * scale,
        origin.dy + 2 * scale,
      )
      ..quadraticBezierTo(
        origin.dx + dir * 14 * scale,
        origin.dy + 6 * scale,
        origin.dx,
        origin.dy,
      )
      ..close();
    ZenCartoonStyle.drawOutlinedPath(
      canvas,
      path,
      _bambooLeaf.withValues(alpha: 0.75),
      stroke: 1.2,
      strokeColor: _bambooDark.withValues(alpha: 0.4),
    );
  }

  void _drawLeftFence(Canvas canvas, Size size) {
    final span = size.height * 0.38;
    final top = size.height * 0.28;
    final left = size.width * 0.03;
    const poles = 5;
    for (var i = 0; i < poles; i++) {
      final y = top + (i / (poles - 1)) * span;
      final h = size.height * 0.09;
      const w = 3.0;
      final pole = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(left, y), width: w, height: h),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(pole, Paint()..color = _bamboo);
      _drawBambooNodeRings(canvas, left, y + h / 2, h);
    }
    for (var r = 0; r < 2; r++) {
      final yy = top + span * (0.25 + r * 0.45);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(left, yy), width: 14, height: 2.5),
          const Radius.circular(1),
        ),
        Paint()..color = _bambooDark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(left, yy), width: 14, height: 2.5),
          const Radius.circular(1),
        ),
        ZenCartoonStyle.outline(1.4),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(left, top + span + size.height * 0.025),
          width: 16,
          height: 3,
        ),
        const Radius.circular(1),
      ),
      Paint()..color = _wood.withValues(alpha: 0.55),
    );
  }

  void _drawCornerShrubs(Canvas canvas, Size size) {
    _drawShrubCluster(
      canvas,
      Offset(size.width * 0.1, size.height * 0.88),
      size.shortestSide * 0.09,
    );
  }

  void _drawShrubCluster(Canvas canvas, Offset center, double radius) {
    final clusters = <({Offset p, double r})>[];
    for (var i = 0; i < 4; i++) {
      final ang = i / 4 * math.pi * 2 + 0.4;
      final r = radius * (0.48 + _hash(i, 17) * 0.22);
      clusters.add((
        p: Offset(
          center.dx + math.cos(ang) * radius * 0.52,
          center.dy + math.sin(ang) * radius * 0.42,
        ),
        r: r,
      ));
    }

    for (final c in clusters) {
      final shadowBlob = Path()
        ..addOval(
          Rect.fromCenter(
            center: c.p + const Offset(0, 2),
            width: c.r * 2,
            height: c.r * 1.5,
          ),
        );
      canvas.drawPath(shadowBlob, Paint()..color = _shrubShadow.withValues(alpha: 0.45));
    }

    for (final c in clusters) {
      final blob = Path()
        ..addOval(Rect.fromCenter(center: c.p, width: c.r * 2, height: c.r * 1.5));
      canvas.drawPath(
        blob,
        Paint()
          ..shader = ui.Gradient.radial(
            c.p,
            c.r,
            [
              _shrubHi,
              _shrub,
            ],
          ),
      );
    }

    for (final c in clusters) {
      final blob = Path()
        ..addOval(Rect.fromCenter(center: c.p, width: c.r * 2, height: c.r * 1.5));
      canvas.drawPath(
        blob,
        Paint()
          ..color = _shrubOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _drawEdgeBoulders(Canvas canvas, Size size) {
    _drawMossBoulder(
      canvas,
      Offset(size.width * 0.94, size.height * 0.52),
      size.shortestSide * 0.11,
      0.15,
    );
    _drawMossBoulder(
      canvas,
      Offset(size.width * 0.88, size.height * 0.62),
      size.shortestSide * 0.08,
      -0.35,
    );
    _drawMossBoulder(
      canvas,
      Offset(size.width * 0.06, size.height * 0.48),
      size.shortestSide * 0.07,
      0.5,
    );
  }

  void _drawMossBoulder(Canvas canvas, Offset c, double scale, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(3, 5), width: scale * 2, height: scale),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    final rock = Path()
      ..moveTo(-scale * 0.9, scale * 0.35)
      ..cubicTo(
        -scale * 1.1,
        -scale * 0.35,
        -scale * 0.2,
        -scale * 0.65,
        scale * 0.25,
        -scale * 0.45,
      )
      ..cubicTo(
        scale * 0.95,
        -scale * 0.25,
        scale * 1.05,
        scale * 0.25,
        scale * 0.55,
        scale * 0.45,
      )
      ..cubicTo(
        scale * 0.1,
        scale * 0.65,
        -scale * 0.55,
        scale * 0.55,
        -scale * 0.9,
        scale * 0.35,
      )
      ..close();
    final bounds = rock.getBounds();
    canvas.drawPath(
      rock,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [_stoneHi, _stoneMid, _stoneLo],
          [0, 0.5, 1],
        ),
    );
    canvas.drawPath(rock, ZenCartoonStyle.outline(ZenCartoonStyle.outlineWidth));
    _drawSandTint(canvas, rock);
    ZenCartoonStyle.highlightSpot(canvas, Offset(-scale * 0.25, -scale * 0.2), scale * 0.10);
    final mossPatch = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(-scale * 0.15, -scale * 0.15),
        width: scale * 0.9,
        height: scale * 0.55,
      ));
    canvas.drawPath(
      mossPatch,
      Paint()..color = _moss,
    );
    canvas.drawPath(mossPatch, ZenCartoonStyle.outline(1.4));
    canvas.restore();
  }

  void _drawCenterBottomShrub(Canvas canvas, Size size) {
    _drawShrubCluster(
      canvas,
      Offset(size.width * 0.48, size.height * 0.9),
      size.shortestSide * 0.042,
    );
  }

  void _drawFlatRockCluster(Canvas canvas, Size size) {
    final anchor = Offset(size.width * 0.17, size.height * 0.83);
    final s = size.shortestSide * 0.052;
    _drawFlatRock(canvas, anchor + Offset(-s * 1.7, s * 0.25), s * 1.25, -0.1);
    _drawFlatRock(canvas, anchor + Offset(s * 0.25, s * 0.4), s * 1.5, 0.06);
    _drawFlatRock(canvas, anchor + Offset(s * 1.9, s * 0.18), s * 1.1, 0.2);
  }

  void _drawFlatRock(Canvas canvas, Offset c, double scale, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 4), width: scale * 2.4, height: scale * 0.55),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    final stone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: scale * 2.2, height: scale * 0.95),
      Radius.circular(scale * 0.18),
    );
    canvas.drawRRect(
      stone,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-scale, -scale * 0.2),
          Offset(scale, scale * 0.2),
          [_stoneHi, _stoneMid, _stoneLo],
          const [0.0, 0.45, 1.0],
        ),
    );
    _drawSandTint(canvas, Path()..addRRect(stone));
    canvas.drawRRect(stone, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));
    canvas.drawLine(
      Offset(-scale * 0.55, -scale * 0.18),
      Offset(scale * 0.2, -scale * 0.22),
      Paint()
        ..color = _stoneHi.withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawAccentStone(Canvas canvas, Offset c, double scale, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 3), width: scale * 2.2, height: scale * 1.1),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );
    final stone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: scale * 2, height: scale * 1.35),
      Radius.circular(scale * 0.25),
    );
    canvas.drawRRect(
      stone,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-scale, -scale),
          Offset(scale, scale),
          [_stoneHi, _stoneMid, _stoneLo],
          [0, 0.45, 1],
        ),
    );
    _drawSandTint(canvas, Path()..addRRect(stone));
    canvas.drawRRect(stone, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));
    canvas.drawLine(
      Offset(-scale * 0.35, -scale * 0.35),
      Offset(scale * 0.15, -scale * 0.4),
      Paint()
        ..color = _stoneHi.withValues(alpha: 0.32)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawSteppingStones(Canvas canvas, Size size) {
    const spacing = 80.0;
    const maxRot = 15 * math.pi / 180;

    final p0 = Offset(size.width * 0.06, size.height * 0.97);
    final p1 = Offset(size.width * 0.14, size.height * 0.84);
    final p2 = Offset(size.width * 0.32, size.height * 0.72);
    final p3 = Offset(size.width * 0.44, size.height * 0.54);

    final pathPts = _sampleCubic(p0, p1, p2, p3, 48);
    final cum = <double>[0.0];
    for (var i = 1; i < pathPts.length; i++) {
      cum.add(cum.last + (pathPts[i] - pathPts[i - 1]).distance);
    }
    final pathLen = cum.last;
    if (pathLen <= 0) return;

    var dist = 0.0;
    var stoneIndex = 0;
    while (dist <= pathLen) {
      final pt = _pointOnPolyline(pathPts, cum, dist);
      final s0 = (dist - 4).clamp(0.0, pathLen);
      final s1 = (dist + 4).clamp(0.0, pathLen);
      final back = _pointOnPolyline(pathPts, cum, s0);
      final ahead = _pointOnPolyline(pathPts, cum, s1);
      final tangent = math.atan2(ahead.dy - back.dy, ahead.dx - back.dx);
      final rot = tangent + (_hash(stoneIndex, 41) - 0.5) * 2 * maxRot;
      final slotW = 14 + _hash(stoneIndex, 7) * 6;
      final slotH = 8 + _hash(stoneIndex, 13) * 4;
      _drawDashedPlacementOval(canvas, pt, slotW, slotH, rot);
      dist += spacing;
      stoneIndex++;
    }
  }

  /// Subtle empty-slot hint — dashed oval perimeter only (no fill, no center mark).
  void _drawDashedPlacementOval(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final rect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
    final oval = Path()..addOval(rect);
    const dash = 4.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.butt;

    for (final metric in oval.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
    canvas.restore();
  }

  List<Offset> _sampleCubic(Offset p0, Offset p1, Offset p2, Offset p3, int steps) {
    final pts = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final u = 1 - t;
      pts.add(Offset(
        u * u * u * p0.dx +
            3 * u * u * t * p1.dx +
            3 * u * t * t * p2.dx +
            t * t * t * p3.dx,
        u * u * u * p0.dy +
            3 * u * u * t * p1.dy +
            3 * u * t * t * p2.dy +
            t * t * t * p3.dy,
      ));
    }
    return pts;
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

  void _drawBorderAccents(Canvas canvas, Size size) {
    final placements = <(double nx, double ny, double scale, double rot)>[
      (0.04, 0.22, 0.032, 0.1),
      (0.96, 0.28, 0.028, -0.25),
      (0.97, 0.78, 0.03, 0.4),
      (0.03, 0.68, 0.026, -0.15),
      (0.5, 0.04, 0.024, 0.0),
    ];
    for (final (nx, ny, sc, rot) in placements) {
      _drawAccentStone(
        canvas,
        Offset(size.width * nx, size.height * ny),
        size.shortestSide * sc,
        rot,
      );
    }
  }

  double _hash(int a, int b) {
    var h = a * 374761393 + b * 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h & 0xFFFFFF) / 0x1000000;
  }

  @override
  bool shouldRepaint(covariant ZenGardenStaticSceneryPainter oldDelegate) {
    return oldDelegate.palette.midTone != palette.midTone;
  }
}
