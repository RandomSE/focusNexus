import 'dart:ui';

/// Shared ids and tunables for Rain Catcher.
abstract final class RainCatcherConstants {
  /// Interpolated fill color that blends between adjacent tier colors.
  static Color gaugeFillColor(double gauge, {bool endless = false}) {
    final max = gaugeMaxFor(endless: endless);
    final marks = gaugeMarkValuesFor(endless: endless);
    final edges = <double>[0, ...marks.map((m) => m.toDouble())];
    final level = gauge.clamp(gaugeMin, max);
    final segments = edges.length - 1;
    for (var i = 0; i < segments; i++) {
      final lo = edges[i];
      final hi = edges[i + 1];
      if (level <= hi) {
        final colorIndex = ((i / segments) * (gaugeTierColors.length - 1))
            .floor()
            .clamp(0, gaugeTierColors.length - 1);
        final nextIndex = (colorIndex + 1).clamp(
          0,
          gaugeTierColors.length - 1,
        );
        final t = ((level - lo) / (hi - lo)).clamp(0.0, 1.0);
        return Color.lerp(
          gaugeTierColors[colorIndex],
          gaugeTierColors[nextIndex],
          t,
        )!;
      }
    }
    return gaugeTierColors.last;
  }

  /// Smooth fill color across numbered gauge tiers (audit palette).
  static Color gaugeColorForLevel(double gauge, {bool endless = false}) =>
      gaugeFillColor(gauge, endless: endless);

  static const String gameId = 'rain_catcher';
  static const String title = 'Rain Catcher';
  static const String description =
      'Drag or tap a lily pad to catch falling rain. Fill the water gauge over 90 seconds.';

  static const String padHint = 'Drag or tap to move the lily pad';

  static const int unlockCost = 150;
  static const int playCost = 70;
  static const int endlessCost = 110;
  static const int durationSeconds = 90;
  static const double baseDifficulty = 1.0;

  // --- Spawn / difficulty ---
  /// Near the 2/s landing cap so ~18-28 slow drops stay on screen.
  static const double baseSpawnPerSecond = 1.7;
  static const double durationRampExtra = 0.3;

  /// Minimum time between catchable-drop landings (pad / bottom).
  static const double minLandingIntervalSeconds = 0.5;

  static const double endlessStepSeconds = 20;
  static const double endlessSpawnStepIncrement = 0.08;
  static const double endlessSpeedStepIncrement = 0.06;

  /// Fall-speed factors vs the base [dropSpeedMin]/[dropSpeedMax] band.
  /// Duration uses the former Endless rate; Endless is one-third quicker than that.
  static const double durationFallSpeedFactor = 1.5;
  static const double endlessFallSpeedFactor = 2.0;

  /// Achievement ladders (round thresholds).
  static const int durationMaxAchievement = 150;
  static const List<int> durationTiers = [50, 75, 100, 125, 150];

  /// Endless score: glass marks x1.5 (45 steps) through 405.
  static const List<int> endlessTiers = [
    45,
    90,
    135,
    180,
    225,
    270,
    315,
    360,
    405,
  ];
  static const int endlessTarget = 405;

  static const int streakMaxAchievement = 120;
  static const List<int> streakTiers = [25, 50, 75, 100, 120];
  static const int endlessStreakTarget = 200;

  static const int targetActiveDropsMin = 18;
  static const int targetActiveDropsMax = 28;

  // --- Survival gauge ---
  /// Duration starts empty; Endless starts with a small buffer.
  static const double gaugeStartDuration = 0;
  static const double gaugeStartEndless = 5;
  static const double gaugeMin = 0;

  /// Duration glass marks (same bar height as Endless; fewer, taller tiers).
  static const double gaugeMaxDuration = 150;
  static const List<int> gaugeMarkValuesDuration = [30, 60, 90, 120, 150];

  /// Endless glass marks (same bar height; 45-step tiers up to 405).
  static const double gaugeMaxEndless = 405;
  static const List<int> gaugeMarkValuesEndless = [
    45,
    90,
    135,
    180,
    225,
    270,
    315,
    360,
    405,
  ];

  /// Back-compat alias for Duration max (tests / older call sites).
  static const double gaugeMax = gaugeMaxDuration;
  static const List<int> gaugeMarkValues = gaugeMarkValuesDuration;

  static double gaugeStartFor({required bool endless}) =>
      endless ? gaugeStartEndless : gaugeStartDuration;

  static double gaugeMaxFor({required bool endless}) =>
      endless ? gaugeMaxEndless : gaugeMaxDuration;

  static List<int> gaugeMarkValuesFor({required bool endless}) =>
      endless ? gaugeMarkValuesEndless : gaugeMarkValuesDuration;

  static const double gaugeCatchFill = 1.0;
  static const double gaugeMissDrain = 4.0;
  static const double gaugeRegenPerSecond = 0.35;
  static const int gaugeRegenStreakMin = 1;

  /// Gauge tier colors bottom -> top (calm blue / teal / soft green / gold / amber).
  /// No lime; soft green is #64C87A.
  static const List<Color> gaugeTierColors = [
    Color(0xFF4A90C4),
    Color(0xFF5AAA8A),
    Color(0xFF64C87A),
    Color(0xFFC4AA3A),
    Color(0xFFC45A3A),
  ];

  // Gauge chrome (shared with painter + spawn exclusion).
  static const double gaugeBarWidth = 16;
  static const double gaugeInset = 12;
  static const double gaugeVerticalInset = 96;
  static const double gaugeLabelReserve = 30;
  static const double gaugeSpawnPadding = 10;

  /// Right edge of playfield that catchable drops may use (left of gauge column).
  static double spawnMaxX(double playWidth) {
    return playWidth -
        gaugeInset -
        gaugeBarWidth -
        gaugeLabelReserve -
        gaugeSpawnPadding;
  }

  // --- Lily pad (circular pad) ---
  /// Diameter as a fraction of canvas width (garden-scale catch target).
  static const double padDiameterFraction = 0.20;

  /// Total V-notch opening at the rim (degrees). Half is cut on each side of +X.
  static const double padNotchDegrees = 32;

  /// Half-angle of the notch in radians (~16 deg for a 32 deg slice).
  static const double padNotchHalfRadians = padNotchDegrees * 0.5 * 3.141592653589793 / 180;

  /// Inset of the notch tip from pad center, as a fraction of radius.
  static const double padNotchTipInsetFraction = 0.14;

  static const double padBottomInset = 40;

  /// Hide the move hint after this many seconds of play.
  static const double padHintVisibleSeconds = 5;

  // --- Catchable raindrops (slow so many stay on screen with 0.5s landings) ---
  static const double dropBaseWidth = 3;
  static const double dropBaseHeightMin = 12;
  static const double dropBaseHeightMax = 18;
  static const double dropScaleMin = 0.6;
  static const double dropScaleMax = 1.4;
  /// Hit radius used for pad / miss collision (half of visual width * scale).
  static const double dropHitRadius = 6;
  static const double dropSpeedMin = 58;
  static const double dropSpeedMax = 78;
  static const Color dropColor = Color(0xFFA8D8F0);
  static const Color dropHighlight = Color(0x99FFFFFF);

  // --- Background rain (non-interactive atmosphere) ---
  static const int backgroundRainMin = 40;
  static const int backgroundRainMax = 50;
  static const double backgroundSpeedFactor = 1.5;
  /// Subtle wind lean from vertical (degrees). Foreground drops stay vertical.
  static const double backgroundRainLeanDegrees = 4;
  static const double backgroundRainLeanRadians =
      backgroundRainLeanDegrees * 3.141592653589793 / 180;
  static const Color backgroundRainColor = Color(0x148CC8DC);

  // --- FX ---
  static const double rippleLifeSeconds = 0.4;
  static const double missRippleLifeSeconds = 0.3;
  static const double catchParticleLifeSeconds = 0.5;
  static const double gaugeFlashSeconds = 0.1;
  static const double gaugeWavePeriodSeconds = 2.0;
  static const double gaugeWaveAmplitude = 3.0;

  static const double lightningIntervalMin = 15;
  static const double lightningIntervalMax = 25;
  static const double lightningFlashSeconds = 0.06;
  static const double lightningBoltSeconds = 0.08;

  static const String catchSoundAsset = 'sounds/rain_catch_click.mp3';
  static const String missSoundAsset = 'sounds/rain_miss.mp3';

  /// Spawn rate at [t]; capped by [minLandingIntervalSeconds].
  static double spawnRatePerSecond(double t, {bool endless = false}) {
    final ramp = durationRampExtra * (t / durationSeconds).clamp(0.0, 1.0);
    var rate = baseSpawnPerSecond + ramp;
    if (endless && t > durationSeconds) {
      final steps = ((t - durationSeconds) / endlessStepSeconds).floor();
      rate += steps * endlessSpawnStepIncrement;
    }
    final maxRate = 1.0 / minLandingIntervalSeconds;
    return rate > maxRate ? maxRate : rate;
  }

  /// Fall-speed multiplier: +20% Duration, +50% Endless, then Endless step ramp.
  static double speedMultiplier(double t, {bool endless = false}) {
    final mode = endless ? endlessFallSpeedFactor : durationFallSpeedFactor;
    if (endless && t > durationSeconds) {
      final steps = ((t - durationSeconds) / endlessStepSeconds).floor();
      return mode * (1.0 + steps * endlessSpeedStepIncrement);
    }
    return mode;
  }
}
