import 'dart:math' as math;
import 'dart:ui';

/// Shared ids and tunables for Word Bloom.
abstract final class WordBloomConstants {
  static const String gameId = 'word_bloom';
  static const String title = 'Word Bloom';
  static const String description =
      'Tap a glowing affirmation, gather the letters into their outline, and bloom into the next word.';

  static const int unlockCost = 200;
  static const int playCost = 80;
  static const int endlessCost = 120;
  static const int durationSeconds = 90;
  static const double baseDifficulty = 1.0;

  static const Color background = Color(0xFF0A0F18);

  /// Legacy ordinal scatter caps (kept for tests / FAQ energy notes).
  static const double scatterMaxWords1To3 = 300;
  static const double scatterMaxWords4To6 = 380;
  static const double scatterMaxWords7To9 = 500;
  static const double scatterMinSpeed = 200;
  static const double endlessScatterMultiplier = 1.15;

  /// Shatter targets land inside this fraction of the playfield (centered).
  static const double scatterPlayfieldFraction = 0.80;

  /// Minimum travel as a fraction of the shorter play axis.
  static const double scatterMinTravelFraction = 0.18;

  /// Soft min separation between letter targets (fraction of shorter axis).
  static const double scatterTargetSeparationFraction = 0.08;

  static const double velocityDecayPerFrame = 0.88;
  static const double edgeBounceRetain = 0.70;
  static const double nearStopSpeed = 12;
  static const double durationRandomWalkPx = 0.5;
  static const double endlessEdgeDriftPxPerSec = 8;

  static const double collectArcSeconds = 0.35;
  static const double collectArcLiftPx = 60;
  static const double collectPopSeconds = 0.15;
  static const double collectPopScale = 1.3;
  static const int collectParticleCount = 8;

  static const double bloomScalePeak = 1.08;
  /// ~60% shorter than the prior 0.4 / 1.5 / 0.6 bloom cadence.
  static const double bloomScaleSeconds = 0.16;
  static const double bloomHoldSeconds = 0.6;
  static const double transitionSeconds = 0.24;
  static const int completeParticleCount = 24;
  static const int goldBonusParticleCount = 24;

  /// Default glyph layout size (matches `(fontSize ?? 14) * 1.6` at default 14).
  static const double defaultLetterLayoutSize = 22;

  /// Caps playfield glyphs so Impeller atlas stays valid at large settings fonts
  /// (especially OpenDyslexic). Family still follows accessibility settings.
  static const double maxLetterLayoutSize = 24;

  /// Extra raster pad as a fraction of glyph font size so OpenDyslexic ascenders
  /// are not clipped when baking [ui.Image] glyphs (top ~1/6 cut otherwise).
  static const double glyphRasterPadFraction = 0.32;

  /// Line height used when laying out playfield glyphs (OpenDyslexic needs room).
  static const double glyphLineHeight = 1.35;

  /// Scales settings font into a playfield layout size with a hard ceiling.
  static double letterLayoutSizeForSettingsFont(double? settingsFontSize) {
    final raw = (settingsFontSize ?? 14) * 1.6;
    if (raw < 18) return 18;
    if (raw > maxLetterLayoutSize) return maxLetterLayoutSize;
    return raw;
  }

  static const double letterHitRadius = 30;
  static const double wordHitPadding = 36;

  /// Slot outline box at [defaultLetterLayoutSize]; painter scales with layout size.
  /// Sized to clear padded OpenDyslexic glyphs (taller than Latin defaults).
  static const double slotOutlineWidth = 34;
  static const double slotOutlineHeight = 46;

  static const double angularSpeedMin = 1;
  static const double angularSpeedMax = 4;

  static const String clickSoundAsset = 'sounds/word_bloom_click.mp3';
  static const String collectedSoundAsset = 'sounds/word_collected.mp3';

  /// Accent palette (breath pulse, trails, slots, bloom).
  static const List<Color> accentPalette = <Color>[
    Color(0xFFFFB7C5),
    Color(0xFFFFE566),
    Color(0xFF64FFC8),
    Color(0xFFB8A4E8),
    Color(0xFFFF9A6C),
  ];

  static const Color goldAccent = Color(0xFFFFD54A);

  /// Scatter speed cap for the current 1-based word ordinal.
  static double scatterMaxForOrdinal(int wordOrdinal) {
    if (wordOrdinal <= 3) return scatterMaxWords1To3;
    if (wordOrdinal <= 6) return scatterMaxWords4To6;
    return scatterMaxWords7To9;
  }

  /// Letter-length band for Duration / early Endless (1-based ordinal).
  /// Words 7+ allow up to 9 so longer standard words stay reachable without
  /// relying on the empty-band fallback.
  static (int minLen, int maxLen) lengthBandForOrdinal(int wordOrdinal) {
    if (wordOrdinal <= 3) return (4, 5);
    if (wordOrdinal <= 6) return (6, 7);
    return (7, 9);
  }

  /// Centered rectangle covering [scatterPlayfieldFraction] of [playSize].
  static Rect scatterBounds(Size playSize) {
    final insetX = playSize.width * (1 - scatterPlayfieldFraction) / 2;
    final insetY = playSize.height * (1 - scatterPlayfieldFraction) / 2;
    return Rect.fromLTRB(
      insetX,
      insetY,
      playSize.width - insetX,
      playSize.height - insetY,
    );
  }

  /// Initial speed so exponential decay coasts ~[distance] px (0.88 @ 60fps).
  static double coastSpeedForDistance(double distance) {
    final denom = -60 * math.log(velocityDecayPerFrame);
    if (denom <= 0) return distance;
    return distance * denom;
  }
}
