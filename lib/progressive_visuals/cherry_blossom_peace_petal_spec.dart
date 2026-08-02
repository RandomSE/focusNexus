import 'dart:ui' show Color;

/// Pure constants and helpers for Serenity (peace finale) luminous petals.
abstract final class CherryBlossomPeacePetalSpec {
  CherryBlossomPeacePetalSpec._();

  static const int minConcurrent = 70; // 2x prior (35)
  static const int maxConcurrent = 90; // 2x prior (45)

  static const double backLayerShare = 0.40;
  static const double midLayerShare = 0.40;
  static const double frontLayerShare = 0.20;

  static const double luminousWhiteWeight = 0.50;
  static const double softBlushWeight = 0.35;
  static const double goldKissedWeight = 0.15;

  /// Base petal size in logical pixels (width x height).
  static const double baseWidth = 8;
  static const double baseHeight = 12;

  static const double fallDurationMinSec = 6;
  static const double fallDurationMaxSec = 14;

  static const double driftAmplitudeFactor = 0.06;
  static const double driftPeriodMinSec = 4;
  static const double driftPeriodMaxSec = 8;

  static const double rotationRadPerSecMin = 0.05;
  static const double rotationRadPerSecMax = 0.25;

  static const double groundFadeTravelFraction = 0.12;
  static const int pauseEveryNthPetal = 12;
  static const double pauseDurationMinSec = 0.8;
  static const double pauseDurationMaxSec = 1.5;

  // 1.5x frequency vs prior 1-3s pauses.
  static const double clusterPauseMinSec = 1.0 / 1.5;
  static const double clusterPauseMaxSec = 3.0 / 1.5;
  static const int clusterSizeMin = 3;
  static const int clusterSizeMax = 5;

  static PeacePetalType typeForRoll(double roll) {
    final t = roll.clamp(0.0, 1.0);
    if (t < luminousWhiteWeight) return PeacePetalType.luminousWhite;
    if (t < luminousWhiteWeight + softBlushWeight) {
      return PeacePetalType.softBlush;
    }
    return PeacePetalType.goldKissed;
  }

  static PeacePetalLayer layerForRoll(double roll) {
    final t = roll.clamp(0.0, 1.0);
    if (t < backLayerShare) return PeacePetalLayer.back;
    if (t < backLayerShare + midLayerShare) return PeacePetalLayer.mid;
    return PeacePetalLayer.front;
  }

  /// Size multiplier from population bucket roll (0..1).
  static double sizeScaleForRoll(double roll) {
    final t = roll.clamp(0.0, 1.0);
    if (t < 0.60) {
      return 0.5 + (t / 0.60) * 0.4; // 0.5 .. 0.9
    }
    if (t < 0.90) {
      final u = (t - 0.60) / 0.30;
      return 0.9 + u * 0.4; // 0.9 .. 1.3
    }
    final u = (t - 0.90) / 0.10;
    return 1.4 + u * 0.4; // 1.4 .. 1.8
  }
}

enum PeacePetalType { luminousWhite, softBlush, goldKissed }

enum PeacePetalLayer { back, mid, front }

extension PeacePetalLayerMods on PeacePetalLayer {
  double get scaleMul => switch (this) {
        PeacePetalLayer.back => 0.60,
        PeacePetalLayer.mid => 1.0,
        PeacePetalLayer.front => 1.30,
      };

  double get opacityMul => switch (this) {
        PeacePetalLayer.back => 0.55,
        PeacePetalLayer.mid => 0.80,
        PeacePetalLayer.front => 0.95,
      };

  double get speedMul => switch (this) {
        PeacePetalLayer.back => 0.70,
        PeacePetalLayer.mid => 1.0,
        PeacePetalLayer.front => 1.20,
      };

  bool get strongGlow => this == PeacePetalLayer.front;
}

extension PeacePetalTypeColors on PeacePetalType {
  Color get fillTop => switch (this) {
        PeacePetalType.luminousWhite => const Color(0xFFFFF8F8),
        PeacePetalType.softBlush => const Color(0xFFFFD4DE),
        PeacePetalType.goldKissed => const Color(0xFFFFF0D4),
      };

  Color get fillTip => switch (this) {
        PeacePetalType.luminousWhite => const Color(0xFFFFFFFF),
        PeacePetalType.softBlush => const Color(0xFFFFBDCC),
        PeacePetalType.goldKissed => const Color(0xFFFFE4B0),
      };

  Color? get blushEdge => switch (this) {
        PeacePetalType.luminousWhite => const Color(0xFFFFE8EC),
        PeacePetalType.softBlush => null,
        PeacePetalType.goldKissed => null,
      };

  double get opacityMin => switch (this) {
        PeacePetalType.luminousWhite => 0.70,
        PeacePetalType.softBlush => 0.60,
        PeacePetalType.goldKissed => 0.50,
      };

  double get opacityMax => switch (this) {
        PeacePetalType.luminousWhite => 0.95,
        PeacePetalType.softBlush => 0.85,
        PeacePetalType.goldKissed => 0.75,
      };

  /// Gold-kissed petals run slightly smaller on average.
  double get sizeBias => switch (this) {
        PeacePetalType.goldKissed => 0.85,
        _ => 1.0,
      };
}
