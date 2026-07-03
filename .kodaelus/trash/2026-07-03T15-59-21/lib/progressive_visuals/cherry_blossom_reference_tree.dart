import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cherry_blossom_growth.dart';
import 'cherry_blossom_tree_visuals.dart';

/// Procedural perfect-stage sakura — recursive branch skeleton + cluster blossoms.
abstract final class CherryBlossomReferenceTree {
  CherryBlossomReferenceTree._();

  static const anchorXRatio = 0.50;
  static const anchorYRatio = 0.88;
  static const trunkHeightRatio = 0.28;
  static const trunkBaseWidthRatio = 0.062;
  static const canopyRxRatio = 0.44;

  /// Maximum individual blossom dot radius — 1.1% of canvas width.
  static const maxDotRadiusRatio = 0.011;

  static CherryBlossomReferenceTreeLayout layout(Size size) =>
      _PerfectTreeCache.layoutFor(size);

  static void paint(
    Canvas canvas,
    Size size, {
    Color? trunkTint,
    double Function(CherryBlossomGrowthKind kind, int slot)? pulseFor,
    double auroraT = 0,
    List<({Offset pos, double opacity})>? groundLandingPetals,
  }) {
    final treeLayout = layout(size);
    final pulse = pulseFor ?? (_, __) => 1.0;

    _paintCanopyGlow(canvas, treeLayout);

    if (auroraT != 0) {
      _paintPetalAurora(canvas, treeLayout, auroraT);
    }

    _paintDots(canvas, treeLayout.backDots, CherryBlossomTreeVisuals.blossomDeep, 0.70);
    _paintTrunk(canvas, treeLayout, trunkTint, pulse(CherryBlossomGrowthKind.base, 0));

    for (final branch in treeLayout.branches) {
      _paintBranch(canvas, branch);
    }

    _paintDarkLeaves(canvas, treeLayout);
    _paintDots(canvas, treeLayout.midDots, CherryBlossomTreeVisuals.blossomPink, 1.0);
    _paintDots(canvas, treeLayout.accentDots, CherryBlossomTreeVisuals.blossomShadow, 0.35);
    _paintDots(canvas, treeLayout.frontDots, CherryBlossomTreeVisuals.blossomCenter, 1.0);
    _paintDots(canvas, treeLayout.whiteDots, Colors.white, 0.50);

    for (final flower in treeLayout.flowers) {
      _paintFlower(canvas, flower.center, flower.size);
    }

    _paintGroundCarpet(canvas, treeLayout);
    _paintGroundPinkGlow(canvas, treeLayout);

    if (groundLandingPetals != null) {
      for (final p in groundLandingPetals) {
        canvas.drawOval(
          Rect.fromCenter(center: p.pos, width: 5, height: 2.5),
          Paint()
            ..color = CherryBlossomTreeVisuals.blossomPink
                .withValues(alpha: p.opacity),
        );
      }
    }
  }

  static bool inCanopy(double x, double y, CherryBlossomReferenceTreeLayout layout) =>
      layout.isInCanopy(x, y);

  static void _paintCanopyGlow(Canvas canvas, CherryBlossomReferenceTreeLayout layout) {
    final center = Offset(layout.canopyCenter.dx, layout.midY);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: layout.size.width * 0.92,
        height: layout.size.height * 0.52,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          layout.size.width * 0.46,
          const [Color(0x2EFFB7C5), Color(0x00FFB7C5)],
        ),
    );
  }

  static void _paintPetalAurora(
    Canvas canvas,
    CherryBlossomReferenceTreeLayout layout,
    double t,
  ) {
    final center = Offset(layout.canopyCenter.dx, layout.midY);
    final w = layout.size.width;
    for (final seed in layout.auroraSeeds) {
      final angle = seed.baseAngle + t * seed.speed * math.pi * 2;
      final radius = w * seed.radiusRatio;
      final rect = Rect.fromCenter(
        center: center + Offset(math.cos(angle) * radius * 0.3, math.sin(angle) * radius * 0.15),
        width: radius * 1.6,
        height: radius * 0.5,
      );
      canvas.drawArc(
        rect,
        angle,
        math.pi * 0.42,
        false,
        Paint()
          ..color = const Color(0x12FFB7C5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  static void _paintDots(
    Canvas canvas,
    List<CanopyDot> dots,
    Color color,
    double alpha,
  ) {
    final paint = Paint()..color = color.withValues(alpha: alpha);
    for (final dot in dots) {
      canvas.drawCircle(dot.center, dot.radius, paint);
    }
  }

  static void _paintDarkLeaves(Canvas canvas, CherryBlossomReferenceTreeLayout layout) {
    for (final leaf in layout.leaves) {
      canvas.save();
      canvas.translate(leaf.center.dx, leaf.center.dy);
      canvas.rotate(leaf.angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: leaf.width, height: leaf.height),
        Paint()..color = CherryBlossomTreeVisuals.leafGreen.withValues(alpha: 0.72),
      );
      canvas.restore();
    }
  }

  static void _paintTrunk(
    Canvas canvas,
    CherryBlossomReferenceTreeLayout layout,
    Color? trunkTint,
    double pulse,
  ) {
    final base = layout.base;
    final trunkH = layout.trunkH;
    final baseW = layout.trunkBaseW;
    final topW = layout.trunkTopW;
    final flareW = layout.size.width * 0.02;
    final center = Offset(base.dx, base.dy - trunkH * 0.5);

    void draw() {
      final path = Path()
        ..moveTo(base.dx - baseW * 0.5 - flareW, base.dy)
        ..quadraticBezierTo(
          base.dx - baseW * 0.55 - flareW,
          base.dy - trunkH * 0.08,
          base.dx - topW * 0.48,
          base.dy - trunkH,
        )
        ..lineTo(base.dx + topW * 0.48, base.dy - trunkH)
        ..quadraticBezierTo(
          base.dx + baseW * 0.55 + flareW,
          base.dy - trunkH * 0.08,
          base.dx + baseW * 0.5 + flareW,
          base.dy,
        )
        ..close();

      final top = Offset(base.dx, base.dy - trunkH);
      if (trunkTint != null) {
        canvas.drawPath(path, Paint()..color = trunkTint);
      } else {
        canvas.drawPath(
          path,
          Paint()
            ..shader = ui.Gradient.linear(
              top,
              base,
              const [Color(0xFF6B3A1F), Color(0xFF5C3317), Color(0xFF3D1F0A)],
              [0.0, 0.45, 1.0],
            ),
        );
      }

      for (var i = 0; i < layout.barkLines.length; i++) {
        canvas.drawPath(
          layout.barkLines[i],
          Paint()
            ..color = CherryBlossomTreeVisuals.rootBrown
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8 + (i % 3) * 0.15
            ..strokeCap = StrokeCap.round,
        );
      }
    }

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

  static void _paintBranch(Canvas canvas, PerfectBranch branch) {
    canvas.drawPath(
      branch.path,
      Paint()
        ..color = branch.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = branch.strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _paintFlower(Canvas canvas, Offset center, double size) {
    for (var petal = 0; petal < 5; petal++) {
      final angle = petal * 2 * math.pi / 5 - math.pi / 2;
      final petalCenter = center + Offset(
        math.cos(angle) * size * 0.55,
        math.sin(angle) * size * 0.55,
      );
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size * 0.85,
          height: size * 0.42,
        ),
        Paint()..color = CherryBlossomTreeVisuals.blossomPink,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      size * 0.18,
      Paint()..color = CherryBlossomTreeVisuals.stamenYellow,
    );
    for (var s = 0; s < 5; s++) {
      final sAngle = s * 2 * math.pi / 5;
      canvas.drawCircle(
        center + Offset(math.cos(sAngle) * size * 0.28, math.sin(sAngle) * size * 0.28),
        1.2,
        Paint()..color = const Color(0xFFFFCC00),
      );
    }
  }

  static void _paintGroundCarpet(Canvas canvas, CherryBlossomReferenceTreeLayout layout) {
    for (final p in layout.groundCarpet) {
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 5, height: 2),
        Paint()..color = CherryBlossomTreeVisuals.blossomPink.withValues(alpha: 0.55),
      );
    }
  }

  static void _paintGroundPinkGlow(Canvas canvas, CherryBlossomReferenceTreeLayout layout) {
    final center = Offset(layout.base.dx, layout.base.dy + layout.size.height * 0.01);
    canvas.drawCircle(
      center,
      layout.size.width * 0.22,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          layout.size.width * 0.22,
          const [Color(0x33FFB7C5), Color(0x00FFB7C5)],
        ),
    );
  }
}

final class _PerfectTreeCache {
  _PerfectTreeCache._();
  static final _cache = <String, CherryBlossomReferenceTreeLayout>{};

  static CherryBlossomReferenceTreeLayout layoutFor(Size size) {
    const gen = 'r4';
    final key = '${size.width}x${size.height}@$gen';
    return _cache.putIfAbsent(key, () => _buildLayout(size));
  }
}

CherryBlossomReferenceTreeLayout _buildLayout(Size size) {
  final w = size.width;
  final h = size.height;
  final anchorX = w * CherryBlossomReferenceTree.anchorXRatio;
  final anchorY = h * CherryBlossomReferenceTree.anchorYRatio;
  final base = Offset(anchorX, anchorY);
  final trunkH = h * CherryBlossomReferenceTree.trunkHeightRatio;
  final trunkBaseW = w * CherryBlossomReferenceTree.trunkBaseWidthRatio;
  final trunkTopW = trunkBaseW * 0.45;
  final rx = w * CherryBlossomReferenceTree.canopyRxRatio;

  final canopyTopY = base.dy - trunkH - h * 0.18;
  final midY = base.dy - trunkH * 0.55;
  final canopyCenter = Offset(w * 0.50, midY);

  final field = _CanopyField(
    w: w,
    h: h,
    rx: rx,
    canopyTopY: canopyTopY,
    midY: midY,
  );

  final skeleton = _buildSkeleton(
    anchorX: anchorX,
    anchorY: anchorY,
    trunkH: trunkH,
    trunkBaseW: trunkBaseW,
  );

  final maxDotR = w * CherryBlossomReferenceTree.maxDotRadiusRatio;
  final tipClusterR = w * 0.048;
  final innerClusterR = w * 0.032;
  final minClusterSpacing = w * 0.055;
  final rng = math.Random(311);

  final blossoms = _BlossomLayers();
  final clusterCenters = <Offset>[];
  final stripCounts = <int, int>{};
  const stripHeight = 10.0;

  for (final tip in skeleton.branchTips) {
    _generateCluster(
      center: tip,
      clusterRadius: tipClusterR,
      rng: rng,
      blossoms: blossoms,
      clusterCenters: clusterCenters,
      minSpacing: minClusterSpacing,
      stripCounts: stripCounts,
      stripHeight: stripHeight,
      maxDotR: maxDotR,
    );
  }

  for (final node in skeleton.innerNodes) {
    if (rng.nextDouble() >= 0.60) continue;
    _generateCluster(
      center: node.pos,
      clusterRadius: innerClusterR,
      rng: rng,
      blossoms: blossoms,
      clusterCenters: clusterCenters,
      minSpacing: minClusterSpacing,
      stripCounts: stripCounts,
      stripHeight: stripHeight,
      maxDotR: maxDotR,
    );
  }

  final flowerSize = w * 0.020;
  final flowers = <CanopyFlower>[];
  final tipPool = List<Offset>.from(skeleton.branchTips)..shuffle(rng);
  for (var i = 0; i < math.min(35, tipPool.length); i++) {
    flowers.add(CanopyFlower(center: tipPool[i], size: flowerSize));
  }

  final leafSize = w * 0.030;
  final nodePool = List<_InnerNode>.from(skeleton.innerNodes)..shuffle(rng);
  final leaves = <CanopyLeaf>[
    for (var i = 0; i < math.min(18, nodePool.length); i++)
      CanopyLeaf(
        center: nodePool[i].pos,
        width: leafSize,
        height: leafSize * 0.38,
        angle: nodePool[i].angle,
      ),
  ];

  final barkLines = <Path>[];
  final barkRng = math.Random(47);
  for (var i = 0; i < 6; i++) {
    final side = i.isEven ? -1.0 : 1.0;
    final x0 = base.dx + side * trunkBaseW * (0.15 + barkRng.nextDouble() * 0.25);
    barkLines.add(Path()
      ..moveTo(x0, base.dy - trunkH * 0.05)
      ..quadraticBezierTo(
        x0 + side * w * 0.008,
        base.dy - trunkH * 0.45,
        x0 - side * w * 0.004,
        base.dy - trunkH * 0.92,
      ));
  }

  final groundCarpet = <Offset>[
    for (var i = 0; i < 35; i++)
      Offset(
        base.dx + (math.Random(99 + i).nextDouble() - 0.5) * w * 0.38,
        base.dy + math.Random(99 + i).nextDouble() * h * 0.018,
      ),
  ];

  final petalSpawnPoints = <Offset>[
    for (var i = 0; i < 28; i++)
      Offset(
        w * 0.50 + (rng.nextDouble() - 0.5) * w * 0.86,
        canopyTopY + rng.nextDouble() * (midY - canopyTopY) * 0.25,
      ),
  ];

  final auroraSeeds = List.generate(6, (i) => (
        baseAngle: i / 6 * math.pi * 2,
        radiusRatio: 0.28 + (i % 3) * 0.08,
        speed: 1 / (14 + i * 1.5),
      ));

  final focusPoints = [
    ...clusterCenters,
    ...blossoms.midDots.map((d) => d.center),
    ...blossoms.frontDots.map((d) => d.center),
  ];

  final sideBottomY = field.bottomBoundAt(1.0);
  final centerBottomY = field.bottomBoundAt(0.0);

  return CherryBlossomReferenceTreeLayout(
    size: size,
    base: base,
    trunkH: trunkH,
    trunkBaseW: trunkBaseW,
    trunkTopW: trunkTopW,
    canopyCenter: canopyCenter,
    canopyRadiusX: rx,
    midY: midY,
    canopyTopY: canopyTopY,
    canopyBottomY: sideBottomY,
    canopyBottomCenterY: centerBottomY,
    canopyHeight: sideBottomY - canopyTopY,
    branches: skeleton.branches,
    branchTips: skeleton.branchTips,
    clusterCenters: clusterCenters,
    backDots: blossoms.backDots,
    midDots: blossoms.midDots,
    frontDots: blossoms.frontDots,
    whiteDots: blossoms.whiteDots,
    accentDots: blossoms.accentDots,
    flowers: flowers,
    leaves: leaves,
    barkLines: barkLines,
    groundCarpet: groundCarpet,
    petalSpawnPoints: petalSpawnPoints,
    auroraSeeds: auroraSeeds,
    focusPoints: focusPoints,
    isInCanopy: field.isInCanopy,
    maxDotRadius: maxDotR,
  );
}

class _CanopyField {
  _CanopyField({
    required this.w,
    required this.h,
    required this.rx,
    required this.canopyTopY,
    required this.midY,
  });

  final double w;
  final double h;
  final double rx;
  final double canopyTopY;
  final double midY;

  double get cx => w * 0.50;
  double get topRadius => midY - canopyTopY;

  double topBoundAt(double nx) =>
      midY - topRadius * math.sqrt(math.max(0, 1 - nx * nx));

  double bottomBoundAt(double nx) => midY + h * 0.08 + h * 0.046 * nx * nx;

  bool isInCanopy(double x, double y) {
    final nx = (x - cx) / rx;
    if (nx.abs() > 1.05) return false;
    return y >= topBoundAt(nx) && y <= bottomBoundAt(nx);
  }
}

class _SkeletonResult {
  final List<PerfectBranch> branches = [];
  final List<Offset> branchTips = [];
  final List<_InnerNode> innerNodes = [];
}

class _InnerNode {
  const _InnerNode({required this.pos, required this.angle});
  final Offset pos;
  final double angle;
}

_SkeletonResult _buildSkeleton({
  required double anchorX,
  required double anchorY,
  required double trunkH,
  required double trunkBaseW,
}) {
  final result = _SkeletonResult();

  void grow({
    required Offset start,
    required double angle,
    required double length,
    required double thickness,
    required int depth,
    required int maxDepth,
    required double asymmetrySeed,
  }) {
    if (depth > maxDepth || length < 4) return;

    final control = start + Offset(
      math.cos(angle) * length * 0.5,
      -math.sin(angle) * length * 0.5 - length * 0.12,
    );
    final end = start + Offset(
      math.cos(angle) * length,
      -math.sin(angle) * length + length * 0.15,
    );

    final color = Color.lerp(
      const Color(0xFF3D1F0A),
      const Color(0xFF7A4A2A),
      depth / maxDepth,
    )!;

    result.branches.add(PerfectBranch(
      path: Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy),
      strokeWidth: thickness,
      color: color,
    ));

    if (depth >= maxDepth) {
      result.branchTips.add(end);
      return;
    }

    if (depth >= 2 && depth <= 4) {
      final startFraction = 0.82 + math.sin(asymmetrySeed * 7.7) * 0.08;
      result.innerNodes.add(_InnerNode(
        pos: Offset(
          start.dx + (end.dx - start.dx) * startFraction,
          start.dy + (end.dy - start.dy) * startFraction,
        ),
        angle: angle,
      ));
    }

    final childCount = depth == 0 ? 3 : (depth <= 2 ? 2 : 1);
    final baseSpread = math.pi * (0.28 - depth * 0.025);
    final asymmetryOffset = (asymmetrySeed - 0.5) * 0.18;

    for (var i = 0; i < childCount; i++) {
      final fraction = childCount == 1 ? 0.5 : i / (childCount - 1);
      final wobble = math.sin(asymmetrySeed * 17.3 + i * 5.7) * 0.12;
      var childAngle = angle - baseSpread * (fraction - 0.5) * 2 + asymmetryOffset + wobble;

      // Keep branches angling upward (not drooping below horizontal).
      childAngle = childAngle.clamp(math.pi / 2 - 1.2, math.pi / 2 + 1.2);

      final lengthFactor = 0.62 + math.sin(asymmetrySeed * 13.1 + i * 3.3) * 0.12;
      final childLength = length * lengthFactor;
      final childThickness = thickness * (0.58 + i * 0.06);
      final startFraction = 0.82 + math.sin(asymmetrySeed * 7.7 + i) * 0.08;
      final childStart = Offset(
        start.dx + (end.dx - start.dx) * startFraction,
        start.dy + (end.dy - start.dy) * startFraction,
      );

      grow(
        start: childStart,
        angle: childAngle,
        length: childLength,
        thickness: childThickness,
        depth: depth + 1,
        maxDepth: maxDepth,
        asymmetrySeed: (asymmetrySeed * 1.618 + i * 0.382) % 1.0,
      );
    }
  }

  grow(
    start: Offset(anchorX, anchorY - trunkH * 0.68),
    angle: math.pi / 2 + 0.06,
    length: trunkH * 0.28,
    thickness: trunkBaseW * 0.52,
    depth: 0,
    maxDepth: 4,
    asymmetrySeed: 0.371,
  );
  grow(
    start: Offset(anchorX - trunkBaseW * 0.3, anchorY - trunkH * 0.66),
    angle: math.pi / 2 + 0.55,
    length: trunkH * 0.32,
    thickness: trunkBaseW * 0.48,
    depth: 0,
    maxDepth: 4,
    asymmetrySeed: 0.618,
  );
  grow(
    start: Offset(anchorX + trunkBaseW * 0.2, anchorY - trunkH * 0.64),
    angle: math.pi / 2 - 0.48,
    length: trunkH * 0.35,
    thickness: trunkBaseW * 0.50,
    depth: 0,
    maxDepth: 4,
    asymmetrySeed: 0.247,
  );
  grow(
    start: Offset(anchorX - trunkBaseW * 0.8, anchorY - trunkH * 0.42),
    angle: math.pi / 2 + 1.05,
    length: trunkH * 0.38,
    thickness: trunkBaseW * 0.40,
    depth: 0,
    maxDepth: 3,
    asymmetrySeed: 0.752,
  );
  grow(
    start: Offset(anchorX + trunkBaseW * 0.6, anchorY - trunkH * 0.44),
    angle: math.pi / 2 - 0.98,
    length: trunkH * 0.42,
    thickness: trunkBaseW * 0.42,
    depth: 0,
    maxDepth: 3,
    asymmetrySeed: 0.133,
  );

  return result;
}

class _BlossomLayers {
  final backDots = <CanopyDot>[];
  final midDots = <CanopyDot>[];
  final frontDots = <CanopyDot>[];
  final whiteDots = <CanopyDot>[];
  final accentDots = <CanopyDot>[];
}

void _generateCluster({
  required Offset center,
  required double clusterRadius,
  required math.Random rng,
  required _BlossomLayers blossoms,
  required List<Offset> clusterCenters,
  required double minSpacing,
  required Map<int, int> stripCounts,
  required double stripHeight,
  required double maxDotR,
}) {
  if (clusterCenters.any((c) => (c - center).distance < minSpacing)) return;
  clusterCenters.add(center);

  const goldenAngle = 2.399963;
  final dotCount = 8 + rng.nextInt(9);

  for (var i = 0; i < dotCount; i++) {
    final r = clusterRadius * math.sqrt((i + 0.5) / dotCount);
    final theta = i * goldenAngle + rng.nextDouble() * 0.4;
    final dotPos = center + Offset(math.cos(theta) * r, math.sin(theta) * r);

    final strip = (dotPos.dy / stripHeight).floor();
    final stripCount = stripCounts[strip] ?? 0;
    if (stripCount > 12 && rng.nextDouble() > 0.30) continue;
    stripCounts[strip] = stripCount + 1;

    final distFromCenter = clusterRadius > 0 ? r / clusterRadius : 0.0;
    final rawRadius = clusterRadius * (distFromCenter < 0.3 ? 0.18 : distFromCenter < 0.7 ? 0.22 : 0.20);
    final dotRadius = math.min(rawRadius, maxDotR);

    final dot = CanopyDot(center: dotPos, radius: dotRadius);
    if (distFromCenter < 0.3) {
      blossoms.backDots.add(dot);
      blossoms.accentDots.add(dot);
    } else if (distFromCenter < 0.7) {
      blossoms.midDots.add(dot);
    } else {
      blossoms.frontDots.add(dot);
    }
  }

  for (var i = 0; i < 2; i++) {
    final highlightPos = center + Offset(
      rng.nextDouble() * clusterRadius * 0.4 - clusterRadius * 0.2,
      -clusterRadius * (0.5 + rng.nextDouble() * 0.3),
    );
    blossoms.whiteDots.add(CanopyDot(
      center: highlightPos,
      radius: math.min(clusterRadius * 0.14, maxDotR),
    ));
  }
}

class CherryBlossomReferenceTreeLayout {
  const CherryBlossomReferenceTreeLayout({
    required this.size,
    required this.base,
    required this.trunkH,
    required this.trunkBaseW,
    required this.trunkTopW,
    required this.canopyCenter,
    required this.canopyRadiusX,
    required this.midY,
    required this.canopyTopY,
    required this.canopyBottomY,
    required this.canopyBottomCenterY,
    required this.canopyHeight,
    required this.branches,
    required this.branchTips,
    required this.clusterCenters,
    required this.backDots,
    required this.midDots,
    required this.frontDots,
    required this.whiteDots,
    required this.accentDots,
    required this.flowers,
    required this.leaves,
    required this.barkLines,
    required this.groundCarpet,
    required this.petalSpawnPoints,
    required this.auroraSeeds,
    required this.focusPoints,
    required this.isInCanopy,
    required this.maxDotRadius,
  });

  final Size size;
  final Offset base;
  final double trunkH;
  final double trunkBaseW;
  final double trunkTopW;
  final Offset canopyCenter;
  final double canopyRadiusX;
  final double midY;
  final double canopyTopY;
  final double canopyBottomY;
  final double canopyBottomCenterY;
  final double canopyHeight;
  final List<PerfectBranch> branches;
  final List<Offset> branchTips;
  final List<Offset> clusterCenters;
  final List<CanopyDot> backDots;
  final List<CanopyDot> midDots;
  final List<CanopyDot> frontDots;
  final List<CanopyDot> whiteDots;
  final List<CanopyDot> accentDots;
  final List<CanopyFlower> flowers;
  final List<CanopyLeaf> leaves;
  final List<Path> barkLines;
  final List<Offset> groundCarpet;
  final List<Offset> petalSpawnPoints;
  final List<({double baseAngle, double radiusRatio, double speed})> auroraSeeds;
  final List<Offset> focusPoints;
  final bool Function(double x, double y) isInCanopy;
  final double maxDotRadius;

  double get canopySpanWidth => canopyRadiusX * 2;
}

class PerfectBranch {
  const PerfectBranch({
    required this.path,
    required this.strokeWidth,
    required this.color,
  });

  final Path path;
  final double strokeWidth;
  final Color color;

  Offset get tip {
    final metrics = path.computeMetrics().first;
    return metrics.getTangentForOffset(metrics.length)?.position ?? Offset.zero;
  }
}

class CanopyDot {
  const CanopyDot({required this.center, required this.radius});
  final Offset center;
  final double radius;
}

class CanopyFlower {
  const CanopyFlower({required this.center, required this.size});
  final Offset center;
  final double size;
}

class CanopyLeaf {
  const CanopyLeaf({
    required this.center,
    required this.width,
    required this.height,
    required this.angle,
  });
  final Offset center;
  final double width;
  final double height;
  final double angle;
}
