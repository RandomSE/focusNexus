import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cherry_blossom_tree_sequence.dart';
import 'cherry_blossom_tree_state.dart';

/// Blossom depth layer for dome fill ordering.
enum CherryBlossomDomeLayer { back, mid, front, highlight }

/// One curved limb segment (quadratic bezier).
class CherryBlossomLimb {
  const CherryBlossomLimb({
    required this.origin,
    required this.control,
    required this.end,
    required this.strokeWidth,
    this.colorValue = 0,
  });

  final Offset origin;
  final Offset control;
  final Offset end;
  final double strokeWidth;
  /// 0 trunk, 1 mid, 2 tertiary.
  final int colorValue;
}

/// One blossom cluster in the dome fill grid.
class CherryBlossomDomeCluster {
  const CherryBlossomDomeCluster({
    required this.center,
    required this.layer,
    required this.flowerSize,
    required this.flowerCount,
    required this.useFivePetals,
    this.highlight = 0,
  });

  final Offset center;
  final CherryBlossomDomeLayer layer;
  final double flowerSize;
  final int flowerCount;
  final bool useFivePetals;
  /// 0–1 pale top-lit strength.
  final double highlight;
}

/// Reference-accurate tree skeleton + branch-anchored blossom clusters.
class CherryBlossomTreeComposition {
  const CherryBlossomTreeComposition({
    required this.base,
    required this.trunkH,
    required this.trunkBaseW,
    required this.forkPoint,
    required this.canopyCenter,
    required this.canopyRadiusX,
    required this.canopyRadiusY,
    required this.limbs,
    required this.clusters,
    required this.bandProgress,
    required this.seedlingBuds,
    required this.petalSpawnPoints,
  });

  final Offset base;
  final double trunkH;
  final double trunkBaseW;
  final Offset forkPoint;
  final Offset canopyCenter;
  final double canopyRadiusX;
  final double canopyRadiusY;
  final List<CherryBlossomLimb> limbs;
  final List<CherryBlossomDomeCluster> clusters;
  final double bandProgress;
  final List<Offset> seedlingBuds;
  /// Canopy-local origins for falling petals (pixel coordinates).
  final List<Offset> petalSpawnPoints;

  static CherryBlossomTreeComposition forStep(
    Size size,
    int completedSteps,
    CherryBlossomVisualBand band,
  ) {
    final w = size.width;
    final h = size.height;
    final base = Offset(w * 0.5, h * CherryBlossomTreeComposition._anchorY);
    final bandT = _progressWithinBand(completedSteps, band);
    final metrics = _lerpMetrics(band, bandT);

    final trunkH = h * metrics.trunkHRatio;
    final trunkBaseW = w * metrics.trunkBaseWRatio;
    final forkPoint = Offset(base.dx, base.dy - trunkH * metrics.forkTrunkFraction);
    final canopyRadiusX = w * metrics.canopyRadiusXRatio;
    final canopyRadiusY = h * metrics.canopyRadiusYRatio;
    final canopyCenter = Offset(
      base.dx,
      forkPoint.dy - canopyRadiusY * 0.42,
    );

    final limbs = _buildLimbs(
      forkPoint: forkPoint,
      base: base,
      size: size,
      metrics: metrics,
      canopyRadiusX: canopyRadiusX,
      band: band,
      bandT: bandT,
    );

    final clusters = _buildClusters(
      limbs: limbs,
      forkPoint: forkPoint,
      canopyCenter: canopyCenter,
      canopyRadiusX: canopyRadiusX,
      canopyRadiusY: canopyRadiusY,
      band: band,
      bandT: bandT,
      w: w,
    );

    final seedlingBuds = band == CherryBlossomVisualBand.seedling
        ? _seedlingBuds(base, trunkH, w, bandT)
        : const <Offset>[];

    final petalSpawnPoints = _petalSpawnPoints(
      clusters: clusters,
      limbs: limbs,
      forkPoint: forkPoint,
      band: band,
    );

    return CherryBlossomTreeComposition(
      base: base,
      trunkH: trunkH,
      trunkBaseW: trunkBaseW,
      forkPoint: forkPoint,
      canopyCenter: canopyCenter,
      canopyRadiusX: canopyRadiusX,
      canopyRadiusY: canopyRadiusY,
      limbs: limbs,
      clusters: clusters,
      bandProgress: bandT,
      seedlingBuds: seedlingBuds,
      petalSpawnPoints: petalSpawnPoints,
    );
  }

  static const _anchorY = 0.88;

  static double _progressWithinBand(
    int steps,
    CherryBlossomVisualBand band,
  ) {
    final (start, end) = switch (band) {
      CherryBlossomVisualBand.seedling => (0, CherryBlossomTreeSequence.stepsAt1k),
      CherryBlossomVisualBand.basic => (
          CherryBlossomTreeSequence.stepsAt1k,
          CherryBlossomTreeSequence.stepsAt10k,
        ),
      CherryBlossomVisualBand.good => (
          CherryBlossomTreeSequence.stepsAt10k,
          CherryBlossomTreeSequence.stepsAt100k,
        ),
      CherryBlossomVisualBand.great => (
          CherryBlossomTreeSequence.stepsAt100k,
          CherryBlossomTreeSequence.stepsAt1m,
        ),
      CherryBlossomVisualBand.perfect => (
          CherryBlossomTreeSequence.stepsAt1m,
          CherryBlossomTreeSequence.stepsAt1m,
        ),
    };
    if (end <= start) return 1.0;
    return ((steps - start) / (end - start)).clamp(0.0, 1.0);
  }

  static _BandMetrics _lerpMetrics(CherryBlossomVisualBand band, double bandT) {
    final target = _metricsFor(band);
    final prev = _metricsFor(_previousBand(band));
    return _BandMetrics(
      trunkHRatio: ui.lerpDouble(prev.trunkHRatio, target.trunkHRatio, bandT)!,
      trunkBaseWRatio:
          ui.lerpDouble(prev.trunkBaseWRatio, target.trunkBaseWRatio, bandT)!,
      forkTrunkFraction: ui.lerpDouble(
        prev.forkTrunkFraction,
        target.forkTrunkFraction,
        bandT,
      )!,
      canopyRadiusXRatio: ui.lerpDouble(
        prev.canopyRadiusXRatio,
        target.canopyRadiusXRatio,
        bandT,
      )!,
      canopyRadiusYRatio: ui.lerpDouble(
        prev.canopyRadiusYRatio,
        target.canopyRadiusYRatio,
        bandT,
      )!,
      limbCount: (prev.limbCount + (target.limbCount - prev.limbCount) * bandT)
          .round()
          .clamp(0, 8),
      clusterCount:
          (prev.clusterCount + (target.clusterCount - prev.clusterCount) * bandT)
              .round(),
      flowerDensity: ui.lerpDouble(prev.flowerDensity, target.flowerDensity, bandT)!,
      fivePetalRatio:
          ui.lerpDouble(prev.fivePetalRatio, target.fivePetalRatio, bandT)!,
    );
  }

  static CherryBlossomVisualBand _previousBand(CherryBlossomVisualBand band) =>
      switch (band) {
        CherryBlossomVisualBand.seedling => CherryBlossomVisualBand.seedling,
        CherryBlossomVisualBand.basic => CherryBlossomVisualBand.seedling,
        CherryBlossomVisualBand.good => CherryBlossomVisualBand.basic,
        CherryBlossomVisualBand.great => CherryBlossomVisualBand.good,
        CherryBlossomVisualBand.perfect => CherryBlossomVisualBand.great,
      };

  static _BandMetrics _metricsFor(CherryBlossomVisualBand band) => switch (band) {
        CherryBlossomVisualBand.seedling => const _BandMetrics(
            trunkHRatio: 0.08,
            trunkBaseWRatio: 0.022,
            forkTrunkFraction: 0.85,
            canopyRadiusXRatio: 0.06,
            canopyRadiusYRatio: 0.05,
            limbCount: 0,
            clusterCount: 0,
            flowerDensity: 0.2,
            fivePetalRatio: 0,
          ),
        CherryBlossomVisualBand.basic => const _BandMetrics(
            trunkHRatio: 0.14,
            trunkBaseWRatio: 0.038,
            forkTrunkFraction: 0.55,
            canopyRadiusXRatio: 0.22,
            canopyRadiusYRatio: 0.16,
            limbCount: 4,
            clusterCount: 12,
            flowerDensity: 0.45,
            fivePetalRatio: 0.35,
          ),
        CherryBlossomVisualBand.good => const _BandMetrics(
            trunkHRatio: 0.17,
            trunkBaseWRatio: 0.048,
            forkTrunkFraction: 0.42,
            canopyRadiusXRatio: 0.32,
            canopyRadiusYRatio: 0.22,
            limbCount: 6,
            clusterCount: 28,
            flowerDensity: 0.65,
            fivePetalRatio: 0.55,
          ),
        CherryBlossomVisualBand.great => const _BandMetrics(
            trunkHRatio: 0.20,
            trunkBaseWRatio: 0.058,
            forkTrunkFraction: 0.28,
            canopyRadiusXRatio: 0.42,
            canopyRadiusYRatio: 0.30,
            limbCount: 8,
            clusterCount: 72,
            flowerDensity: 1.0,
            fivePetalRatio: 0.92,
          ),
        CherryBlossomVisualBand.perfect => const _BandMetrics(
            trunkHRatio: 0.19,
            trunkBaseWRatio: 0.068,
            forkTrunkFraction: 0.26,
            canopyRadiusXRatio: 0.46,
            canopyRadiusYRatio: 0.28,
            limbCount: 6,
            clusterCount: 0,
            flowerDensity: 1.0,
            fivePetalRatio: 1.0,
          ),
      };

  /// Primary limb angles (° from +x); wide low split per reference.
  static const _limbAngles = <double>[
    155, 125, 58, 32, 148, 22,
  ];

  static List<CherryBlossomLimb> _buildLimbs({
    required Offset forkPoint,
    required Offset base,
    required Size size,
    required _BandMetrics metrics,
    required double canopyRadiusX,
    required CherryBlossomVisualBand band,
    required double bandT,
  }) {
    if (metrics.limbCount <= 0) return const [];

    final h = size.height;
    final limbs = <CherryBlossomLimb>[];
    for (var i = 0; i < metrics.limbCount; i++) {
      final angleDeg = _limbAngles[i % _limbAngles.length];
      final length = canopyRadiusX * (0.90 + (i % 3) * 0.05) * bandT.clamp(0.4, 1.0);
      final dir = _direction(angleDeg);
      final tangentEnd = forkPoint + dir * length;
      final droop = h * (0.018 + (i % 4) * 0.006);
      final end = Offset(tangentEnd.dx, tangentEnd.dy + droop);
      final lift = h * 0.028;
      final ctrl = Offset(
        (forkPoint.dx + tangentEnd.dx) * 0.5,
        math.min(forkPoint.dy, tangentEnd.dy) - lift,
      );
      final stroke = (5.5 + (metrics.limbCount - i) * 0.9) *
          (size.width / 360).clamp(0.75, 1.35);
      limbs.add(CherryBlossomLimb(
        origin: forkPoint,
        control: ctrl,
        end: end,
        strokeWidth: stroke,
        colorValue: i >= 6 ? 2 : i >= 4 ? 1 : 0,
      ));

      if (band.index >= CherryBlossomVisualBand.good.index && bandT > 0.35) {
        final subOrigin = Offset(
          forkPoint.dx + (end.dx - forkPoint.dx) * 0.55,
          forkPoint.dy + (end.dy - forkPoint.dy) * 0.55,
        );
        final subDir = _direction(angleDeg + (i.isEven ? 18 : -18));
        final subLen = length * 0.48;
        final subTangent = subOrigin + subDir * subLen;
        final subEnd = Offset(subTangent.dx, subTangent.dy + droop * 0.5);
        limbs.add(CherryBlossomLimb(
          origin: subOrigin,
          control: Offset(
            (subOrigin.dx + subTangent.dx) * 0.5,
            math.min(subOrigin.dy, subTangent.dy) - lift * 0.4,
          ),
          end: subEnd,
          strokeWidth: stroke * 0.42,
          colorValue: 1,
        ));

        if (band == CherryBlossomVisualBand.perfect && bandT > 0.85) {
          final twigOrigin = Offset(
            subOrigin.dx + (subEnd.dx - subOrigin.dx) * 0.62,
            subOrigin.dy + (subEnd.dy - subOrigin.dy) * 0.62,
          );
          final twigDir = _direction(angleDeg + (i.isEven ? 32 : -28));
          final twigLen = subLen * 0.38;
          final twigTangent = twigOrigin + twigDir * twigLen;
          final twigEnd = Offset(twigTangent.dx, twigTangent.dy + droop * 0.35);
          limbs.add(CherryBlossomLimb(
            origin: twigOrigin,
            control: Offset(
              (twigOrigin.dx + twigTangent.dx) * 0.5,
              math.min(twigOrigin.dy, twigTangent.dy) - lift * 0.25,
            ),
            end: twigEnd,
            strokeWidth: stroke * 0.22,
            colorValue: 2,
          ));
        }
      }
    }

    if (band == CherryBlossomVisualBand.perfect && bandT > 0.85) {
      for (final angleDeg in [98.0, 82.0, 110.0]) {
        final dir = _direction(angleDeg);
        final twigLen = h * 0.055;
        final twigEnd = forkPoint + dir * twigLen;
        limbs.add(CherryBlossomLimb(
          origin: forkPoint,
          control: Offset(
            (forkPoint.dx + twigEnd.dx) * 0.5,
            forkPoint.dy - h * 0.02,
          ),
          end: twigEnd,
          strokeWidth: (size.width / 360).clamp(0.75, 1.35) * 2.8,
          colorValue: 1,
        ));
      }
    }

    return limbs;
  }

  static List<CherryBlossomDomeCluster> _buildClusters({
    required List<CherryBlossomLimb> limbs,
    required Offset forkPoint,
    required Offset canopyCenter,
    required double canopyRadiusX,
    required double canopyRadiusY,
    required CherryBlossomVisualBand band,
    required double bandT,
    required double w,
  }) {
    if (band.index < CherryBlossomVisualBand.basic.index) return const [];
    if (band.index >= CherryBlossomVisualBand.great.index) {
      return _buildBranchAnchoredClusters(
        limbs: limbs,
        forkPoint: forkPoint,
        canopyCenter: canopyCenter,
        w: w,
        band: band,
        bandT: bandT,
        dense: band == CherryBlossomVisualBand.perfect,
      );
    }
    return _buildBranchAnchoredClusters(
      limbs: limbs,
      forkPoint: forkPoint,
      canopyCenter: canopyCenter,
      w: w,
      band: band,
      bandT: bandT,
      dense: false,
    );
  }

  /// Blossoms only along visible branch geometry — no free-floating dome fill.
  static List<CherryBlossomDomeCluster> _buildBranchAnchoredClusters({
    required List<CherryBlossomLimb> limbs,
    required Offset forkPoint,
    required Offset canopyCenter,
    required double w,
    required CherryBlossomVisualBand band,
    required double bandT,
    required bool dense,
  }) {
    if (limbs.isEmpty) return const [];

    final metrics = _metricsFor(band);
    final rng = math.Random(101 + band.index + (dense ? 7 : 0));
    final clusters = <CherryBlossomDomeCluster>[];

    for (var li = 0; li < limbs.length; li++) {
      final limb = limbs[li];
      final isPrimary = limb.colorValue == 0;
      final isTertiary = limb.colorValue == 2;

      final sampleTs = dense
          ? (isPrimary
              ? [0.32, 0.48, 0.62, 0.76, 0.86, 0.94, 0.99]
              : isTertiary
                  ? [0.72, 0.88, 0.97]
                  : [0.50, 0.68, 0.84, 0.95, 0.99])
          : (isPrimary
              ? [0.55, 0.78, 0.94]
              : [0.70, 0.92]);

      for (final t in sampleTs) {
        if (t > bandT.clamp(0.45, 1.0) + 0.02 && band != CherryBlossomVisualBand.perfect) {
          continue;
        }

        final point = _quadraticPoint(limb.origin, limb.control, limb.end, t);
        final tangent = _quadraticTangent(limb.origin, limb.control, limb.end, t);
        final normal = _normalize(Offset(-tangent.dy, tangent.dx));

        final canopyTop = canopyCenter.dy - w * 0.14;
        final isUpper = point.dy < canopyTop + w * 0.04;
        final layer = isUpper && t > 0.82
            ? CherryBlossomDomeLayer.highlight
            : t < 0.42
                ? CherryBlossomDomeLayer.back
                : t > 0.88
                    ? CherryBlossomDomeLayer.front
                    : li.isEven
                        ? CherryBlossomDomeLayer.mid
                        : CherryBlossomDomeLayer.front;

        final sizeScale = isPrimary ? 1.05 : (isTertiary ? 0.78 : 0.9);
        final flowerSize = w *
            (0.010 + t * 0.011) *
            sizeScale *
            (layer == CherryBlossomDomeLayer.highlight ? 1.12 : 1.0);
        final flowerCount = dense
            ? (3 + ((t - 0.25) * 10).round()).clamp(3, isPrimary && t > 0.9 ? 11 : 8)
            : (3 + ((t - 0.4) * 5).round()).clamp(3, 6);
        final useFive =
            rng.nextDouble() < metrics.fivePetalRatio * bandT.clamp(0.5, 1.0);

        final jitterAlong =
            tangent * ((rng.nextDouble() - 0.5) * w * (dense ? 0.004 : 0.003));
        final jitterNormal = t >= 0.96
            ? Offset.zero
            : normal * ((rng.nextDouble() - 0.5) * w * (dense ? 0.006 : 0.005));

        clusters.add(CherryBlossomDomeCluster(
          center: point + jitterAlong + jitterNormal,
          layer: layer,
          flowerSize: flowerSize,
          flowerCount: flowerCount,
          useFivePetals: useFive || dense,
          highlight: layer == CherryBlossomDomeLayer.highlight
              ? 0.55 + rng.nextDouble() * 0.35
              : 0,
        ));

        if (dense && t > 0.72) {
          for (var s = 0; s < (isPrimary ? 2 : 1); s++) {
            final satT = (t + rng.nextDouble() * 0.05).clamp(0.0, 1.0);
            final satPoint =
                _quadraticPoint(limb.origin, limb.control, limb.end, satT);
            final satTangent =
                _quadraticTangent(limb.origin, limb.control, limb.end, satT);
            final satNormal = _normalize(Offset(-satTangent.dy, satTangent.dx));
            clusters.add(CherryBlossomDomeCluster(
              center: satPoint +
                  satNormal * (rng.nextDouble() - 0.5) * w * 0.007,
              layer: t > 0.9
                  ? CherryBlossomDomeLayer.front
                  : CherryBlossomDomeLayer.mid,
              flowerSize: flowerSize * 0.82,
              flowerCount: 3 + rng.nextInt(3),
              useFivePetals: true,
              highlight: 0,
            ));
          }
        }
      }
    }

    return clusters;
  }

  static List<Offset> _petalSpawnPoints({
    required List<CherryBlossomDomeCluster> clusters,
    required List<CherryBlossomLimb> limbs,
    required Offset forkPoint,
    required CherryBlossomVisualBand band,
  }) {
    if (band.index < CherryBlossomVisualBand.basic.index) return const [];

    final points = <Offset>[];
    for (final limb in limbs) {
      points.add(_quadraticPoint(limb.origin, limb.control, limb.end, 0.88));
      points.add(limb.end);
    }
    for (final cluster in clusters) {
      if (cluster.center.dy > forkPoint.dy - 8) {
        points.add(cluster.center);
      }
    }
    if (points.isEmpty) {
      return [forkPoint];
    }
    return points;
  }

  static Offset _quadraticPoint(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }

  static Offset _quadraticTangent(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      2 * u * (b.dx - a.dx) + 2 * t * (c.dx - b.dx),
      2 * u * (b.dy - a.dy) + 2 * t * (c.dy - b.dy),
    );
  }

  static Offset _normalize(Offset v) {
    final len = math.sqrt(v.dx * v.dx + v.dy * v.dy);
    if (len < 0.0001) return const Offset(0, 1);
    return Offset(v.dx / len, v.dy / len);
  }

  static List<Offset> _seedlingBuds(Offset base, double trunkH, double w, double t) {
    final tip = Offset(base.dx, base.dy - trunkH);
    return [
      tip,
      tip + Offset(-w * 0.018 * t, w * 0.012 * t),
      tip + Offset(w * 0.018 * t, w * 0.012 * t),
    ];
  }

  static Offset _direction(double angleDeg) {
    final rad = angleDeg * math.pi / 180;
    return Offset(math.cos(rad), -math.sin(rad));
  }
}

class _BandMetrics {
  const _BandMetrics({
    required this.trunkHRatio,
    required this.trunkBaseWRatio,
    required this.forkTrunkFraction,
    required this.canopyRadiusXRatio,
    required this.canopyRadiusYRatio,
    required this.limbCount,
    required this.clusterCount,
    required this.flowerDensity,
    required this.fivePetalRatio,
  });

  final double trunkHRatio;
  final double trunkBaseWRatio;
  final double forkTrunkFraction;
  final double canopyRadiusXRatio;
  final double canopyRadiusYRatio;
  final int limbCount;
  final int clusterCount;
  final double flowerDensity;
  final double fivePetalRatio;
}
