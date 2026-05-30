import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_bridge.dart';

import 'zen_garden_cartoon_style.dart';
import 'zen_garden_decor_painters.dart';

/// Canopy diameter per growth stage (stage 1→22px … stage 5→60px).
double zenTreeCanopyDiameter(int stageIndex) {
  const diameters = [22.0, 30.0, 40.0, 50.0, 60.0];
  return diameters[stageIndex.clamp(0, 4)];
}

/// Light outline for foliage bubbles (less dominant than default ink stroke).
const double zenTreeCanopyStrokeWidth = 1.5;

Color _invColor(Color c, MutationKind? m) => applyMutationTint(base: c, mutation: m);

double _sandHash(int x, int y) {
  var h = x * 374761393 + y * 668265263;
  h = (h ^ (h >> 13)) * 1274126177;
  return ((h & 0xFFFFFF) / 0x1000000);
}

/// Warm, desaturated sand palette that lets greens, blues, and wood placeables pop.
class ZenGardenBackgroundPalette {
  const ZenGardenBackgroundPalette({
    required this.highlight,
    required this.midTone,
    required this.shadow,
    required this.deepShadow,
    required this.rakeLine,
    required this.mossVeil,
    required this.stoneEdge,
  });

  final Color highlight;
  final Color midTone;
  final Color shadow;
  final Color deepShadow;
  final Color rakeLine;
  final Color mossVeil;
  final Color stoneEdge;

  /// Split-complementary warm sand base with a whisper of theme hue (â‰¤8% mix).
  factory ZenGardenBackgroundPalette.harmonized({
    Color? themePrimary,
    Color? themeSecondary,
  }) {
    const highlight = Color(0xFFF7EAC8);
    const midTone = Color(0xFFEFD89E);
    const shadow = Color(0xFFE0C078);
    const deepShadow = Color(0xFFC9A060);
    const rakeLine = Color(0xFFB88850);
    const mossVeil = Color(0xFF6B9E54);
    const stoneEdge = Color(0xFF8A7058);

    Color tint(Color base, Color? theme, double amount) {
      if (theme == null) return base;
      return Color.lerp(base, theme, amount)!;
    }

    return ZenGardenBackgroundPalette(
      highlight: tint(highlight, themeSecondary, 0.06),
      midTone: tint(midTone, themeSecondary, 0.05),
      shadow: tint(shadow, themePrimary, 0.04),
      deepShadow: tint(deepShadow, themePrimary, 0.07),
      rakeLine: tint(rakeLine, themePrimary, 0.05),
      mossVeil: mossVeil,
      stoneEdge: tint(stoneEdge, themePrimary, 0.04),
    );
  }
}

/// Rustic dry zen garden: warm sand, soft rake arcs, mossy corners, stone edge.
class RakedSandPainter extends CustomPainter {
  RakedSandPainter._(this.palette);

  factory RakedSandPainter.harmonized({
    Color? themePrimary,
    Color? themeSecondary,
  }) =>
      RakedSandPainter._(
        ZenGardenBackgroundPalette.harmonized(
          themePrimary: themePrimary,
          themeSecondary: themeSecondary,
        ),
      );

  final ZenGardenBackgroundPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final cx = size.width * 0.46;
    final cy = size.height * 0.46;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.highlight,
            palette.midTone,
            palette.shadow,
            palette.deepShadow,
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.55, -0.65),
          radius: 1.05,
          colors: [
            palette.highlight.withValues(alpha: 0.55),
            palette.midTone.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.72, 0.78),
          radius: 0.85,
          colors: [
            Colors.transparent,
            palette.deepShadow.withValues(alpha: 0.18),
            palette.deepShadow.withValues(alpha: 0.32),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    _drawMossCorners(canvas, size);
    _drawFineGrain(canvas, size);
    _drawRakeArcs(canvas, cx, cy, size);
    _drawStoneBorder(canvas, size);
    _drawVignette(canvas, rect);
  }

  void _drawMossCorners(Canvas canvas, Size size) {
    final moss = Paint()..color = palette.mossVeil.withValues(alpha: 0.07);
    for (final corner in [
      Offset(size.width * 0.06, size.height * 0.08),
      Offset(size.width * 0.92, size.height * 0.1),
      Offset(size.width * 0.08, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.88),
    ]) {
      canvas.drawCircle(corner, size.shortestSide * 0.14, moss);
      canvas.drawCircle(
        corner,
        size.shortestSide * 0.08,
        Paint()..color = palette.mossVeil.withValues(alpha: 0.05),
      );
    }
  }

  void _drawFineGrain(Canvas canvas, Size size) {
    const step = 12.0;
    for (var gy = 0.0; gy < size.height; gy += step) {
      for (var gx = 0.0; gx < size.width; gx += step) {
        final h = _sandHash(gx.round(), gy.round());
        final a = 0.008 + h * 0.022;
        final tone = Color.lerp(palette.midTone, palette.shadow, h)!;
        canvas.drawCircle(
          Offset(
            gx + (h - 0.5) * 1.4,
            gy + (_sandHash(gy.round(), gx.round()) - 0.5) * 1.4,
          ),
          0.35 + h * 0.45,
          Paint()..color = tone.withValues(alpha: a),
        );
      }
    }
  }

  void _drawRakeArcs(Canvas canvas, double cx, double cy, Size size) {
    // Outermost ring = 75% of garden width (radius 37.5%).
    final maxR = size.width * 0.375;
    const ringGap = 14.0;
    const minRingR = 30.0;
    const ringColor = Color(0x26000000);

    var r = minRingR;
    var ringIndex = 0;
    while (r <= maxR) {
      final innerFade = ringIndex < 3;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = ringColor.withValues(alpha: innerFade ? 0.10 : 0.15)
          ..strokeWidth = 0.9
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      r += ringGap;
      ringIndex++;
    }

    _drawHorizontalRakesOutsideCircle(
      canvas,
      size,
      circleCenter: Offset(cx, cy),
      circleRadius: maxR,
    );
  }

  /// Full-width horizontal rakes clipped to the region outside the rake circle.
  void _drawHorizontalRakesOutsideCircle(
    Canvas canvas,
    Size size, {
    required Offset circleCenter,
    required double circleRadius,
  }) {
    const inset = 14.0;
    const lineGap = 12.0;

    canvas.save();
    final garden = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circleHole = Path()
      ..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius));
    canvas.clipPath(Path.combine(PathOperation.difference, garden, circleHole));

    final paint = Paint()
      ..color = const Color(0x26000000)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var y = inset; y < size.height - inset; y += lineGap) {
      canvas.drawLine(
        Offset(inset, y),
        Offset(size.width - inset, y),
        paint,
      );
    }
    canvas.restore();
  }

  void _drawStoneBorder(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      outer,
      Paint()..color = palette.stoneEdge.withValues(alpha: 0.22),
    );
    canvas.drawRRect(outer, ZenCartoonStyle.outline(3.2));
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
      const Radius.circular(8),
    );
    canvas.drawRRect(inner, ZenCartoonStyle.outline(ZenCartoonStyle.outlineThin));
  }

  void _drawVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [
            Colors.transparent,
            palette.deepShadow.withValues(alpha: 0.08),
            palette.deepShadow.withValues(alpha: 0.22),
          ],
          stops: const [0.55, 0.85, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant RakedSandPainter oldDelegate) {
    return oldDelegate.palette.highlight != palette.highlight ||
        oldDelegate.palette.midTone != palette.midTone ||
        oldDelegate.palette.shadow != palette.shadow;
  }
}

/// Drop shadow beneath draggable plants and decor.
class PlaceableGroundShadowPainter extends CustomPainter {
  PlaceableGroundShadowPainter({
    required this.center,
    this.width = 56,
    this.height = 14,
  });

  final Offset center;
  final double width;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    ZenCartoonStyle.drawGroundShadow(
      canvas,
      center,
      width: width,
      height: height,
    );
  }

  @override
  bool shouldRepaint(covariant PlaceableGroundShadowPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
  }
}

/// Soft ring for selection + optional timer arc (0â€“1 progress filled clockwise from top).
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
        ..color = primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(c, r, track);
      final sweep = 2 * math.pi * timerProgress!.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = ZenCartoonStyle.saturate(primary)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    if (selected) {
      ZenCartoonStyle.drawDashedCircle(
        canvas,
        c,
        r + (timerProgress != null ? 8 : 6),
        ZenCartoonStyle.saturate(primary),
        stroke: 3,
      );
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
    ZenCartoonStyle.drawDashedCircle(canvas, center, 28, color, stroke: 2.8);
    canvas.drawCircle(
      center,
      28,
      Paint()..color = color.withValues(alpha: 0.15),
    );
    ZenCartoonStyle.highlightSpot(canvas, center + const Offset(-8, -8), 5);
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
    final mutated = mutation == MutationKind.invertedColors;
    final foliage = mutated ? ZenCartoonStyle.plantMutant : ZenCartoonStyle.plantSage;
    final foliageHi = mutated ? ZenCartoonStyle.plantMutantHi : ZenCartoonStyle.plantSageHi;
    final edge = _invColor(ZenCartoonStyle.ink, mutation);
    final trunk = _invColor(ZenCartoonStyle.trunk, mutation);
    final trunkHi = _invColor(ZenCartoonStyle.trunkHi, mutation);
    const swThin = ZenCartoonStyle.outlineThin;

    void trunkRect(double width, double height, double cx, double bottom) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, bottom - height / 2),
          width: width,
          height: height,
        ),
        Radius.circular(width * 0.35),
      );
      canvas.drawRRect(r, Paint()..color = trunk);
      canvas.drawRRect(r, ZenCartoonStyle.outline(swThin, edge));
      ZenCartoonStyle.highlightSpot(
        canvas,
        Offset(cx - width * 0.15, bottom - height * 0.65),
        width * 0.12,
      );
    }

    void branch(double x0, double y0, double x1, double y1, double bw) {
      canvas.drawLine(
        Offset(x0, y0),
        Offset(x1, y1),
        Paint()
          ..color = trunkHi
          ..strokeWidth = bw + 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(x0, y0),
        Offset(x1, y1),
        ZenCartoonStyle.outline(swThin, edge),
      );
    }

    void leafBlob(double cx, double cy, double rx, double ry, double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2.2, height: ry * 2.2);
      final path = Path()..addOval(rect);
      if (mutated) {
        canvas.drawPath(
          path,
          Paint()
            ..color = ZenCartoonStyle.plantMutant.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }
      canvas.drawPath(path, Paint()..color = foliage);
      canvas.drawPath(path, ZenCartoonStyle.outline(zenTreeCanopyStrokeWidth, edge));
      ZenCartoonStyle.highlightSpot(canvas, Offset(-rx * 0.25, -ry * 0.35), rx * 0.22);
      canvas.restore();
    }

    void drawMutationStars(double cx, double cy, double rx, double ry) {
      final rng = math.Random((cx * 1000 + cy).round());
      for (var s = 0; s < 3 + rng.nextInt(2); s++) {
        final ang = rng.nextDouble() * math.pi * 2;
        final star = Offset(cx + math.cos(ang) * rx, cy + math.sin(ang) * ry);
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final a = i / 4 * math.pi * 2 - math.pi / 2;
          final tip = star + Offset(math.cos(a) * 8, math.sin(a) * 8);
          final side = star + Offset(math.cos(a + math.pi / 4) * 3, math.sin(a + math.pi / 4) * 3);
          if (i == 0) {
            path.moveTo(tip.dx, tip.dy);
          } else {
            path.lineTo(tip.dx, tip.dy);
          }
          path.lineTo(side.dx, side.dy);
        }
        path.close();
        canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.8));
      }
    }

    void drawCanopyOval(
      double cx,
      double cy,
      double diameter,
      Color color, {
      double stroke = zenTreeCanopyStrokeWidth,
    }) {
      final canopy = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(cx, cy),
          width: diameter,
          height: diameter * 0.88,
        ));
      if (mutated) {
        canvas.drawPath(
          canopy,
          Paint()
            ..color = ZenCartoonStyle.plantMutant.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }
      ZenCartoonStyle.celShadow(canvas, canopy);
      ZenCartoonStyle.drawOutlinedPath(canvas, canopy, color, stroke: stroke);
      ZenCartoonStyle.highlightSpot(canvas, Offset(cx - diameter * 0.18, cy - diameter * 0.22), diameter * 0.08);
    }

    final cx = w * 0.5;
    final bottom = h * 0.94;
    final st = stageIndex.clamp(0, 4);
    final canopyD = zenTreeCanopyDiameter(st);

    switch (st) {
      case 0:
        final pebble = Path()
          ..addOval(Rect.fromCenter(
            center: Offset(cx, bottom - canopyD * 0.32),
            width: canopyD * 0.72,
            height: canopyD * 0.52,
          ));
        if (mutated) {
          canvas.drawPath(
            pebble,
            Paint()
              ..color = ZenCartoonStyle.plantMutant.withValues(alpha: 0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
        }
        ZenCartoonStyle.celShadow(canvas, pebble);
        ZenCartoonStyle.drawOutlinedPath(canvas, pebble, foliageHi, stroke: zenTreeCanopyStrokeWidth);
        ZenCartoonStyle.highlightSpot(canvas, Offset(cx - 4, bottom - canopyD * 0.4), 4);
        if (mutated) drawMutationStars(cx, bottom - canopyD * 0.32, canopyD * 0.18, canopyD * 0.12);
      case 1:
        trunkRect(8, h * 0.26, cx, bottom);
        final canopyY = bottom - h * 0.40;
        drawCanopyOval(cx, canopyY, canopyD, foliage);
        leafBlob(cx - canopyD * 0.28, canopyY + 4, canopyD * 0.16, canopyD * 0.13, -0.5);
        leafBlob(cx + canopyD * 0.28, canopyY + 3, canopyD * 0.16, canopyD * 0.13, 0.5);
      case 2:
        trunkRect(9, h * 0.36, cx, bottom);
        branch(cx, bottom - h * 0.28, cx - w * 0.17, bottom - h * 0.46, 4.5);
        branch(cx, bottom - h * 0.26, cx + w * 0.15, bottom - h * 0.44, 4.5);
        final canopyY2 = bottom - h * 0.52;
        drawCanopyOval(cx, canopyY2, canopyD, foliage);
        leafBlob(cx - canopyD * 0.22, canopyY2 + 2, canopyD * 0.14, canopyD * 0.10, -0.9);
        leafBlob(cx + canopyD * 0.20, canopyY2 + 2, canopyD * 0.14, canopyD * 0.10, 0.9);
      case 3:
        trunkRect(10, h * 0.42, cx, bottom);
        branch(cx, bottom - h * 0.32, cx - w * 0.19, bottom - h * 0.52, 5);
        branch(cx, bottom - h * 0.3, cx + w * 0.17, bottom - h * 0.5, 5);
        final canopyY3 = bottom - h * 0.58;
        drawCanopyOval(cx, canopyY3, canopyD, foliage);
        final bloom = Path()
          ..addOval(Rect.fromCenter(
            center: Offset(cx, canopyY3 - canopyD * 0.12),
            width: canopyD * 0.22,
            height: canopyD * 0.22,
          ));
        ZenCartoonStyle.drawOutlinedPath(canvas, bloom, foliageHi, stroke: zenTreeCanopyStrokeWidth);
      default:
        trunkRect(12, h * 0.38, cx, bottom);
        final joinY = bottom - h * 0.34;
        branch(cx, bottom - h * 0.08, cx - w * 0.07, joinY, 6);
        branch(cx, bottom - h * 0.08, cx + w * 0.07, joinY, 6);
        branch(cx, joinY, cx - w * 0.21, bottom - h * 0.58, 4);
        branch(cx, joinY, cx + w * 0.19, bottom - h * 0.56, 4);
        final canopyY4 = bottom - h * 0.58;
        drawCanopyOval(cx, canopyY4, canopyD, foliage);
        if (mutated) {
          drawMutationStars(cx, canopyY4, canopyD * 0.38, canopyD * 0.28);
        }
        leafBlob(cx, canopyY4 + 4, canopyD * 0.16, canopyD * 0.12, -0.35);
        leafBlob(cx + canopyD * 0.28, canopyY4 + 4, canopyD * 0.16, canopyD * 0.12, 0.35);
        leafBlob(cx, canopyY4 - canopyD * 0.24, canopyD * 0.14, canopyD * 0.10, 0);
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

/// Decor evolves with [stageIndex]; see [ZenGardenDecorPainter].
class ZenDecorPainter extends CustomPainter {
  ZenDecorPainter({
    required this.item,
    required this.primary,
    required this.secondary,
    this.animPhase = 0,
  });

  final DecorItem item;
  final Color primary;
  final Color secondary;
  final double animPhase;

  @override
  void paint(Canvas canvas, Size size) {
    ZenGardenDecorPainter.paint(
      canvas: canvas,
      size: size,
      item: item,
      primary: primary,
      secondary: secondary,
      animPhase: animPhase,
    );
  }

  @override
  bool shouldRepaint(covariant ZenDecorPainter oldDelegate) {
    return oldDelegate.item != item ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.animPhase != animPhase;
  }
}
