import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cherry_blossom_growth.dart';
import 'cherry_blossom_reference_tree.dart';
import 'cherry_blossom_tree_composition.dart';
import 'cherry_blossom_tree_sequence.dart';
import 'cherry_blossom_tree_state.dart';
import 'cherry_blossom_tree_visuals.dart';

/// Ambient animation values passed from [CherryBlossomTreeCanvas].
class CherryBlossomAmbientState {
  const CherryBlossomAmbientState({
    this.ambientT = 0,
    this.auroraT = 0,
    this.swayRadians = 0,
    this.petals = const [],
    this.fireflies = const [],
    this.groundLandingPetals = const [],
  });

  final double ambientT;
  final double auroraT;
  final double swayRadians;
  final List<({Offset pos, double opacity, double rotation, bool isFlower, double scale})>
      petals;
  final List<({Offset pos, double opacity, Color color})> fireflies;
  final List<({Offset pos, double opacity})> groundLandingPetals;
}

/// Paints the cherry blossom tree from growth substages (deterministic per state).
class CherryBlossomTreePainter extends CustomPainter {
  CherryBlossomTreePainter({
    required this.tree,
    this.growthFocus,
    this.growthPulseT = 1,
    this.ambient = const CherryBlossomAmbientState(),
    this.trunkTint,
  });

  final CherryBlossomTreeState tree;
  final CherryBlossomGrowthFocus? growthFocus;
  final double growthPulseT;
  final CherryBlossomAmbientState ambient;
  final Color? trunkTint;

  @override
  void paint(Canvas canvas, Size size) {
    final band = tree.visualBand;
    final composition = CherryBlossomTreeComposition.forStep(
      size,
      tree.growthStepIndex,
      band,
    );
    final levels = CherryBlossomTreeSequence.deriveLevels(tree.growthStepIndex);
    final growthT =
        (tree.growthStepIndex / CherryBlossomTreeSequence.totalSteps)
            .clamp(0.0, 1.0);

    CherryBlossomTreeVisuals.paintBackground(
      canvas,
      size,
      band,
      ambientT: ambient.ambientT,
    );

    if (band.index >= CherryBlossomVisualBand.good.index &&
        band != CherryBlossomVisualBand.perfect) {
      _paintCanopyGlow(canvas, composition);
    }

    if (growthFocus != null) {
      _paintGrowthHighlight(canvas, size, composition, growthFocus!);
    }

    canvas.save();
    if (band == CherryBlossomVisualBand.perfect && ambient.swayRadians != 0) {
      canvas.translate(composition.base.dx, composition.base.dy);
      canvas.rotate(ambient.swayRadians);
      canvas.translate(-composition.base.dx, -composition.base.dy);
    }

    _paintGroundShadow(canvas, size, composition.base, band, growthT);
    if (band != CherryBlossomVisualBand.perfect) {
      _paintRoots(
        canvas,
        size,
        composition.base,
        band,
        growthT,
        levels.trunkSegments,
      );
    }

    if (band == CherryBlossomVisualBand.perfect) {
      CherryBlossomReferenceTree.paint(
        canvas,
        size,
        trunkTint: trunkTint,
        pulseFor: _pulseFor,
        auroraT: ambient.auroraT,
        groundLandingPetals: ambient.groundLandingPetals,
      );
    } else {
      _paintCompositionTree(canvas, size, composition, band);
      if (band.index >= CherryBlossomVisualBand.great.index) {
        _paintGroundPetals(canvas, size, composition.base, band, growthT);
      }
    }

    canvas.restore();

    if (band.index >= CherryBlossomVisualBand.basic.index) {
      for (final petal in ambient.petals) {
        _paintFallingPetal(canvas, size, petal);
      }
    }

    if (band == CherryBlossomVisualBand.perfect) {
      for (final fly in ambient.fireflies) {
        canvas.drawCircle(
          Offset(size.width * fly.pos.dx, size.height * fly.pos.dy),
          2.5,
          Paint()
            ..color = fly.color.withValues(alpha: fly.opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
  }

  void _paintCompositionTree(
    Canvas canvas,
    Size size,
    CherryBlossomTreeComposition composition,
    CherryBlossomVisualBand band,
  ) {
    final back = composition.clusters
        .where((c) => c.layer == CherryBlossomDomeLayer.back)
        .toList();
    final mid = composition.clusters
        .where((c) => c.layer == CherryBlossomDomeLayer.mid)
        .toList();
    final front = composition.clusters
        .where((c) => c.layer == CherryBlossomDomeLayer.front)
        .toList();
    final highlights = composition.clusters
        .where((c) => c.layer == CherryBlossomDomeLayer.highlight)
        .toList();

    if (band.index >= CherryBlossomVisualBand.basic.index) {
      for (final cluster in back) {
        _paintDomeCluster(canvas, cluster, band);
      }
    }

    _paintTrunkFromComposition(canvas, composition, band);

    for (final limb in composition.limbs) {
      _paintLimb(canvas, limb);
    }

    for (final cluster in mid) {
      _paintDomeCluster(canvas, cluster, band);
    }

    for (final cluster in front) {
      _paintDomeCluster(canvas, cluster, band);
    }

    for (final cluster in highlights) {
      _paintDomeCluster(canvas, cluster, band, emphasize: true);
    }

    if (band == CherryBlossomVisualBand.seedling) {
      _paintSeedlingBuds(canvas, composition);
    }
  }

  void _paintTrunkFromComposition(
    Canvas canvas,
    CherryBlossomTreeComposition composition,
    CherryBlossomVisualBand band,
  ) {
    final base = composition.base;
    final h = composition.trunkH;
    final baseW = composition.trunkBaseW;
    final topW = baseW * 0.52;
    final pulse = _pulseFor(CherryBlossomGrowthKind.base);
    final center = Offset(base.dx, base.dy - h * 0.5);

    _withPop(canvas, center, pulse, () {
      final path = Path()
        ..moveTo(base.dx - baseW * 0.55, base.dy)
        ..lineTo(base.dx - topW * 0.5, base.dy - h)
        ..lineTo(base.dx + topW * 0.5, base.dy - h)
        ..lineTo(base.dx + baseW * 0.55, base.dy)
        ..close();

      final bark = trunkTint ?? CherryBlossomTreeVisuals.trunkBrown;
      canvas.drawPath(path, Paint()..color = bark);

      canvas.drawLine(
        Offset(base.dx - baseW * 0.4, base.dy - h * 0.05),
        Offset(base.dx - topW * 0.35, base.dy - h * 0.92),
        Paint()
          ..color =
              CherryBlossomTreeVisuals.trunkHighlight.withValues(alpha: 0.5)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );

      if (band.index >= CherryBlossomVisualBand.good.index) {
        for (final side in [-1.0, 1.0]) {
          final flare = Path()
            ..moveTo(base.dx + side * baseW * 0.5, base.dy)
            ..quadraticBezierTo(
              base.dx + side * baseW * 0.68,
              base.dy - h * 0.05,
              base.dx + side * baseW * 0.42,
              base.dy - h * 0.14,
            );
          canvas.drawPath(
            flare,
            Paint()
              ..color = CherryBlossomTreeVisuals.trunkDark.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = baseW * 0.18
              ..strokeCap = StrokeCap.round,
          );
        }
      }

      if (band.index >= CherryBlossomVisualBand.basic.index) {
        final forkPaint = Paint()
          ..color = CherryBlossomTreeVisuals.trunkBrown
          ..strokeWidth = topW * 0.85
          ..strokeCap = StrokeCap.round;
        for (final side in [-1.0, 1.0]) {
          final angle = side * 32 * math.pi / 180;
          final len = h * 0.12;
          canvas.drawLine(
            composition.forkPoint,
            Offset(
              composition.forkPoint.dx + math.sin(angle) * len * 2.4,
              composition.forkPoint.dy - math.cos(angle) * len,
            ),
            forkPaint,
          );
        }
      }
    });
  }

  void _paintLimb(Canvas canvas, CherryBlossomLimb limb) {
    final color = switch (limb.colorValue) {
      2 => CherryBlossomTreeVisuals.trunkHighlight,
      1 => CherryBlossomTreeVisuals.trunkMid,
      _ => CherryBlossomTreeVisuals.trunkBrown,
    };
    canvas.drawPath(
      Path()
        ..moveTo(limb.origin.dx, limb.origin.dy)
        ..quadraticBezierTo(
          limb.control.dx,
          limb.control.dy,
          limb.end.dx,
          limb.end.dy,
        ),
      Paint()
        ..color = color.withValues(alpha: 0.93)
        ..strokeWidth = limb.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintDomeCluster(
    Canvas canvas,
    CherryBlossomDomeCluster cluster,
    CherryBlossomVisualBand band, {
    bool emphasize = false,
  }) {
    final baseColor = switch (cluster.layer) {
      CherryBlossomDomeLayer.back => CherryBlossomTreeVisuals.blossomBack,
      CherryBlossomDomeLayer.mid => CherryBlossomTreeVisuals.blossomPink,
      CherryBlossomDomeLayer.front => CherryBlossomTreeVisuals.blossomCenter,
      CherryBlossomDomeLayer.highlight => CherryBlossomTreeVisuals.blossomPale,
    };
    final alpha = switch (cluster.layer) {
      CherryBlossomDomeLayer.back => 0.55,
      _ => 0.92,
    };

    if (cluster.useFivePetals) {
      for (var f = 0; f < cluster.flowerCount; f++) {
        final a = f / cluster.flowerCount * math.pi * 2;
        final offset = Offset(
          math.cos(a) * cluster.flowerSize * 0.55,
          math.sin(a) * cluster.flowerSize * 0.45,
        );
        _paintFivePetalFlower(
          canvas,
          cluster.center + offset,
          cluster.flowerSize,
          emphasize: emphasize || cluster.highlight > 0.4,
          petalColor: emphasize
              ? CherryBlossomTreeVisuals.blossomPale
              : baseColor,
        );
      }
    } else {
      for (var p = 0; p < cluster.flowerCount; p++) {
        final a = p / cluster.flowerCount * math.pi * 2 + p * 0.35;
        final dist = cluster.flowerSize * (0.35 + (p % 3) * 0.15);
        final pos = cluster.center +
            Offset(math.cos(a) * dist, math.sin(a) * dist * 0.82);
        final r = cluster.flowerSize * 0.42;
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = baseColor.withValues(alpha: alpha)
            ..maskFilter = emphasize
                ? const MaskFilter.blur(BlurStyle.normal, 0.5)
                : null,
        );
      }
    }

    if (cluster.highlight > 0.3) {
      canvas.drawCircle(
        cluster.center,
        cluster.flowerSize * 0.65,
        Paint()
          ..color = Colors.white.withValues(alpha: cluster.highlight * 0.35),
      );
    }
  }

  void _paintSeedlingBuds(Canvas canvas, CherryBlossomTreeComposition composition) {
    for (final pos in composition.seedlingBuds) {
      canvas.drawCircle(
        pos,
        composition.trunkBaseW * 0.35,
        Paint()..color = CherryBlossomTreeVisuals.blossomPink,
      );
      canvas.drawCircle(
        pos,
        composition.trunkBaseW * 0.15,
        Paint()..color = CherryBlossomTreeVisuals.blossomCenter,
      );
    }
  }

  double _pulseFor(CherryBlossomGrowthKind kind, [int slot = 0]) {
    final focus = growthFocus;
    if (focus == null) return 1;
    if (focus.kind != kind) return 1;
    if (kind != CherryBlossomGrowthKind.base && focus.slotIndex != slot) {
      return 1;
    }
    return CherryBlossomTreeVisuals.popScale(growthPulseT);
  }

  void _paintCanopyGlow(Canvas canvas, CherryBlossomTreeComposition composition) {
    canvas.drawOval(
      Rect.fromCenter(
        center: composition.canopyCenter,
        width: composition.canopyRadiusX * 2.05,
        height: composition.canopyRadiusY * 2.05,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          composition.canopyCenter,
          composition.canopyRadiusX,
          [
            const Color(0x1FFFB7C5),
            const Color(0x00FFB7C5),
          ],
        ),
    );
  }

  void _paintGroundShadow(
    Canvas canvas,
    Size size,
    Offset base,
    CherryBlossomVisualBand band,
    double growthT,
  ) {
    if (band == CherryBlossomVisualBand.seedling && growthT < 0.05) return;
    final shadowW = size.width *
        ui.lerpDouble(
          0.15,
          band == CherryBlossomVisualBand.perfect ? 0.55 : 0.32,
          growthT,
        )!;
    final shadowH = size.height * ui.lerpDouble(0.012, 0.028, growthT)!;
    final alpha = ui.lerpDouble(0.18, 0.22, growthT)!;
    final center = Offset(base.dx, base.dy + shadowH * 0.3);
    if (band.index >= CherryBlossomVisualBand.good.index) {
      for (var ring = 2; ring >= 0; ring--) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: shadowW * (1 + ring * 0.12),
            height: shadowH * (1 + ring * 0.25),
          ),
          Paint()
            ..color = Colors.black.withValues(alpha: alpha * (1 - ring * 0.35)),
        );
      }
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: shadowW, height: shadowH),
        Paint()..color = Colors.black.withValues(alpha: alpha),
      );
    }
  }

  void _paintRoots(
    Canvas canvas,
    Size size,
    Offset base,
    CherryBlossomVisualBand band,
    double growthT,
    int trunkSegments,
  ) {
    if (trunkSegments <= 0 && growthT < 0.02) return;
    final trunkProgress =
        (trunkSegments / CherryBlossomTreeSequence.totalTrunkGrowthSteps)
            .clamp(0.08, 1.0);
    final count = switch (band) {
      CherryBlossomVisualBand.seedling => 2,
      CherryBlossomVisualBand.basic => 4,
      CherryBlossomVisualBand.good => 6,
      CherryBlossomVisualBand.great => 8,
      CherryBlossomVisualBand.perfect => 8,
    };
    final maxSpread = switch (band) {
      CherryBlossomVisualBand.seedling => 0.04,
      CherryBlossomVisualBand.basic => 0.07,
      CherryBlossomVisualBand.good => 0.10,
      CherryBlossomVisualBand.great => 0.12,
      CherryBlossomVisualBand.perfect => 0.14,
    };
    final spread = size.width * maxSpread * (0.45 + trunkProgress * 0.55);
    final stroke = 1.5 + trunkProgress * 2.5 + growthT;
    final paint = Paint()
      ..color = CherryBlossomTreeVisuals.rootBrown.withValues(alpha: 0.9)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final tier = i ~/ 2;
      final tierSpread = spread * (0.55 + tier * 0.22);
      final depth = size.height * (0.006 + tier * 0.004 + growthT * 0.008);
      final hump = size.height * 0.003 * (tier.isOdd ? 1 : -0.5);
      final path = Path()
        ..moveTo(base.dx + side * size.width * 0.012, base.dy)
        ..cubicTo(
          base.dx + side * tierSpread * 0.35,
          base.dy + hump,
          base.dx + side * tierSpread * 0.75,
          base.dy + depth * 0.55,
          base.dx + side * tierSpread,
          base.dy + depth,
        );
      if (band.index >= CherryBlossomVisualBand.great.index) {
        paint.shader = ui.Gradient.linear(
          Offset(base.dx + side * tierSpread * 0.2, base.dy),
          Offset(base.dx + side * tierSpread, base.dy + depth),
          [
            CherryBlossomTreeVisuals.rootBrown.withValues(alpha: 0.9),
            CherryBlossomTreeVisuals.rootBrown.withValues(alpha: 0),
          ],
          [0.75, 1.0],
        );
      } else {
        paint.shader = null;
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintGroundPetals(
    Canvas canvas,
    Size size,
    Offset base,
    CherryBlossomVisualBand band,
    double growthT,
  ) {
    final count = switch (band) {
      CherryBlossomVisualBand.great => 12,
      CherryBlossomVisualBand.perfect => 28,
      _ => 0,
    };
    final rng = math.Random(99);
    final spreadW = size.width * ui.lerpDouble(0.18, 0.38, growthT)!;
    for (var i = 0; i < count; i++) {
      final pos = Offset(
        base.dx + (rng.nextDouble() - 0.5) * spreadW * 2,
        base.dy + rng.nextDouble() * size.height * 0.018,
      );
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: 5, height: 2),
        Paint()
          ..color = CherryBlossomTreeVisuals.blossomPink
              .withValues(alpha: 0.25 + rng.nextDouble() * 0.25),
      );
    }
  }

  void _paintFivePetalFlower(
    Canvas canvas,
    Offset center,
    double size, {
    bool emphasize = false,
    Color? petalColor,
  }) {
    final color = petalColor ?? CherryBlossomTreeVisuals.blossomPink;
    for (var i = 0; i < 5; i++) {
      final a = i / 5 * math.pi * 2;
      final petalCenter =
          center + Offset(math.cos(a) * size * 0.55, math.sin(a) * size * 0.55);
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.45),
        Paint()..color = color.withValues(alpha: 0.92),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      math.max(1.2, size * 0.16),
      Paint()..color = CherryBlossomTreeVisuals.stamenYellow,
    );
    if (emphasize) {
      canvas.drawCircle(
        center + Offset(size * 0.05, -size * 0.05),
        size * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  void _paintFallingPetal(
    Canvas canvas,
    Size size,
    ({Offset pos, double opacity, double rotation, bool isFlower, double scale}) petal,
  ) {
    final center =
        Offset(size.width * petal.pos.dx, size.height * petal.pos.dy);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(petal.rotation);
    if (petal.isFlower) {
      _paintFivePetalFlower(canvas, Offset.zero, 6 * petal.scale, emphasize: true);
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 7 * petal.scale,
          height: 3.5 * petal.scale,
        ),
        Paint()
          ..color = CherryBlossomTreeVisuals.blossomPink
              .withValues(alpha: petal.opacity),
      );
    }
    canvas.restore();
  }

  void _paintGrowthHighlight(
    Canvas canvas,
    Size size,
    CherryBlossomTreeComposition composition,
    CherryBlossomGrowthFocus focus,
  ) {
    final rect = _focusBounds(size, composition, focus);
    final alpha = (0.22 * (1 - growthPulseT) + 0.08).clamp(0.08, 0.28);
    canvas.drawOval(
      rect.inflate(rect.width * 0.08),
      Paint()
        ..color = CherryBlossomTreeVisuals.blossomPink.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  Rect _focusBounds(
    Size size,
    CherryBlossomTreeComposition composition,
    CherryBlossomGrowthFocus focus,
  ) {
    switch (focus.kind) {
      case CherryBlossomGrowthKind.base:
        return Rect.fromCenter(
          center: Offset(composition.base.dx, composition.base.dy - composition.trunkH * 0.45),
          width: composition.trunkBaseW,
          height: composition.trunkH,
        );
      case CherryBlossomGrowthKind.branch:
        if (focus.slotIndex < composition.limbs.length) {
          final limb = composition.limbs[focus.slotIndex];
          return Rect.fromPoints(limb.origin, limb.end).inflate(12);
        }
        return Rect.fromCenter(
          center: composition.forkPoint,
          width: size.width * 0.2,
          height: size.height * 0.12,
        );
      case CherryBlossomGrowthKind.leaf:
        if (composition.clusters.isEmpty) {
          final ref = CherryBlossomReferenceTree.layout(size);
          if (ref.focusPoints.isEmpty) {
            return Rect.fromCenter(
              center: ref.canopyCenter,
              width: size.width * 0.15,
              height: size.height * 0.15,
            );
          }
          final idx = focus.slotIndex % ref.focusPoints.length;
          final c = ref.focusPoints[idx];
          return Rect.fromCenter(
            center: c,
            width: size.width * 0.06,
            height: size.width * 0.06,
          );
        }
        final idx = focus.slotIndex % composition.clusters.length;
        final c = composition.clusters[idx];
        return Rect.fromCenter(
          center: c.center,
          width: c.flowerSize * 4,
          height: c.flowerSize * 4,
        );
    }
  }

  void _withPop(Canvas canvas, Offset center, double pulse, VoidCallback draw) {
    if (pulse >= 0.999) {
      draw();
      return;
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse, pulse);
    canvas.translate(-center.dx, -center.dy);
    draw();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CherryBlossomTreePainter oldDelegate) {
    return oldDelegate.tree != tree ||
        oldDelegate.growthFocus != growthFocus ||
        oldDelegate.growthPulseT != growthPulseT ||
        oldDelegate.ambient != ambient ||
        oldDelegate.trunkTint != trunkTint;
  }
}
