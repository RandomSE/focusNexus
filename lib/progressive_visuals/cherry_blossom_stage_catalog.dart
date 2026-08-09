import 'package:flutter/material.dart';

import 'cherry_blossom_prestige_path.dart';

/// Stage metadata, costs, assets, and scale rules for image-based cherry trees.
abstract final class CherryBlossomStageCatalog {
  CherryBlossomStageCatalog._();

  static const int levelsPerStage = 25;
  static const int maxPlayableStage = 6;
  static const int finaleStage = 7;

  /// Stage investment totals (FU-1 geometric 0-5; stage 6 kept at 1_000_000).
  /// Series ~4x: 500, 2000, 8000, 32000, 128000, 512000, 1000000.
  /// Stage sum 1,682,500; with first path switch 1,782,500.
  static const List<int> _stageTotals = [
    500,
    2000,
    8000,
    32000,
    128000,
    512000,
    1000000,
  ];

  static const List<String> _stageNames = [
    'Bare Beginning',
    'Early Spring Morning',
    'Midday Spring',
    'Golden Afternoon',
    'Deep Twilight',
    'Aurora Veil',
    'Living Canopy',
  ];

  static const List<String> _finaleNames = [
    'Serenity',
    'Power',
  ];

  static final List<List<int>> _stageCosts = _buildAllStageCosts();

  static int get stageCount => _stageTotals.length;

  static int grandTotalToMaxStage6() =>
      _stageTotals.fold<int>(0, (sum, total) => sum + total);

  static const int pathSwitchCost = 100000;

  static int maxGrowthStepsForStage(int stageIndex) {
    if (stageIndex == finaleStage) return 1;
    return levelsPerStage - 1;
  }

  static String displayNameFor({
    required int stageIndex,
    CherryBlossomPrestigePath? prestigePath,
  }) {
    if (stageIndex == finaleStage) {
      return switch (prestigePath) {
        CherryBlossomPrestigePath.peace => _finaleNames[0],
        CherryBlossomPrestigePath.power => _finaleNames[1],
        null => 'Finale',
      };
    }
    return _stageNames[stageIndex.clamp(0, _stageNames.length - 1)];
  }

  static String assetPathFor({
    required int stageIndex,
    CherryBlossomPrestigePath? prestigePath,
  }) {
    if (stageIndex == finaleStage) {
      return switch (prestigePath) {
        CherryBlossomPrestigePath.peace =>
          'assets/images/cherry_blossom_tree/stage_7a.png',
        CherryBlossomPrestigePath.power =>
          'assets/images/cherry_blossom_tree/stage_7b.png',
        null => 'assets/images/cherry_blossom_tree/stage_7a.png',
      };
    }
    return 'assets/images/cherry_blossom_tree/stage_$stageIndex.png';
  }

  static bool usesProgrammaticBackground(int stageIndex) =>
      stageIndex >= 0 && stageIndex <= 5;

  /// Legacy RGB paper knockout. Off for stages 0-5 (true-alpha PNGs);
  /// multiply washes authored colors into the sky.
  static bool usesMultiplyBlend(int stageIndex, int growthStepsInStage) =>
      false;

  /// Stages 0-5 ship as true-alpha RGBA PNGs under assets/images/cherry_blossom_tree/.
  static bool usesTrueAlphaAsset(int stageIndex) =>
      stageIndex >= 0 && stageIndex <= 5;

  static bool usesFullBleedImage(int stageIndex) => stageIndex >= 6;

  /// Stages 6-7: image covers the viewport when fully grown in that stage.
  static bool fillsViewport(int stageIndex, int growthStepsInStage) {
    if (stageIndex == finaleStage) return true;
    if (stageIndex == maxPlayableStage) {
      return growthStepsInStage >= levelsPerStage - 1;
    }
    return false;
  }

  /// Stages 0-5: contain so wide canopies (e.g. Midday Spring) are not
  /// side-clipped by fitHeight in portrait viewports / View tree.
  static BoxFit imageFitFor({
    required int stageIndex,
    required bool fullBleed,
  }) {
    if (stageIndex >= 6) return BoxFit.cover;
    return BoxFit.contain;
  }

  /// Vertical draw height; tree is bottom-anchored at y = viewport bottom.
  static double treeHeightFraction({
    required int stageIndex,
    required int growthStepsInStage,
  }) {
    if (stageIndex == finaleStage) return 1.0;
    final level = displayLevel(
      stageIndex: stageIndex,
      growthStepsInStage: growthStepsInStage,
    );
    final t = levelsPerStage <= 1 ? 1.0 : (level - 1) / (levelsPerStage - 1);
    if (stageIndex == maxPlayableStage) {
      return _lerp(0.78, 1.0, t);
    }
    if (stageIndex <= 1) {
      return _lerp(0.62, 0.94, t);
    }
    return _lerp(0.58, 0.92, t);
  }

  /// Max [treeHeightFraction] for the stage (level cap). Used as fixed draw box.
  static double maxTreeHeightFraction(int stageIndex) {
    return treeHeightFraction(
      stageIndex: stageIndex,
      growthStepsInStage: maxGrowthStepsForStage(stageIndex),
    );
  }

  /// Scale relative to [maxTreeHeightFraction] so growth expands from baseline.
  static double growthScaleRelativeToMax({
    required int stageIndex,
    required int growthStepsInStage,
  }) {
    final maxH = maxTreeHeightFraction(stageIndex);
    if (maxH <= 0) return 1.0;
    final current = treeHeightFraction(
      stageIndex: stageIndex,
      growthStepsInStage: growthStepsInStage,
    );
    return (current / maxH).clamp(0.0, 1.0);
  }

  /// Transparent padding below trunk in stage PNGs (fraction of height).
  /// Measured from current true-alpha assets (opaque alpha > 8).
  static double contentBottomPaddingFraction(int stageIndex) {
    const pads = <double>[
      0.1268, // 0 Bare Beginning
      0.2467, // 1 Early Spring Morning (tree high in frame)
      0.1380, // 2 Midday Spring
      0.1081, // 3 Golden Afternoon
      0.0716, // 4 Deep Twilight
      0.0, // 5 Aurora Veil
      0.0, // 6
      0.0, // 7
    ];
    final i = stageIndex.clamp(0, pads.length - 1);
    return pads[i];
  }

  /// Extra downward nudge as a fraction of viewport height (fixes residual float).
  static double seatingBiasFraction(int stageIndex) {
    return switch (stageIndex) {
      // Deep Twilight: alpha fringe below bark reads as ~10% float above ground.
      4 => 0.10,
      3 => 0.015,
      5 => 0.02, // Aurora Veil pad ~0 under-seats in bonsai pots
      0 => 0.01,
      _ => 0.0,
    };
  }

  /// Alignment.y for [Transform.scale] so the content baseline stays fixed.
  /// pad=0 -> 1.0 (image bottom); pad=0.15 -> 0.7.
  static double contentBaselineAlignmentY(double paddingFraction) {
    return 1.0 - 2.0 * paddingFraction.clamp(0.0, 0.5);
  }

  /// [Positioned.bottom] so trunk baseline sits on the painted ground top
  /// (`groundInsetFraction`), not floating above it.
  static double treeLayerBottomOffset({
    required int stageIndex,
    required double viewportHeight,
    required double drawHeight,
  }) {
    if (stageIndex >= 5) return 0.0;
    return _baselineSeatBottom(
      stageIndex: stageIndex,
      viewportHeight: viewportHeight,
      drawHeight: drawHeight,
    );
  }

  /// Bonsai pots: seat stages 0-5 on the painted ground strip (includes Aurora).
  static double bonsaiTreeBottomOffset({
    required int stageIndex,
    required double cellHeight,
    required double drawHeight,
  }) {
    if (stageIndex >= 6) return 0.0;
    return _baselineSeatBottom(
      stageIndex: stageIndex,
      viewportHeight: cellHeight,
      drawHeight: drawHeight,
    );
  }

  static double _baselineSeatBottom({
    required int stageIndex,
    required double viewportHeight,
    required double drawHeight,
  }) {
    final pad = contentBottomPaddingFraction(stageIndex);
    final groundTop = viewportHeight * groundInsetFraction;
    final baselineFromWidgetBottom = pad * drawHeight;
    final bias = viewportHeight * seatingBiasFraction(stageIndex);
    return groundTop - baselineFromWidgetBottom - bias;
  }

  /// Soil fill color for stage-matched UI accents (matches ground strips).
  static Color groundFillColorFor(int stageIndex) {
    return switch (stageIndex) {
      0 => const Color(0xFF6B4F2A),
      1 => const Color(0xFF7A5C32),
      2 => const Color(0xFF8A6A3A),
      3 => const Color(0xFF6B4A24),
      4 || 5 => const Color(0xFF3A2410),
      _ => const Color(0xFF1A1018),
    };
  }

  /// Stages 4-5: multiply over dark sky crushes authored tree colors.
  static bool needsNightContrastBoost(int stageIndex) =>
      stageIndex == 4 || stageIndex == 5;

  static const double groundInsetFraction = 0.14;

  /// Bonsai slot: tree fill height as fraction of cell (stages 0-5).
  static double bonsaiTreeHeightFraction(int stageIndex) {
    if (stageIndex >= 6) return 1.0;
    return 0.96;
  }

  static bool bonsaiFillsSlot(int stageIndex) => stageIndex >= 6;

  static bool usesAliveEffects(int stageIndex) => stageIndex >= 6;

  /// Letterbox / scaffold behind the viewport.
  static Color scaffoldColorFor(int stageIndex) {
    if (stageIndex <= 5) {
      return switch (stageIndex) {
        0 => const Color(0xFFC8D8E0),
        1 => const Color(0xFFD4E8F0),
        2 => const Color(0xFFC8E4F4),
        3 => const Color(0xFF8FB0C4),
        4 => const Color(0xFF2E2248),
        5 => const Color(0xFF241E40),
        _ => const Color(0xFFC8D8E0),
      };
    }
    return const Color(0xFF050510);
  }

  /// HUD level denominator (25 for stages 0-6, 1 for finale).
  static int levelCapForStage(int stageIndex) =>
      stageIndex == finaleStage ? 1 : levelsPerStage;

  /// Visible level from completed growth steps in the current stage.
  static int displayLevel({
    required int stageIndex,
    required int growthStepsInStage,
  }) {
    if (stageIndex == finaleStage) return 1;
    return (growthStepsInStage + 1).clamp(1, levelsPerStage);
  }

  /// Scale for tree image; bottom-anchored in the viewport.
  static double scaleFor({
    required int stageIndex,
    required int growthStepsInStage,
  }) {
    if (stageIndex == finaleStage) return 1.0;
    final level = displayLevel(
      stageIndex: stageIndex,
      growthStepsInStage: growthStepsInStage,
    );
    final t = levelsPerStage <= 1 ? 1.0 : (level - 1) / (levelsPerStage - 1);
    if (stageIndex <= 1) {
      return _lerp(1.0, 1.18, t);
    }
    if (stageIndex == maxPlayableStage) {
      return _lerp(0.60, 1.0, t);
    }
    return _lerp(0.60, 1.0, t);
  }

  static int? costForGrow({
    required int stageIndex,
    required int growthStepsInStage,
  }) {
    if (stageIndex == finaleStage) return null;
    if (growthStepsInStage >= levelsPerStage - 1) return null;
    return _stageCosts[stageIndex][growthStepsInStage];
  }

  /// Cost to prestige at max level (same as the final grow would have been).
  static int? costForPrestige({
    required int stageIndex,
    required int growthStepsInStage,
  }) {
    if (stageIndex == finaleStage) return null;
    if (growthStepsInStage < levelsPerStage - 1) return null;
    return _stageCosts[stageIndex][levelsPerStage - 1];
  }

  static int totalInvestedThrough({
    required int stageIndex,
    required int growthStepsInStage,
  }) {
    var total = 0;
    for (var stage = 0; stage < stageIndex; stage++) {
      total += _stageTotals[stage];
    }
    if (stageIndex <= maxPlayableStage && growthStepsInStage > 0) {
      final costs = _stageCosts[stageIndex];
      final steps = growthStepsInStage.clamp(0, costs.length);
      for (var i = 0; i < steps; i++) {
        total += costs[i];
      }
    }
    return total;
  }

  static List<int> stageCostsFor(int stageIndex) =>
      List<int>.unmodifiable(_stageCosts[stageIndex]);

  static int stageTotalFor(int stageIndex) => _stageTotals[stageIndex];

  static List<List<int>> _buildAllStageCosts() {
    return [
      for (final total in _stageTotals) _distributeFlat(total, levelsPerStage),
    ];
  }

  /// Flat per-level cost within a stage; sums exactly to [total].
  /// Stage totals are chosen to divide evenly by [levelsPerStage] for round numbers.
  static List<int> _distributeFlat(int total, int steps) {
    if (steps <= 0) return const [];
    if (steps == 1) return [total];
    assert(
      total % steps == 0,
      'stage total $total must divide evenly by $steps for flat round costs',
    );
    final each = total ~/ steps;
    return List<int>.filled(steps, each);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
