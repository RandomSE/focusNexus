/// Shared ids and tunables for Breath Pacer.
abstract final class BreathPacerConstants {
  static const String gameId = 'breath_pacer';
  static const String title = 'Breath Pacer';
  static const String description =
      'Follow Inhale, Hold, Exhale with a particle bloom and settle into a calm rhythm.';

  static const int unlockCost = 0;
  static const int playCost = 60;
  static const int endlessCost = 90;
  static const int durationSeconds = 90;
  static const double baseDifficulty = 1.0;

  /// Default Duration pattern: 4 in, 4 hold, 6 out, 2 hold.
  static const double inhaleSeconds = 4;
  static const double holdInSeconds = 4;
  static const double exhaleSeconds = 6;
  static const double holdOutSeconds = 2;

  static const int outerParticleCount = 36;
  static const int innerParticleCount = 24;

  static const double minRadiusFraction = 0.16;
  static const double maxRadiusFraction = 0.34;

  /// Tap grading windows against nearest phase transition.
  static const double perfectTapSeconds = 0.15;
  static const double goodTapSeconds = 0.40;

  static const int perfectTapPoints = 100;
  static const int goodTapPoints = 60;
  static const int missPenaltyPoints = 25;
  static const int rapidTapPenaltyPoints = 50;
  static const double rapidTapIntervalSeconds = 0.35;

  /// Inclusive score ceilings. Scores above the last ceiling use the final
  /// open-ended tier.
  static const List<int> scoreTierUpperBounds = [
    200,
    500,
    1000,
    1500,
    2500,
    5000,
  ];

  /// Endless becomes less forgiving after a normal Duration round has elapsed.
  static const double endlessHardModeWindowScale = 0.5;
  static const int endlessHardModePenaltyMultiplier = 2;

  /// Incoming ring contracts during this lead-in, then disappears when the
  /// perfect timing window opens.
  static const double transitionCueLeadSeconds = 1.0;

  static const double holdPulseSeconds = 1.5;
  static const double holdPulseRadiusPx = 2;
  static const double holdPulseOpacity = 0.05;

  static const double windDownSeconds = 10;
  static const double dawnStartRemainingSeconds = 60;

  /// Full listen length for Patient One (breath_background.mp3).
  static const double backgroundTrackSeconds = 8 * 60 + 50;

  static const String clickSoundAsset = 'sounds/breath_click.mp3';
  static const String backgroundSoundAsset =
      'sounds/music/breath_background.mp3';
}
