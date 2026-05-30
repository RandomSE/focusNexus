import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';

import 'zen_garden_cartoon_style.dart';
import 'zen_placeable_layout.dart';

math.Random _decorRng(String kind, String id, int st) =>
    math.Random(kind.hashCode ^ id.hashCode ^ (st * 9176));

bool _mutated(MutationKind? m) => m == MutationKind.invertedColors;

Offset _cubicPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final u = 1 - t;
  return Offset(
    u * u * u * p0.dx + 3 * u * u * t * p1.dx + 3 * u * t * t * p2.dx + t * t * t * p3.dx,
    u * u * u * p0.dy + 3 * u * u * t * p1.dy + 3 * u * t * t * p2.dy + t * t * t * p3.dy,
  );
}

void _drawKoi(
  Canvas canvas,
  Offset center,
  double angle,
  double scale,
  Color body,
  Color accent,
  Color edge, {
  bool metallic = false,
}) {
  const minBodyLen = 12.0;
  const refBodyLen = 16.0;
  final s = math.max(scale, minBodyLen / refBodyLen);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);

  final torso = Path()
    ..moveTo(9 * s, 0)
    ..quadraticBezierTo(11 * s, -4.5 * s, 6 * s, -4 * s)
    ..quadraticBezierTo(1 * s, -3.5 * s, -2 * s, -2.5 * s)
    ..lineTo(-5 * s, -3.5 * s)
    ..quadraticBezierTo(-3 * s, 0, -5 * s, 3.5 * s)
    ..lineTo(-2 * s, 2.5 * s)
    ..quadraticBezierTo(1 * s, 3.5 * s, 6 * s, 4 * s)
    ..quadraticBezierTo(11 * s, 4.5 * s, 9 * s, 0)
    ..close();
  canvas.drawPath(torso, Paint()..color = body);
  if (metallic) {
    final bounds = Rect.fromCenter(
      center: Offset(2 * s, 0),
      width: 20 * s,
      height: 10 * s,
    );
    canvas.drawPath(
      torso,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1.1, -0.85),
          end: const Alignment(1.0, 0.9),
          colors: [
            Colors.white.withValues(alpha: 0.62),
            body.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.48),
          ],
          stops: const [0.0, 0.38, 0.58, 1.0],
        ).createShader(bounds),
    );
  }
  canvas.drawPath(torso, ZenCartoonStyle.outline(1.4, edge));

  final tail = Path()
    ..moveTo(-5 * s, 0)
    ..lineTo(-13 * s, -7 * s)
    ..lineTo(-9 * s, 0)
    ..lineTo(-13 * s, 7 * s)
    ..close();
  canvas.drawPath(tail, Paint()..color = body);
  canvas.drawPath(tail, ZenCartoonStyle.outline(1.4, edge));

  canvas.drawOval(
    Rect.fromCenter(center: Offset(3 * s, -1.5 * s), width: 7 * s, height: 5 * s),
    Paint()..color = accent,
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(3 * s, -1.5 * s), width: 7 * s, height: 5 * s),
    ZenCartoonStyle.outline(1.0, edge.withValues(alpha: 0.5)),
  );
  canvas.drawCircle(Offset(7.5 * s, -1.2 * s), 1.8 * s, Paint()..color = Colors.white);
  canvas.drawCircle(Offset(7.8 * s, -1.2 * s), 1.0 * s, Paint()..color = edge);
  canvas.restore();
}

/// Keeps koi bodies inside the organic pond (elliptical inset from rim).
Offset _clampKoiInsidePond(
  Offset pos,
  Offset center,
  double pondW,
  double pondH, {
  double bodyRadius = 11,
}) {
  final maxRx = math.max(4.0, pondW * 0.36 - bodyRadius);
  final maxRy = math.max(4.0, pondH * 0.30 - bodyRadius);
  final dx = pos.dx - center.dx;
  final dy = pos.dy - center.dy;
  final nx = dx / maxRx;
  final ny = dy / maxRy;
  final distSq = nx * nx + ny * ny;
  if (distSq <= 1.0) return pos;
  final inv = 1.0 / math.sqrt(distSq);
  return Offset(center.dx + nx * inv * maxRx, center.dy + ny * inv * maxRy);
}

double _koiFishScaleForStage(int stageIndex) {
  return switch (stageIndex.clamp(0, 4)) {
    0 => 0.88,
    1 => 0.85,
    2 => 0.82,
    3 => 0.80,
    _ => 0.78,
  };
}

/// Per-fish palette — stable for a given pond, fish index, and mutation state.
({Color body, Color accent, Color edge}) koiFishColors({
  required int fishIndex,
  required String pondId,
  required int stageIndex,
  required bool mutated,
}) {
  final rng = _decorRng('koiColor', pondId, stageIndex * 17 + fishIndex);
  if (mutated) {
    final palette = <(Color, Color, Color)>[
      (const Color(0xFF4A7FD4), const Color(0xFFD6E8FF), const Color(0xFF1E3354)),
      (const Color(0xFFF3EADB), const Color(0xFFFFFBF5), const Color(0xFF8A7968)),
      (const Color(0xFF6D4C41), const Color(0xFFD7CCC8), const Color(0xFF3E2723)),
      (const Color(0xFFCFB53B), const Color(0xFFFFF8E1), const Color(0xFF6D5B3A)),
      (const Color(0xFF90A4AE), const Color(0xFFECEFF1), const Color(0xFF455A64)),
    ];
    final pick = palette[rng.nextInt(palette.length)];
    return (body: pick.$1, accent: pick.$2, edge: pick.$3);
  }
  final palette = <(Color, Color, Color)>[
    (const Color(0xFFF5F5F5), const Color(0xFFE8E8E8), const Color(0xFF616161)),
    (const Color(0xFF212121), const Color(0xFF424242), const Color(0xFF000000)),
    (const Color(0xFFC62828), const Color(0xFFFFCDD2), const Color(0xFF4E342E)),
    (const Color(0xFFE65100), const Color(0xFFFFE0B2), const Color(0xFF4E342E)),
    (const Color(0xFFF9A825), const Color(0xFFFFF9C4), const Color(0xFF5D4037)),
  ];
  final pick = palette[rng.nextInt(palette.length)];
  return (body: pick.$1, accent: pick.$2, edge: pick.$3);
}

void _drawMiniLantern(Canvas canvas, Offset c, {bool mutated = false}) {
  final stone = mutated ? const Color(0xFF2A2A2A) : const Color(0xFF9E9E9E);
  final glow = mutated ? const Color(0xFFB8D4FF) : const Color(0xFFFFE082);
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, 8), width: 10, height: 3), const Radius.circular(1)),
    Paint()..color = stone,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, 3), width: 4, height: 8), const Radius.circular(1)),
    Paint()..color = stone,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, -3), width: 8, height: 8), const Radius.circular(1)),
    Paint()..color = stone.withValues(alpha: 0.9),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, -3), width: 5, height: 5), const Radius.circular(1)),
    Paint()..color = glow.withValues(alpha: 0.85),
  );
  final roof = Path()
    ..moveTo(c.dx, c.dy - 10)
    ..lineTo(c.dx - 6, c.dy - 5)
    ..lineTo(c.dx + 6, c.dy - 5)
    ..close();
  canvas.drawPath(roof, Paint()..color = stone);
}

void _drawGrassTuft(Canvas canvas, Offset p) {
  for (var i = -1.0; i <= 1.0; i++) {
    canvas.drawLine(
      p,
      p + Offset(i * 3, -7),
      Paint()
        ..color = const Color(0xFF5A9A48)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }
}

void _drawFernFrond(Canvas canvas, Offset base, {Color color = const Color(0xFF4A8040)}) {
  final path = Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(base.dx + 4, base.dy - 8, base.dx + 10, base.dy - 14)
    ..quadraticBezierTo(base.dx + 6, base.dy - 10, base.dx + 2, base.dy - 4);
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
}

Path _bumpyMossSilhouette(Offset center, double rx, double ry, {double seed = 0}) {
  const steps = 18;
  final path = Path();
  for (var i = 0; i <= steps; i++) {
    final ang = -math.pi + (i / steps) * math.pi * 1.15;
    final bump = 1 + 0.14 * math.sin(ang * 5.5 + seed);
    final p = Offset(
      center.dx + math.cos(ang) * rx * bump,
      center.dy + math.sin(ang) * ry * bump,
    );
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

void _drawWisteriaCluster(Canvas canvas, Offset onBeam, Color color, {double dropLen = 10}) {
  final drop = onBeam + Offset(0, dropLen);
  canvas.drawLine(
    onBeam,
    drop,
    Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.4,
  );
  const dotCount = 7;
  for (var d = 0; d < dotCount; d++) {
    final dot = drop + Offset((d - (dotCount - 1) / 2) * 4.2, 2 + d * 2.6);
    canvas.drawOval(
      Rect.fromCenter(center: dot, width: 6, height: 6),
      Paint()..color = color.withValues(alpha: 0.92),
    );
  }
}

void _drawRockSpecular(Canvas canvas, Offset c, double sc) {
  canvas.drawCircle(
    Offset(c.dx - 6 * sc, c.dy - 4 * sc),
    3,
    Paint()..color = Colors.white.withValues(alpha: 0.4),
  );
}

void _drawRockFlower(Canvas canvas, Offset center, Color petalColor, {bool prominent = false}) {
  if (prominent) {
    canvas.drawCircle(center, 2, Paint()..color = petalColor);
    for (var i = 0; i < 6; i++) {
      final ang = i / 6 * math.pi * 2;
      final petal = Rect.fromCenter(
        center: center + Offset(math.cos(ang) * 7, math.sin(ang) * 7),
        width: 5,
        height: 3.5,
      );
      canvas.drawOval(petal, Paint()..color = petalColor.withValues(alpha: 0.95));
    }
    return;
  }
  canvas.drawCircle(center, 2.5, Paint()..color = petalColor);
  for (var i = 0; i < 4; i++) {
    final ang = i / 4 * math.pi * 2;
    final petal = Rect.fromCenter(
      center: center + Offset(math.cos(ang) * 4, math.sin(ang) * 4),
      width: 4,
      height: 2.5,
    );
    canvas.drawOval(petal, Paint()..color = petalColor.withValues(alpha: 0.9));
  }
}

/// Single S-curve path shared by all stepping-stone stages.
(Offset, Offset, Offset, Offset) _steppingStonePath(Size size) {
  final p0 = Offset(size.width * 0.04, size.height * 0.94);
  final p1 = Offset(size.width * 0.30, size.height * 0.76);
  final p2 = Offset(size.width * 0.56, size.height * 0.50);
  final p3 = Offset(size.width * 0.84, size.height * 0.20);
  return (p0, p1, p2, p3);
}

List<Offset> _sampleCubic(Offset p0, Offset p1, Offset p2, Offset p3, {int steps = 64}) {
  final pts = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    pts.add(_cubicPoint(p0, p1, p2, p3, i / steps));
  }
  return pts;
}

List<double> _cumulativeLengths(List<Offset> pts) {
  final cum = <double>[0.0];
  for (var i = 1; i < pts.length; i++) {
    cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
  }
  return cum;
}

Offset _pointOnSampledCurve(List<Offset> pts, List<double> cum, double s) {
  if (s <= 0) return pts.first;
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

double _tangentAngle(List<Offset> pts, List<double> cum, double s) {
  const delta = 3.0;
  final s0 = (s - delta).clamp(0.0, cum.last);
  final s1 = (s + delta).clamp(0.0, cum.last);
  final a = _pointOnSampledCurve(pts, cum, s0);
  final b = _pointOnSampledCurve(pts, cum, s1);
  return math.atan2(b.dy - a.dy, b.dx - a.dx);
}

double _pathStartTangentAngle(Offset p0, Offset p1, Offset p2, Offset p3) {
  final pts = _sampleCubic(p0, p1, p2, p3);
  final cum = _cumulativeLengths(pts);
  return _tangentAngle(pts, cum, cum.last * 0.04);
}

List<(Offset, double)> _steppingStoneArcPlacements(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
  int count,
  String id, {
  bool arcStartPair = false,
  bool lockPathAngle = false,
}) {
  const baseW = 16.0;
  const maxGap = baseW * 1.5;
  final pts = _sampleCubic(p0, p1, p2, p3);
  final cum = _cumulativeLengths(pts);
  final total = cum.last;
  final placements = <(Offset, double)>[];
  final pathAng = lockPathAngle ? _pathStartTangentAngle(p0, p1, p2, p3) : null;

  if (arcStartPair && count == 2) {
    const pairStep = 22.0;
    final startS = total * 0.04;
    final ang = pathAng ?? _tangentAngle(pts, cum, startS);
    final startPt = _pointOnSampledCurve(pts, cum, startS);
    final along = Offset(math.cos(ang), math.sin(ang));
    placements.add((startPt, ang));
    placements.add((startPt + along * pairStep, ang));
    return placements;
  }

  if (count <= 1) {
    final s = total * 0.5;
    placements.add((_pointOnSampledCurve(pts, cum, s), _tangentAngle(pts, cum, s)));
    return placements;
  }

  var startS = total * 0.04;
  final endS = total * 0.94;
  var step = (endS - startS) / (count - 1);
  if (step > maxGap) {
    step = maxGap;
    startS = endS - step * (count - 1);
    startS = startS.clamp(0.0, total * 0.04);
  }

  for (var i = 0; i < count; i++) {
    final s = startS + i * step;
    final ang = pathAng ??
        (_tangentAngle(pts, cum, s) +
            (_decorRng('sp', id, i).nextDouble() - 0.5) * 0.14);
    placements.add((_pointOnSampledCurve(pts, cum, s), ang));
  }
  return placements;
}

(double, double) _stoneDimensions(int index, String id) {
  final r = _decorRng('spshape', id, index).nextDouble();
  if (r < 0.35) return (18, 12);
  if (r < 0.7) return (20, 13);
  return (22, 14);
}

List<(Offset, double)> _stonePathPlacements(DecorItem item, Size canvasSize) {
  final st = item.stageIndex.clamp(0, 4);
  const stoneCounts = [2, 4, 6, 8, 10];
  final count = stoneCounts[st];
  final (p0, p1, p2, p3) = _steppingStonePath(canvasSize);
  return _steppingStoneArcPlacements(
    p0,
    p1,
    p2,
    p3,
    count,
    item.id,
    arcStartPair: st == 0,
    lockPathAngle: st <= 1,
  );
}

/// Tap position in decor paint-canvas pixels (origin = top-left of paint layer).
Offset zenDecorPaintLocalFromNorm(
  double nx,
  double ny,
  DecorItem item,
  Size gardenSize,
) {
  final canvas = zenDecorPaintCanvasSize(item);
  final decorCenter = Offset(
    item.positionX * gardenSize.width,
    item.positionY * gardenSize.height,
  );
  final widgetTL = decorCenter -
      const Offset(zenDecorSlotWidth / 2, zenDecorSlotHeight / 2);
  final paintTL = widgetTL +
      Offset(
        (zenDecorSlotWidth - canvas.width) / 2,
        zenDecorSlotHeight - zenDecorPaintBottomInset - canvas.height,
      );
  return Offset(nx * gardenSize.width, ny * gardenSize.height) - paintTL;
}

Offset zenDecorPaintNormFromLocal(
  Offset localPx,
  DecorItem item,
  Size gardenSize,
) {
  final canvas = zenDecorPaintCanvasSize(item);
  final decorCenter = Offset(
    item.positionX * gardenSize.width,
    item.positionY * gardenSize.height,
  );
  final widgetTL = decorCenter -
      const Offset(zenDecorSlotWidth / 2, zenDecorSlotHeight / 2);
  final paintTL = widgetTL +
      Offset(
        (zenDecorSlotWidth - canvas.width) / 2,
        zenDecorSlotHeight - zenDecorPaintBottomInset - canvas.height,
      );
  final gardenPx = paintTL + localPx;
  return Offset(
    gardenPx.dx / gardenSize.width,
    gardenPx.dy / gardenSize.height,
  );
}

/// Norm positions of each stepping-stone center (paint order).
List<Offset> zenStonePathStoneCentersNorm(DecorItem item, Size gardenSize) {
  final canvas = zenDecorPaintCanvasSize(item);
  final placements = _stonePathPlacements(
    item,
    Size(canvas.width, canvas.height),
  );
  return [
    for (final (pt, _) in placements)
      zenDecorPaintNormFromLocal(pt, item, gardenSize),
  ];
}

bool _pointInRotatedStonePx(
  Offset localPx,
  Offset stoneCenter,
  double angle,
  double width,
  double height, {
  double pad = 5,
}) {
  final dx = localPx.dx - stoneCenter.dx;
  final dy = localPx.dy - stoneCenter.dy;
  final cos = math.cos(-angle);
  final sin = math.sin(-angle);
  final lx = dx * cos - dy * sin;
  final ly = dx * sin + dy * cos;
  return lx.abs() <= width / 2 + pad && ly.abs() <= height / 2 + pad;
}

/// True when [nx, ny] hits an individual stepping stone (all stages).
bool zenStonePathHitNorm(
  double nx,
  double ny,
  DecorItem item,
  Size gardenSize,
) {
  if (item.kind != 'zen.stone_path') return false;
  final canvas = zenDecorPaintCanvasSize(item);
  final local = zenDecorPaintLocalFromNorm(nx, ny, item, gardenSize);
  final placements = _stonePathPlacements(
    item,
    Size(canvas.width, canvas.height),
  );
  for (var i = 0; i < placements.length; i++) {
    final (pt, ang) = placements[i];
    final (pw, ph) = _stoneDimensions(i, item.id);
    if (_pointInRotatedStonePx(local, pt, ang, pw, ph)) {
      return true;
    }
  }
  return false;
}

/// Norm-space bounds covering every stone (for box selection / pick distance).
Rect zenStonePathUnionNormRect(DecorItem item, Size gardenSize) {
  final canvas = zenDecorPaintCanvasSize(item);
  final decorCenter = Offset(
    item.positionX * gardenSize.width,
    item.positionY * gardenSize.height,
  );
  final widgetTL = decorCenter -
      const Offset(zenDecorSlotWidth / 2, zenDecorSlotHeight / 2);
  final paintOrigin = widgetTL +
      Offset(
        (zenDecorSlotWidth - canvas.width) / 2,
        zenDecorSlotHeight - zenDecorPaintBottomInset - canvas.height,
      );

  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  final placements = _stonePathPlacements(
    item,
    Size(canvas.width, canvas.height),
  );
  for (var i = 0; i < placements.length; i++) {
    final (pt, ang) = placements[i];
    final (pw, ph) = _stoneDimensions(i, item.id);
    const pad = 5.0;
    for (final corner in [
      Offset(-pw / 2 - pad, -ph / 2 - pad),
      Offset(pw / 2 + pad, -ph / 2 - pad),
      Offset(pw / 2 + pad, ph / 2 + pad),
      Offset(-pw / 2 - pad, ph / 2 + pad),
    ]) {
      final cos = math.cos(ang);
      final sin = math.sin(ang);
      final wx = paintOrigin.dx + pt.dx + corner.dx * cos - corner.dy * sin;
      final wy = paintOrigin.dy + pt.dy + corner.dx * sin + corner.dy * cos;
      minX = math.min(minX, wx);
      minY = math.min(minY, wy);
      maxX = math.max(maxX, wx);
      maxY = math.max(maxY, wy);
    }
  }
  return Rect.fromLTRB(
    minX / gardenSize.width,
    minY / gardenSize.height,
    maxX / gardenSize.width,
    maxY / gardenSize.height,
  );
}

/// Elapsed seconds from a repeating controller — monotonic, never wraps to zero.
double zenDecorAnimElapsedSeconds(AnimationController? controller) {
  if (controller == null) return 0;
  return (controller.lastElapsedDuration?.inMicroseconds ?? 0) / 1000000.0;
}

/// Computes a smooth pond wander position for one koi at [elapsedSeconds].
({Offset position, double angle}) koiWanderAt({
  required Offset pondCenter,
  required double pondW,
  required double pondH,
  required int fishIndex,
  required String pondId,
  required int stageIndex,
  required double elapsedSeconds,
}) {
  final rng = _decorRng('koiWander', pondId, stageIndex * 31 + fishIndex);
  final seed = rng.nextDouble() * math.pi * 2;
  // Per-fish speed multiplier in [0.5, 2.0×] on top of base swim rate.
  final speedMul = 0.5 + rng.nextDouble() * 1.5;
  final baseSwimRate = 0.45 + rng.nextDouble() * 0.35;
  final swimRate = baseSwimRate * speedMul;
  final t = elapsedSeconds * swimRate + seed;
  // Amplitudes kept modest so Lissajous sum stays inside the pond ellipse.
  final ax = 0.14 + rng.nextDouble() * 0.10;
  final ay = 0.13 + rng.nextDouble() * 0.09;
  final fx1 = 1.0 + rng.nextDouble() * 0.55;
  final fx2 = 0.55 + rng.nextDouble() * 0.35;
  final fy1 = 0.85 + rng.nextDouble() * 0.45;
  final fy2 = 0.45 + rng.nextDouble() * 0.30;
  final px = pondCenter.dx +
      math.sin(t * fx1) * pondW * ax +
      math.sin(t * fx2 + fishIndex * 0.9) * pondW * ax * 0.34;
  final py = pondCenter.dy +
      math.cos(t * fy1 + seed * 0.3) * pondH * ay +
      math.cos(t * fy2 + fishIndex * 0.6) * pondH * ay * 0.30;
  const dt = 0.05;
  final t2 = t + dt * swimRate;
  final px2 = pondCenter.dx +
      math.sin(t2 * fx1) * pondW * ax +
      math.sin(t2 * fx2 + fishIndex * 0.9) * pondW * ax * 0.34;
  final py2 = pondCenter.dy +
      math.cos(t2 * fy1 + seed * 0.3) * pondH * ay +
      math.cos(t2 * fy2 + fishIndex * 0.6) * pondH * ay * 0.30;
  final pos = _clampKoiInsidePond(
    Offset(px, py),
    pondCenter,
    pondW,
    pondH,
  );
  final pos2 = _clampKoiInsidePond(
    Offset(px2, py2),
    pondCenter,
    pondW,
    pondH,
  );
  var velDx = pos2.dx - pos.dx;
  var velDy = pos2.dy - pos.dy;
  if (velDx * velDx + velDy * velDy < 0.04) {
    velDx = px2 - px;
    velDy = py2 - py;
  }
  final ang = math.atan2(velDy, velDx);
  return (position: pos, angle: ang);
}

/// Stage-aware decor rendering for all zen placeables.
abstract final class ZenGardenDecorPainter {
  static void paint({
    required Canvas canvas,
    required Size size,
    required DecorItem item,
    required Color primary,
    required Color secondary,
    double animPhase = 0,
  }) {
    final c = Offset(size.width / 2, size.height / 2);
    final st = item.stageIndex.clamp(0, 4);
    final m = item.mutation;

    switch (item.kind) {
      case 'zen.stone_path':
        _paintStonePath(canvas, size, c, st, m, item.id);
      case 'zen.koi_pond':
        _paintKoiPond(canvas, size, c, st, m, item.id, animPhase);
      case 'zen.stone_lantern':
        _paintStoneLantern(canvas, size, c, st, m, animPhase);
      case 'zen.wood_bench':
        _paintWoodBench(canvas, size, c, st, m);
      case 'zen.bamboo_fence':
        _paintBambooFence(canvas, size, c, st, m, item.id);
      case 'zen.moss_rock':
        _paintMossRock(canvas, size, c, st, m, item.id);
      default:
        _paintFallbackRock(canvas, c, st);
    }
  }

  static void _paintStonePath(
    Canvas canvas,
    Size size,
    Offset c,
    int st,
    MutationKind? m,
    String id,
  ) {
    final mutated = _mutated(m);
    final stoneCounts = [2, 4, 6, 8, 10];
    final count = stoneCounts[st];
    final (p0, p1, p2, p3) = _steppingStonePath(size);
    final placements = _steppingStoneArcPlacements(
      p0,
      p1,
      p2,
      p3,
      count,
      id,
      arcStartPair: st == 0,
      lockPathAngle: st <= 1,
    );

    for (var i = 0; i < placements.length; i++) {
      final (pt, ang) = placements[i];
      if (st >= 4 && i.isOdd) {
        _drawGrassTuft(canvas, pt + const Offset(0, 6));
      }
      canvas.save();
      canvas.translate(pt.dx, pt.dy);
      canvas.rotate(ang);
      final (pw, ph) = _stoneDimensions(i, id);
      const stoneCornerR = Radius.circular(5);
      final stoneRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: pw, height: ph),
        stoneCornerR,
      );
      final light = mutated ? const Color(0xFF3A4550) : const Color(0xFFD2CEC6);
      final mid = mutated ? const Color(0xFF2A3238) : const Color(0xFFA8A098);
      final dark = mutated ? const Color(0xFF1A2028) : const Color(0xFF6F6A62);
      canvas.drawRRect(
        stoneRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [light, mid, dark],
          ).createShader(Rect.fromCenter(center: Offset.zero, width: pw, height: ph)),
      );
      if (st == 1) {
        canvas.drawRRect(
          stoneRect,
          Paint()..color = const Color(0xFF8CB878).withValues(alpha: 0.10),
        );
      } else if (st == 2) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, -ph * 0.22), width: pw * 0.85, height: ph * 0.38),
            stoneCornerR,
          ),
          Paint()..color = const Color(0xFF5A8A48).withValues(alpha: 0.55),
        );
      } else if (st == 3) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(0, -1), width: pw * 0.9, height: ph * 0.55),
            stoneCornerR,
          ),
          Paint()..color = const Color(0xFF4A7A42).withValues(alpha: 0.5),
        );
      } else if (st >= 4) {
        final mossPatch = _bumpyMossSilhouette(
          Offset(0, -ph * 0.12),
          pw * 0.48,
          ph * 0.42,
          seed: i * 1.7,
        );
        canvas.drawPath(
          mossPatch,
          Paint()..color = const Color(0xFF4A7A42).withValues(alpha: st >= 4 ? 0.65 : 0.45),
        );
      }
      if (mutated) {
        canvas.drawRRect(
          stoneRect,
          Paint()
            ..color = const Color(0xFFB8D8FF).withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      } else {
        canvas.drawRRect(stoneRect, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));
      }
      canvas.restore();
    }

    if (st >= 4) {
      final end = _cubicPoint(p0, p1, p2, p3, 0.94);
      _drawMiniLantern(canvas, end + const Offset(0, -12), mutated: mutated);
    }
  }

  static Path _organicPondPath(Offset c, double w, double h) {
    return Path()
      ..moveTo(c.dx - w * 0.48, c.dy + h * 0.12)
      ..quadraticBezierTo(c.dx - w * 0.52, c.dy - h * 0.35, c.dx - w * 0.08, c.dy - h * 0.42)
      ..quadraticBezierTo(c.dx + w * 0.18, c.dy - h * 0.48, c.dx + w * 0.46, c.dy - h * 0.18)
      ..quadraticBezierTo(c.dx + w * 0.52, c.dy + h * 0.22, c.dx + w * 0.12, c.dy + h * 0.38)
      ..quadraticBezierTo(c.dx - w * 0.28, c.dy + h * 0.44, c.dx - w * 0.48, c.dy + h * 0.12)
      ..close();
  }

  static void _paintKoiPond(
    Canvas canvas,
    Size size,
    Offset c,
    int st,
    MutationKind? m,
    String id,
    double animPhase,
  ) {
    final mutated = _mutated(m);
    var pondW = zenKoiPondFitWidth(st, size.width, canvasHeight: size.height);
    if (st == 0) {
      pondW = math.max(pondW, 72.0);
    }
    final pondH = pondW * 0.58;
    final pond = _organicPondPath(c, pondW, pondH);
    final bounds = pond.getBounds();

    final waterLite = mutated ? const Color(0xFF1A2848) : const Color(0xFFB8DFF0);
    final waterMid = mutated ? const Color(0xFF0F1830) : const Color(0xFF6AADD4);
    final waterDeep = mutated ? const Color(0xFF080810) : const Color(0xFF3D7AA8);

    canvas.drawPath(
      pond,
      Paint()..color = waterLite.withValues(alpha: mutated ? 1.0 : 0.95),
    );
    canvas.drawPath(
      pond,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [waterLite, waterMid, waterDeep],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );

    if (st >= 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx - pondW * 0.22, c.dy - pondH * 0.18),
          width: pondW * 0.22,
          height: pondH * 0.14,
        ),
        Paint()..color = Colors.white.withValues(alpha: mutated ? 0.08 : 0.35),
      );
    }

    if (st >= 2) {
      canvas.save();
      canvas.clipPath(pond);
      canvas.drawPath(
        pond,
        Paint()
          ..color = (mutated ? const Color(0xFF000008) : const Color(0xFF1A4060)).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
      canvas.restore();
    }

    canvas.drawPath(
      pond,
      ZenCartoonStyle.outline(st == 0 ? 2.0 : ZenCartoonStyle.outlineThin),
    );

    final padColor = mutated ? const Color(0xFFE8B8C8) : const Color(0xFF4A8A48);
    final padCount = st >= 4 ? 3 : (st >= 1 ? (st == 1 ? 1 : 2) : 0);
    final rnd = _decorRng('koi', id, st);
    for (var i = 0; i < padCount; i++) {
      final a = i / math.max(1, padCount) * math.pi * 1.4 - 0.8 + rnd.nextDouble() * 0.3;
      final lp = Offset(c.dx + math.cos(a) * pondW * 0.28, c.dy + math.sin(a) * pondH * 0.22);
      canvas.drawOval(
        Rect.fromCenter(center: lp, width: 14, height: 10),
        Paint()..color = padColor,
      );
      canvas.drawOval(Rect.fromCenter(center: lp, width: 14, height: 10), ZenCartoonStyle.outline(1.4));
      if (st >= 2) {
        canvas.drawCircle(lp + const Offset(2, -2), 2.2, Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
    }

    if (st >= 4) {
      final bridgeY = c.dy + pondH * 0.05;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, bridgeY), width: pondW * 0.55, height: 5),
          const Radius.circular(2),
        ),
        Paint()..color = mutated ? const Color(0xFF2A2A2A) : const Color(0xFF8B6914),
      );
      for (final dx in [-pondW * 0.22, pondW * 0.22]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(c.dx + dx, bridgeY + 4), width: 4, height: 8),
            const Radius.circular(1),
          ),
          Paint()..color = const Color(0xFF6D4C41),
        );
      }
    }

    final fishRnd = _decorRng('koiFish', id, st);
    final fishCount = switch (st) {
      0 => 1,
      1 => 2,
      2 => 2,
      3 => 3 + fishRnd.nextInt(2),
      _ => 5,
    };
    canvas.save();
    canvas.clipPath(pond);
    for (var i = 0; i < fishCount; i++) {
      final wander = koiWanderAt(
        pondCenter: c,
        pondW: pondW,
        pondH: pondH,
        fishIndex: i,
        pondId: id,
        stageIndex: st,
        elapsedSeconds: animPhase,
      );
      final pos = wander.position;
      final ang = wander.angle;
      final colors = koiFishColors(
        fishIndex: i,
        pondId: id,
        stageIndex: st,
        mutated: mutated,
      );

      if (st >= 3) {
        final rippleT = (animPhase * 0.18 + i * 0.41) % 1.0;
        final rippleR = (4 + rippleT * 10).clamp(4.0, pondW * 0.12);
        canvas.drawCircle(
          pos,
          rippleR,
          Paint()
            ..color = Colors.white.withValues(alpha: (1 - rippleT) * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }

      _drawKoi(
        canvas,
        pos,
        ang,
        _koiFishScaleForStage(st),
        colors.body,
        colors.accent,
        colors.edge.withValues(alpha: 0.65),
        metallic: mutated,
      );
    }
    canvas.restore();
  }

  static Color _lanternWindowColor(int st, bool mutated) {
    if (mutated) return const Color(0xFFB8D4FF);
    return switch (st) {
      1 => const Color(0xFFD4A843),
      2 => const Color(0xFFFFD166),
      3 => const Color(0xFFFFB347),
      4 => const Color(0xFFFFA500),
      _ => const Color(0xFF4A4A4A),
    };
  }

  static void _drawLanternGroundGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    final glowRect = Rect.fromCenter(
      center: center,
      width: radius * 2.4,
      height: radius * 1.35,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(glowRect),
    );
  }

  static void _paintStoneLantern(
    Canvas canvas,
    Size size,
    Offset c,
    int st,
    MutationKind? m,
    double animPhase,
  ) {
    final mutated = _mutated(m);

    final stone = mutated ? const Color(0xFF2A2A2A) : const Color(0xFF9E9E9E);
    final stoneHi = mutated ? const Color(0xFF3A3A3A) : const Color(0xFFC4C4C4);
    final stoneLo = mutated ? const Color(0xFF1A1A1A) : const Color(0xFF6D6D6D);
    final windowGlow = _lanternWindowColor(st, mutated);
    final base = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, 21), width: 34, height: 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(base, Paint()..color = stoneLo);
    canvas.drawRRect(base, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));

    final post = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, 8), width: 10, height: 18),
      const Radius.circular(2),
    );
    canvas.drawRRect(post, Paint()..color = stone);
    canvas.drawRRect(post, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));

    if (st >= 2) {
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(0, 8), width: 14, height: 5),
        Paint()
          ..color = stoneLo.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, -7), width: 24, height: 20),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, Paint()..color = stoneHi);
    canvas.drawRRect(bodyRect, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));

    final win = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(0, -7), width: 14, height: 12),
      const Radius.circular(2),
    );
    if (st >= 1) {
      canvas.drawRRect(win, Paint()..color = windowGlow.withValues(alpha: st == 1 ? 0.82 : 0.95));
    } else {
      canvas.drawRRect(win, Paint()..color = const Color(0xFF4A4A4A));
    }
    canvas.drawRRect(win, ZenCartoonStyle.outline(1.4));

    final roof = Path()
      ..moveTo(c.dx, c.dy - 25)
      ..lineTo(c.dx - 14, c.dy - 13)
      ..lineTo(c.dx + 14, c.dy - 13)
      ..close();
    canvas.drawPath(roof, Paint()..color = stone);
    canvas.drawPath(roof, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));

    if (st >= 4) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, -28), width: 5, height: 7),
          const Radius.circular(2),
        ),
        Paint()..color = stone,
      );
    }
  }

  static void _paintLanternSandGlow(
    Canvas canvas,
    Size size,
    int st,
    bool mutated,
    double animPhase,
  ) {
    if (st < 2) return;
    final poolCenter = Offset(size.width / 2, size.height * 0.42);
    final poolColor = mutated ? const Color(0xFFB8D4FF) : _lanternWindowColor(st, false);

    switch (st) {
      case 2:
        _drawLanternGroundGlow(canvas, poolCenter, 25, poolColor, 0.25);
      case 3:
        _drawLanternGroundGlow(canvas, poolCenter, 38, poolColor, 0.30);
      case 4:
        var innerRadius = 50.0;
        if (!mutated) {
          innerRadius = ui.lerpDouble(
            innerRadius * 0.94,
            innerRadius,
            0.5 + 0.5 * math.sin(animPhase * 0.9),
          )!;
        }
        _drawLanternGroundGlow(canvas, poolCenter, innerRadius, poolColor, 0.32);
        _drawLanternGroundGlow(canvas, poolCenter, 70, poolColor, 0.10);
      default:
        break;
    }
  }

  /// Sand-surface glow drawn beneath the lantern body (wide canvas, sand-aligned).
  static void paintLanternSandGlowLayer(Canvas canvas, Size size, DecorItem item, double animPhase) {
    if (item.kind != 'zen.stone_lantern') return;
    final st = item.stageIndex.clamp(0, 4);
    if (st < 2) return;
    _paintLanternSandGlow(canvas, size, st, _mutated(item.mutation), animPhase);
  }

  static Size lanternSandGlowSize(int stageIndex) {
    final st = stageIndex.clamp(0, 4);
    if (st < 2) return Size.zero;
    final outerRadius = switch (st) {
      2 => 25.0,
      3 => 38.0,
      _ => 70.0,
    };
    return Size(math.min(outerRadius * 2.5, 150), math.min(outerRadius * 1.15, 50));
  }

  static void _paintWoodBench(Canvas canvas, Size size, Offset c, int st, MutationKind? m) {
    final mutated = _mutated(m);
    final wood = mutated ? const Color(0xFF1A1A1A) : const Color(0xFF8B5E3C);
    final woodHi = mutated ? const Color(0xFF2E2E2E) : const Color(0xFFA67C5A);
    final woodDark = mutated ? const Color(0xFF0A0A0A) : const Color(0xFF5D4037);
    const benchScale = 1.22;
    const seatW = 40.0;
    const seatY = 4.0;
    const legY = 18.0;
    const legH = 20.0;
    const toriiBeamY = -26.0;
    const backPostW = 6.0;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(benchScale);
    canvas.translate(-c.dx, -c.dy);

    void drawBackCornerPosts(double postH) {
      for (final px in [-seatW / 2, seatW / 2]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx + px, c.dy + seatY - 4 - postH / 2),
              width: backPostW,
              height: postH,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = wood,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx + px, c.dy + seatY - 4 - postH / 2),
              width: backPostW,
              height: postH,
            ),
            const Radius.circular(2),
          ),
          ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin),
        );
      }
    }

    if (st >= 3) {
      final postX = seatW / 2 - 2;
      for (final px in [-postX, postX]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx + px, c.dy + (toriiBeamY + seatY) / 2),
              width: 5,
              height: seatY - toriiBeamY + 6,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = woodDark,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, c.dy + toriiBeamY), width: seatW + 18, height: 5),
          const Radius.circular(2),
        ),
        Paint()..color = wood,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, c.dy + toriiBeamY - 6), width: seatW + 12, height: 4),
          const Radius.circular(2),
        ),
        Paint()..color = woodDark,
      );
    }

    if (st >= 4) {
      final wisteria = mutated ? const Color(0xFFF0F0F0) : const Color(0xFFC48BB8);
      for (final xOff in [-seatW * 0.40, -seatW * 0.14, seatW * 0.14, seatW * 0.40]) {
        _drawWisteriaCluster(canvas, Offset(c.dx + xOff, c.dy + toriiBeamY), wisteria, dropLen: 10);
      }
    }

    for (final x in [-seatW / 2 + 6, seatW / 2 - 6]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx + x, c.dy + legY), width: 5, height: legH),
          const Radius.circular(1),
        ),
        Paint()..color = wood,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx + x, c.dy + legY), width: 5, height: legH),
          const Radius.circular(1),
        ),
        ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + seatY), width: seatW, height: 8),
        const Radius.circular(3),
      ),
      Paint()..color = woodHi,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + seatY), width: seatW, height: 8),
        const Radius.circular(3),
      ),
      ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin),
    );

    if (st == 1) {
      const stubWood = Color(0xFF8B5E3C);
      const stubPostH = 20.0;
      const stubPostW = 7.0;
      final plankTopY = c.dy + seatY - 4;
      for (final px in [-seatW / 2, seatW / 2]) {
        final postRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c.dx + px, plankTopY - stubPostH / 2),
            width: stubPostW,
            height: stubPostH,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(postRect, Paint()..color = stubWood);
        canvas.drawRRect(postRect, ZenCartoonStyle.outline(1.6));
      }
    }

    if (st == 2) {
      const postH = 40.0;
      final plankTopY = c.dy + seatY - 4;
      drawBackCornerPosts(postH);
      final partialBeamY = plankTopY - postH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, partialBeamY), width: seatW * 0.58, height: 4),
          const Radius.circular(2),
        ),
        Paint()..color = wood,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx, partialBeamY), width: seatW * 0.58, height: 4),
          const Radius.circular(2),
        ),
        ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin),
      );
    }

    if (st >= 1) {
      for (var g = -1; g <= 1; g++) {
        canvas.drawLine(
          Offset(c.dx + g * 11, c.dy + seatY - 2),
          Offset(c.dx + g * 11, c.dy + seatY + 2),
          Paint()
            ..color = woodDark.withValues(alpha: 0.5)
            ..strokeWidth = 1,
        );
      }
    }

    if (st >= 2) {
      final plantX = c.dx + seatW / 2 - 10;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(plantX, c.dy + seatY + 2), width: 10, height: 4),
        Paint()..color = const Color(0xFF6D4C41),
      );
      canvas.drawLine(
        Offset(plantX, c.dy + seatY),
        Offset(plantX, c.dy + seatY - 10),
        Paint()
          ..color = woodDark
          ..strokeWidth = 2,
      );
      if (mutated) {
        _drawRockFlower(canvas, Offset(plantX, c.dy + seatY - 12), Colors.white);
      } else {
        canvas.drawCircle(Offset(plantX, c.dy + seatY - 12), 5, Paint()..color = const Color(0xFF5A9A48));
      }
    }

    if (st >= 4) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(c.dx - 8, c.dy + seatY), width: 8, height: 5),
          const Radius.circular(1),
        ),
        Paint()..color = const Color(0xFFF5F0E8),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx + 6, c.dy + seatY + 1), width: 5, height: 4),
        Paint()..color = const Color(0xFFE8E0D8),
      );
    }

    canvas.restore();
  }

  static void _paintBambooFence(Canvas canvas, Size size, Offset c, int st, MutationKind? m, String id) {
    final mutated = _mutated(m);
    final bamboo = mutated ? const Color(0xFF2A2A2A) : const Color(0xFF6B8F5E);
    final node = mutated ? const Color(0xFFBBBBBB) : const Color(0xFF4A6A48);
    final rope = mutated ? Colors.white : const Color(0xFF5D4037);
    final poleCounts = [3, 5, 7, 9, 9];
    final spans = [54.0, 44.0, 40.0, 36.0, 36.0];
    const fenceHeight = 45.0;
    final poles = poleCounts[st];
    final span = spans[st];
    final rnd = _decorRng('bf', id, st);
    final gateCenter = st >= 4;
    final gateIndex = poles ~/ 2;

    for (var i = 0; i < poles; i++) {
      if (gateCenter && i == gateIndex) continue;
      final t = poles == 1 ? 0.5 : i / (poles - 1);
      final x = c.dx - span / 2 + t * span;
      final heightVar = (rnd.nextDouble() - 0.5) * 0.06;
      final h = fenceHeight +
          (gateCenter && (i == gateIndex - 1 || i == gateIndex + 1) ? 4 : 0);
      _drawBambooStalk(canvas, Offset(x, c.dy + 4), h * (1 + heightVar), bamboo, node);
    }

    if (gateCenter) {
      _drawBambooStalk(canvas, Offset(c.dx - 7, c.dy + 2), fenceHeight + 2, bamboo, node);
      _drawBambooStalk(canvas, Offset(c.dx + 7, c.dy + 2), fenceHeight + 2, bamboo, node);
      canvas.drawLine(
        Offset(c.dx - 5, c.dy - 4),
        Offset(c.dx + 5, c.dy - 4),
        Paint()
          ..color = rope
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset(c.dx + 5, c.dy - 4),
        2.5,
        Paint()
          ..color = rope
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final ropeRows = switch (st) {
      0 => 1,
      1 => 1,
      _ => 2,
    };
    for (var r = 0; r < ropeRows; r++) {
      final yy = c.dy - 4 - r * 11.0;
      canvas.drawLine(
        Offset(c.dx - span / 2 - 2, yy),
        Offset(c.dx + span / 2 + 2, yy),
        Paint()
          ..color = rope
          ..strokeWidth = 2,
      );
      for (var i = 0; i < poles; i++) {
        if (gateCenter && i == gateIndex) continue;
        final t = poles == 1 ? 0.5 : i / (poles - 1);
        final x = c.dx - span / 2 + t * span;
        _drawRopeTie(canvas, Offset(x, yy), rope);
      }
      if (gateCenter && r == 0) {
        _drawRopeTie(canvas, Offset(c.dx - 7, yy), rope);
        _drawRopeTie(canvas, Offset(c.dx + 7, yy), rope);
      }
    }
  }

  static void _drawBambooStalk(Canvas canvas, Offset base, double height, Color bamboo, Color node) {
    final w = 6.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(base.dx, base.dy - height / 2), width: w, height: height),
      Radius.circular(w / 2),
    );
    canvas.drawRRect(rect, Paint()..color = bamboo);
    canvas.drawRRect(rect, ZenCartoonStyle.outline(1.4));
    for (var y = base.dy - height + 14; y < base.dy - 6; y += 28) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(base.dx, y), width: w + 2, height: 4),
        Paint()..color = node.withValues(alpha: 0.9),
      );
    }
  }

  static void _drawRopeTie(Canvas canvas, Offset p, Color rope) {
    final paint = Paint()
      ..color = rope
      ..strokeWidth = 1.8;
    canvas.drawLine(p.translate(-3, -3), p.translate(3, 3), paint);
    canvas.drawLine(p.translate(-3, 3), p.translate(3, -3), paint);
  }

  static void _paintMossRock(Canvas canvas, Size size, Offset c, int st, MutationKind? m, String id) {
    final mutated = _mutated(m);
    final rockHi = mutated ? const Color(0xFF2A2A2A) : const Color(0xFF9E9A93);
    final rockMid = mutated ? const Color(0xFF1A1A1A) : const Color(0xFF6F6B64);
    final rockLo = mutated ? const Color(0xFF0A0A0A) : const Color(0xFF4A4742);
    final mossHi = mutated ? const Color(0xFF2A6A68) : const Color(0xFF6B8F5E);
    final mossLo = mutated ? const Color(0xFF1A4848) : const Color(0xFF3D5A38);
    final flower = mutated ? const Color(0xFFD8B8FF) : Colors.white;

    final rockSpecs = switch (st) {
      0 => [(0.0, 0.0, 1.0)],
      1 => [(0.0, 0.0, 1.0)],
      2 => [(0.0, 0.0, 1.0)],
      3 => [(-14.0, 4.0, 0.85), (12.0, 6.0, 0.75)],
      _ => [(-16.0, 6.0, 0.8), (10.0, 8.0, 0.75), (0.0, -10.0, 0.95)],
    };

    final coverage = [0.0, 0.2, 0.5, 0.8, 1.0][st];

    for (final (ox, oy, sc) in rockSpecs) {
      _drawSingleMossRock(
        canvas,
        c.translate(ox, oy),
        sc,
        rockHi,
        rockMid,
        rockLo,
        mossHi,
        mossLo,
        coverage,
      );
    }

    if (st >= 3) {
      _drawFernFrond(canvas, c.translate(-18, 14), color: mossHi);
    }
    if (st >= 4) {
      _drawFernFrond(canvas, c.translate(16, 16), color: mossHi);
      _drawRockFlower(canvas, c.translate(0, -10), flower, prominent: true);
    }
  }

  static void _drawSingleMossRock(
    Canvas canvas,
    Offset c,
    double sc,
    Color rockHi,
    Color rockMid,
    Color rockLo,
    Color mossHi,
    Color mossLo,
    double coverage,
  ) {
    final boulder = Path()
      ..moveTo(c.dx - 22 * sc, c.dy + 8 * sc)
      ..cubicTo(c.dx - 28 * sc, c.dy - 6 * sc, c.dx - 8 * sc, c.dy - 18 * sc, c.dx + 6 * sc, c.dy - 14 * sc)
      ..cubicTo(c.dx + 24 * sc, c.dy - 10 * sc, c.dx + 28 * sc, c.dy + 4 * sc, c.dx + 16 * sc, c.dy + 10 * sc)
      ..cubicTo(c.dx + 4 * sc, c.dy + 16 * sc, c.dx - 14 * sc, c.dy + 14 * sc, c.dx - 22 * sc, c.dy + 8 * sc)
      ..close();
    final bb = boulder.getBounds();
    canvas.drawPath(
      boulder,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [rockHi, rockMid, rockLo],
        ).createShader(bb),
    );
    canvas.drawPath(boulder, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));
    _drawRockSpecular(canvas, c, sc);

    if (coverage > 0) {
      final mossH = 22 * sc * coverage;
      final mossRx = 18 * sc;
      final mossRy = mossH * 0.55;
      final mossCenter = Offset(c.dx, c.dy - mossH * 0.35);
      final mossPath = _bumpyMossSilhouette(mossCenter, mossRx, mossRy, seed: sc * 2.1);
      canvas.drawPath(
        mossPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [mossHi, mossLo],
          ).createShader(mossPath.getBounds()),
      );
    }
  }

  static void _paintFallbackRock(Canvas canvas, Offset c, int st) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 30 + st * 4.0, height: 18 + st * 2.0),
      Paint()..color = const Color(0xFF8A8A8A),
    );
  }
}

/// Warm sand glow beneath placeable stone lanterns (stages 3–5).
class LanternSandGlowPainter extends CustomPainter {
  LanternSandGlowPainter({
    required this.item,
    required this.animPhase,
  });

  final DecorItem item;
  final double animPhase;

  @override
  void paint(Canvas canvas, Size size) {
    ZenGardenDecorPainter.paintLanternSandGlowLayer(canvas, size, item, animPhase);
  }

  @override
  bool shouldRepaint(covariant LanternSandGlowPainter oldDelegate) {
    return oldDelegate.item != item || oldDelegate.animPhase != animPhase;
  }
}

/// Whether this decor item should run a looping paint animation.
bool zenDecorNeedsAnimation(DecorItem item, {required bool reduceMotion}) {
  if (item.kind == 'zen.koi_pond') return true;
  if (reduceMotion) return false;
  return item.kind == 'zen.stone_lantern' && item.stageIndex >= 4;
}

/// Duration for decor animation loops (elapsed via [AnimationController.lastElapsedDuration]).
Duration zenDecorAnimationDuration(DecorItem item) {
  if (item.kind == 'zen.stone_lantern') {
    return const Duration(seconds: 3);
  }
  return const Duration(seconds: 8);
}
