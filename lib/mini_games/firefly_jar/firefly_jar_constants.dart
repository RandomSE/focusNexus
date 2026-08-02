/// Shared ids and tunables for Firefly Jar.
abstract final class FireflyJarConstants {
  static const String gameId = 'firefly_jar';
  static const String title = 'Firefly Jar';
  static const String description =
      'Tap glowing fireflies as they drift. Fill the jar over 90 seconds.';

  static const int durationSeconds = 90;
  static const int jarFillCapacity = 36;
  static const double endlessTickSeconds = 15;

  /// Standard Duration start. Endless total = playCost + endlessCost.
  static const int unlockCost = 0;
  static const int playCost = 60;
  static const int endlessCost = 100;
  static const double baseDifficulty = 1.0;

  static const double catchRadius = 32;
  static const double jarWidthFraction = 0.22;
  static const int baseActiveCount = 7;
  static const double spawnMargin = 24;

  static const double coreRadius = 4;
  static const double pulsePeriodMin = 1.2;
  static const double pulsePeriodMax = 2.8;
  static const double pulseScaleMin = 0.6;
  static const double pulseScaleMax = 1.0;

  static const int starCountMin = 18;
  static const int starCountMax = 24;

  static const double catchBurstLife = 0.3;
  static const double catchStreakLife = 0.5;
  static const double catchFlareLife = 0.12;
  static const double jarBoostLife = 0.4;

  /// Endless: mild early ticks, then faster ramp after Duration length.
  static const double endlessOvertimeTickSeconds = 8;
  static const double endlessEarlyDifficultyStep = 0.03;
  static const double endlessOvertimeDifficultyStep = 0.12;
  static const double endlessOvertimeMotionStep = 0.15;

  static const int jarPlaceCols = 4;
  static const int jarPlaceRows = 5;

  /// Body-normalized fill height at full jar (bottom up toward neck).
  static const double jarMassHeightFraction = 0.94;

  /// Top of the mass band at full fill (start of the jar neck opening).
  static const double jarMassTopNyAtFull = 0.06;
  static const double jarMassBottomNy = 0.93;
  static const double jarMassLeftNx = 0.12;
  static const double jarMassRightNx = 0.88;

  /// Soft blend when remapping older jar dots into an expanded fill band.
  static const double jarRedistributeBlend = 0.45;

  static double jarMassTopNy(double fill) {
    final clamped = fill.clamp(0.0, 1.0);
    return (1.0 - jarMassHeightFraction * clamped).clamp(
      jarMassTopNyAtFull,
      jarMassBottomNy - 0.05,
    );
  }

  static const String clickSoundAsset = 'sounds/firefly_click.mp3';
}
