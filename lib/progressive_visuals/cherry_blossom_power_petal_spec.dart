import 'dart:ui' show Color;

/// Force-fragment petals for Power (Eternal Tree) finale.
abstract final class CherryBlossomPowerPetalSpec {
  CherryBlossomPowerPetalSpec._();

  static const int minConcurrent = 12;
  static const int maxConcurrent = 18;

  /// Crimson / burnt gold / deep violet / blackened ash.
  static const double crimsonWeight = 0.35;
  static const double burntGoldWeight = 0.25;
  static const double deepVioletWeight = 0.25;
  static const double ashWeight = 0.15;

  static const double crimsonSizeMinPx = 15;
  static const double crimsonSizeMaxPx = 24;
  static const double burntGoldSizeMinPx = 12;
  static const double burntGoldSizeMaxPx = 19.5;
  static const double deepVioletSizeMinPx = 12;
  static const double deepVioletSizeMaxPx = 20;
  static const double ashSizeMinPx = 9;
  static const double ashSizeMaxPx = 15;

  static const double slowFallMinSec = 5;
  static const double slowFallMaxSec = 9;
  static const double fastFallMinSec = 1.5;
  static const double fastFallMaxSec = 3.0;
  static const double slowFallChance = 0.60;

  /// Max total lateral travel as a fraction of canvas width.
  static const double driftAmplitudeFactor = 0.015;
  static const double driftPeriodMinSec = 6;
  static const double driftPeriodMaxSec = 10;
  static const double zeroDriftChance = 0.30;

  static const double fixedAngleChance = 0.65;
  static const double fixedAngleMaxRad = 0.3;
  static const double rotationRadPerSecMin = 0.08;
  static const double rotationRadPerSecMax = 0.2;

  /// Burst: 2-4 petals released within this window, then silence.
  static const double burstWindowSec = 0.8;
  static const int burstSizeMin = 2;
  static const int burstSizeMax = 4;
  static const double silenceMinSec = 2.5;
  static const double silenceMaxSec = 5.5;

  /// Rising deep-violet signature petal (excluded from concurrent cap).
  static const double risingPetalMinSec = 50;
  static const double risingPetalMaxSec = 80;
  static const double risingSpeedFactor = 0.4;
  static const double risingFadeInSec = 0.5;
  static const double risingFadeOutSec = 0.5;

  /// First 25% of fall ramps from this fraction of final speed via easeIn.
  static const double accelStartSpeedFactor = 0.40;
  static const double accelProgressEnd = 0.25;
  static const double coastProgressEnd = 0.85;

  /// Fall progress: luminous start ends; intensify peaks; ash fade begins.
  static const double luminousEndProgress = 0.22;
  static const double intensifyEndProgress = 0.62;
  static const double ashFadeStartProgress = 0.62;

  static const double opacityMin = 0.82;
  static const double opacityMax = 1.0;
  static const double ashOpacityMin = 0.55;
  static const double ashOpacityMax = 0.80;

  static const double emberPulseAmplitude = 0.06;
  static const double emberPulsePeriodMinSec = 2;
  static const double emberPulsePeriodMaxSec = 5;

  // --- Crimson (blood / raw energy) ---
  static const Color crimsonLuminous = Color(0xFFFF6B7A);
  static const Color crimsonCore = Color(0xFFC41E3A);
  static const Color crimsonIntense = Color(0xFF8B0018);
  static const Color crimsonGlow = Color(0xFFFF4D5E);

  // --- Burnt gold (corrupted glory) ---
  static const Color goldLuminous = Color(0xFFFFE08A);
  static const Color goldCore = Color(0xFFC9A227);
  static const Color goldIntense = Color(0xFF8B5A00);
  static const Color goldGlow = Color(0xFFE8C547);

  // --- Deep violet (mysticism / canopy tie) ---
  static const Color violetLuminous = Color(0xFFC39BD3);
  static const Color violetCore = Color(0xFF6C3483);
  static const Color violetIntense = Color(0xFF3B1A4A);
  static const Color violetGlow = Color(0xFF9B59B6);

  // --- Blackened ash (destruction / aftermath) ---
  static const Color ashLuminous = Color(0xFF8A8588);
  static const Color ashCore = Color(0xFF4A4548);
  static const Color ashIntense = Color(0xFF2C2A2B);
  static const Color ashGlow = Color(0xFF6E686C);

  /// Terminal ash all types fade into near the ground.
  static const Color ashEnd = Color(0xFF1A1819);
  static const Color ashEndTip = Color(0xFF0E0D0E);

  static PowerPetalType typeForRoll(double roll) {
    final t = roll.clamp(0.0, 1.0);
    if (t < crimsonWeight) return PowerPetalType.crimson;
    if (t < crimsonWeight + burntGoldWeight) return PowerPetalType.burntGold;
    if (t < crimsonWeight + burntGoldWeight + deepVioletWeight) {
      return PowerPetalType.deepViolet;
    }
    return PowerPetalType.ash;
  }

  static double sizePxForType(PowerPetalType type, double roll) {
    final t = roll.clamp(0.0, 1.0);
    return switch (type) {
      PowerPetalType.crimson =>
        crimsonSizeMinPx + t * (crimsonSizeMaxPx - crimsonSizeMinPx),
      PowerPetalType.burntGold =>
        burntGoldSizeMinPx + t * (burntGoldSizeMaxPx - burntGoldSizeMinPx),
      PowerPetalType.deepViolet =>
        deepVioletSizeMinPx + t * (deepVioletSizeMaxPx - deepVioletSizeMinPx),
      PowerPetalType.ash =>
        ashSizeMinPx + t * (ashSizeMaxPx - ashSizeMinPx),
    };
  }

  static (Color luminous, Color core, Color intense, Color glow) paletteFor(
    PowerPetalType type,
  ) {
    return switch (type) {
      PowerPetalType.crimson => (
          crimsonLuminous,
          crimsonCore,
          crimsonIntense,
          crimsonGlow,
        ),
      PowerPetalType.burntGold => (
          goldLuminous,
          goldCore,
          goldIntense,
          goldGlow,
        ),
      PowerPetalType.deepViolet => (
          violetLuminous,
          violetCore,
          violetIntense,
          violetGlow,
        ),
      PowerPetalType.ash => (ashLuminous, ashCore, ashIntense, ashGlow),
    };
  }
}

enum PowerPetalType { crimson, burntGold, deepViolet, ash }

extension PowerPetalTypeStyle on PowerPetalType {
  bool get pulses =>
      this == PowerPetalType.crimson || this == PowerPetalType.burntGold;
}
