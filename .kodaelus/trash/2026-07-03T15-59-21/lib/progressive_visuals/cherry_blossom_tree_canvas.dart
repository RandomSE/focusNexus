import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'cherry_blossom_growth.dart';
import 'cherry_blossom_reference_tree.dart';
import 'cherry_blossom_tree_composition.dart';
import 'cherry_blossom_tree_painter.dart';
import 'cherry_blossom_tree_state.dart';

/// Animated tree canvas with ambient effects and growth pop-in support.
class CherryBlossomTreeCanvas extends StatefulWidget {
  const CherryBlossomTreeCanvas({
    super.key,
    required this.tree,
    this.growthFocus,
    this.growthPulseT = 1,
    this.trunkTint,
    required this.size,
  });

  final CherryBlossomTreeState tree;
  final CherryBlossomGrowthFocus? growthFocus;
  final double growthPulseT;
  final Color? trunkTint;
  final Size size;

  @override
  State<CherryBlossomTreeCanvas> createState() => _CherryBlossomTreeCanvasState();
}

class _CherryBlossomTreeCanvasState extends State<CherryBlossomTreeCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  late List<_PetalSeed> _petalSeeds;
  late List<_FireflySeed> _fireflySeeds;
  late List<_GroundPetalSeed> _groundPetalSeeds;

  @override
  void initState() {
    super.initState();
    _rebuildSeeds();
    _ticker = createTicker(_onTick);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant CherryBlossomTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tree.visualBand != oldWidget.tree.visualBand ||
        widget.tree.growthStepIndex != oldWidget.tree.growthStepIndex ||
        widget.size != oldWidget.size) {
      _rebuildSeeds();
      _syncTicker();
    }
  }

  void _rebuildSeeds() {
    _petalSeeds = _buildPetalSeeds(widget.size, widget.tree);
    _fireflySeeds = _buildFireflySeeds();
    _groundPetalSeeds = _buildGroundPetalSeeds(widget.size);
  }

  void _syncTicker() {
    final band = widget.tree.visualBand;
    final needsAmbient = band.index >= CherryBlossomVisualBand.basic.index;
    if (needsAmbient && !_ticker.isActive) {
      _ticker.start();
    } else if (!needsAmbient && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    setState(() => _elapsed = elapsed);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<_PetalSeed> _buildPetalSeeds(Size size, CherryBlossomTreeState tree) {
    final band = tree.visualBand;
    final count = switch (band) {
      CherryBlossomVisualBand.basic => 4,
      CherryBlossomVisualBand.good => 4,
      CherryBlossomVisualBand.great => 10,
      CherryBlossomVisualBand.perfect => 28,
      _ => 0,
    };
    if (count <= 0) return const [];

    final layout = band == CherryBlossomVisualBand.perfect
        ? CherryBlossomReferenceTree.layout(size)
        : null;
    final composition = layout == null
        ? CherryBlossomTreeComposition.forStep(size, tree.growthStepIndex, band)
        : null;

    final spawnPoints = layout?.petalSpawnPoints ?? composition!.petalSpawnPoints;
    final baseY = layout?.base.dy ?? composition!.base.dy;
    final endY = (baseY + size.height * 0.015) / size.height;
    final canopyTop = layout != null
        ? layout.canopyTopY / size.height
        : endY - 0.35;

    final rng = math.Random(7);
    return List.generate(count, (i) {
      final spawn = spawnPoints[i % spawnPoints.length];
      final startX = (spawn.dx / size.width).clamp(0.06, 0.94);
      final startY = band == CherryBlossomVisualBand.perfect
          ? canopyTop.clamp(0.08, endY - 0.12)
          : (spawn.dy / size.height).clamp(0.12, endY - 0.04);
      final isFlower = band == CherryBlossomVisualBand.perfect
          ? i < 10
          : band.index >= CherryBlossomVisualBand.great.index &&
              rng.nextDouble() < 0.28;
      return _PetalSeed(
        startX: startX,
        startY: startY,
        endY: endY,
        delaySeconds: rng.nextDouble() * 6,
        fallSeconds: 3.5 + rng.nextDouble() * 3.5,
        driftAmplitude: size.width * 0.03,
        driftHz: 0.4 + rng.nextDouble() * 0.4,
        windPerSecond: (rng.nextDouble() < 0.2 ? -1 : 1) * size.width * 0.006 / size.width,
        rotationSpeed: 0.4 + rng.nextDouble() * 1.6,
        phase: rng.nextDouble() * math.pi * 2,
        isFlower: isFlower,
        scale: 0.7 + rng.nextDouble() * 0.7,
      );
    });
  }

  List<_FireflySeed> _buildFireflySeeds() {
    final colors = <Color>[
      Colors.white,
      Colors.white,
      Colors.white,
      Colors.white,
      Colors.white,
      Colors.white,
      Colors.white,
      const Color(0xFFFFFACD),
      const Color(0xFFFFFACD),
      const Color(0xFFFFD4E0),
    ];
    final rng = math.Random(19);
    return List.generate(10, (i) {
      return _FireflySeed(
        x: 0.22 + rng.nextDouble() * 0.56,
        phase: rng.nextDouble(),
        riseSeconds: 4 + rng.nextDouble() * 5,
        driftHz: 0.35 + rng.nextDouble() * 0.25,
        color: colors[i],
      );
    });
  }

  List<_GroundPetalSeed> _buildGroundPetalSeeds(Size size) {
    final layout = CherryBlossomReferenceTree.layout(size);
    final rng = math.Random(83);
    return List.generate(8, (i) {
      return _GroundPetalSeed(
        x: 0.5 + (rng.nextDouble() - 0.5) * 0.34,
        delaySeconds: i * 1.2 + rng.nextDouble() * 2,
        fallSeconds: 4 + rng.nextDouble() * 4,
        startY: layout.canopyTopY / size.height,
        endY: (layout.base.dy + size.height * 0.012) / size.height,
      );
    });
  }

  CherryBlossomAmbientState _ambientFor(CherryBlossomVisualBand band) {
    final seconds = _elapsed.inMilliseconds / 1000.0;
    final ambientT = (seconds % 4) / 4;
    final auroraT = (seconds % 18) / 18;
    final sway = band.index >= CherryBlossomVisualBand.great.index
        ? math.sin(seconds / 6 * math.pi * 2) * 0.014
        : 0.0;

    final petals = <({Offset pos, double opacity, double rotation, bool isFlower, double scale})>[];
    if (band.index >= CherryBlossomVisualBand.basic.index) {
      for (final seed in _petalSeeds) {
        final elapsed = seconds - seed.delaySeconds;
        if (elapsed < 0) continue;
        final cycle = elapsed % seed.fallSeconds;
        final t = cycle / seed.fallSeconds;
        final y = seed.startY + t * (seed.endY - seed.startY);
        final drift = math.sin((cycle * seed.driftHz + seed.phase) * math.pi * 2) *
            (seed.driftAmplitude / widget.size.width);
        final wind = t * seed.windPerSecond;
        final opacity = t < 0.8 ? 0.92 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
        petals.add((
          pos: Offset((seed.startX + drift + wind).clamp(0.04, 0.96), y),
          opacity: opacity,
          rotation: seed.phase + seconds * seed.rotationSpeed,
          isFlower: seed.isFlower,
          scale: seed.scale,
        ));
      }
    }

    final fireflies = <({Offset pos, double opacity, Color color})>[];
    if (band == CherryBlossomVisualBand.perfect) {
      final layout = CherryBlossomReferenceTree.layout(widget.size);
      final canopyBottom = layout.canopyBottomY / widget.size.height;
      final canopyTop = layout.canopyTopY / widget.size.height;
      for (final seed in _fireflySeeds) {
        final cycle = (seconds + seed.phase * seed.riseSeconds) % seed.riseSeconds;
        final t = cycle / seed.riseSeconds;
        final y = canopyBottom - t * (canopyBottom - canopyTop);
        final drift = math.sin((seconds * seed.driftHz + seed.phase) * math.pi * 2) *
            (widget.size.width * 0.018 / widget.size.width);
        final opacity = (math.sin(t * math.pi) * 0.65 + 0.2).clamp(0.1, 0.85);
        fireflies.add((
          pos: Offset((seed.x + drift).clamp(0.08, 0.92), y),
          opacity: opacity,
          color: seed.color,
        ));
      }
    }

    final groundLandingPetals = <({Offset pos, double opacity})>[];
    if (band == CherryBlossomVisualBand.perfect) {
      for (final seed in _groundPetalSeeds) {
        final elapsed = seconds - seed.delaySeconds;
        if (elapsed < 0 || elapsed > seed.fallSeconds) continue;
        final t = elapsed / seed.fallSeconds;
        final y = seed.startY + t * (seed.endY - seed.startY);
        final opacity = t < 0.85 ? 0.7 : (1 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
        groundLandingPetals.add((
          pos: Offset(seed.x * widget.size.width, y * widget.size.height),
          opacity: opacity,
        ));
      }
    }

    return CherryBlossomAmbientState(
      ambientT: ambientT,
      auroraT: auroraT,
      swayRadians: sway,
      petals: petals,
      fireflies: fireflies,
      groundLandingPetals: groundLandingPetals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final band = widget.tree.visualBand;
    return CustomPaint(
      size: widget.size,
      painter: CherryBlossomTreePainter(
        tree: widget.tree,
        growthFocus: widget.growthFocus,
        growthPulseT: widget.growthPulseT,
        trunkTint: widget.trunkTint,
        ambient: _ambientFor(band),
      ),
    );
  }
}

class _PetalSeed {
  const _PetalSeed({
    required this.startX,
    required this.startY,
    required this.endY,
    required this.delaySeconds,
    required this.fallSeconds,
    required this.driftAmplitude,
    required this.driftHz,
    required this.windPerSecond,
    required this.rotationSpeed,
    required this.phase,
    required this.isFlower,
    required this.scale,
  });

  final double startX;
  final double startY;
  final double endY;
  final double delaySeconds;
  final double fallSeconds;
  final double driftAmplitude;
  final double driftHz;
  final double windPerSecond;
  final double rotationSpeed;
  final double phase;
  final bool isFlower;
  final double scale;
}

class _FireflySeed {
  const _FireflySeed({
    required this.x,
    required this.phase,
    required this.riseSeconds,
    required this.driftHz,
    required this.color,
  });

  final double x;
  final double phase;
  final double riseSeconds;
  final double driftHz;
  final Color color;
}

class _GroundPetalSeed {
  const _GroundPetalSeed({
    required this.x,
    required this.delaySeconds,
    required this.fallSeconds,
    required this.startY,
    required this.endY,
  });

  final double x;
  final double delaySeconds;
  final double fallSeconds;
  final double startY;
  final double endY;
}
