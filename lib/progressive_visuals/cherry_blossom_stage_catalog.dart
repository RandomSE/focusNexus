import 'package:flutter/material.dart';

import 'cherry_blossom_prestige_path.dart';

/// Stage metadata, costs, assets, and scale rules for image-based cherry trees.
abstract final class CherryBlossomStageCatalog {
  CherryBlossomStageCatalog._();

  static const int levelsPerStage = 25;
  static const int maxPlayableStage = 6;
  static const int finaleStage = 7;

  static const List<int> _stageTotals = [
    500,
    2500,
    12500,
    50000,
    100000,
    500000,
    2000000,
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

  static const int pathSwitchCost = 500000;

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

  /// Stages 0–5 only: knock out PNG white via multiply over painted sky.
  static bool usesMultiplyBlend(int stageIndex, int growthStepsInStage) =>
      stageIndex >= 0 && stageIndex <= 5;

  static bool usesFullBleedImage(int stageIndex) => stageIndex >= 6;

  /// Stages 6–7: image covers the viewport when fully grown in that stage.
  static bool fillsViewport(int stageIndex, int growthStepsInStage) {
    if (stageIndex == finaleStage) return true;
    if (stageIndex == maxPlayableStage) {
      return growthStepsInStage >= levelsPerStage - 1;
    }
    return false;
  }

  static BoxFit imageFitFor({
    required int stageIndex,
    required bool fullBleed,
  }) {
    if (stageIndex >= 6) return BoxFit.cover;
    return BoxFit.fitHeight;
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

  static const double groundInsetFraction = 0.14;

  /// Bonsai slot: tree fill height as fraction of cell (stages 0–5).
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
        3 => const Color(0xFF87CEEB),
        4 => const Color(0xFF1A1A2E),
        5 => const Color(0xFF0D0D1F),
        _ => const Color(0xFFC8D8E0),
      };
    }
    return const Color(0xFF050510);
  }

  /// HUD level denominator (25 for stages 0–6, 1 for finale).
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
      for (final total in _stageTotals) _distributeIncreasing(total, levelsPerStage),
    ];
  }

  /// Strictly increasing costs within a stage; sums exactly to [total].
  static List<int> _distributeIncreasing(int total, int steps) {
    if (steps <= 0) return const [];
    if (steps == 1) return [total];
    final costs = List.generate(steps, (i) => i + 1);
    var remaining = total - costs.fold<int>(0, (a, b) => a + b);
    var idx = steps - 1;
    while (remaining > 0) {
      costs[idx]++;
      remaining--;
      idx = idx <= 0 ? steps - 1 : idx - 1;
    }
    assert(costs.fold<int>(0, (a, b) => a + b) == total);
    for (var i = 1; i < costs.length; i++) {
      assert(costs[i] > costs[i - 1], 'costs must increase within stage');
    }
    return costs;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
