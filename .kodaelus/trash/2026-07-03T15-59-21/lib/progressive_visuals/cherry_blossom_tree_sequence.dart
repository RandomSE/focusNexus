import 'dart:math' as math;

import 'cherry_blossom_growth.dart';
import 'cherry_blossom_tree_state.dart';

/// Fixed growth sequence: total spend is exactly 1,000,000 across all steps.
/// Milestone totals are exactly 1k / 10k / 100k / 1M at band boundaries.
abstract final class CherryBlossomTreeSequence {
  CherryBlossomTreeSequence._();

  static const int milestone1k = 1000;
  static const int milestone10k = 10000;
  static const int milestone100k = 100000;
  static const int milestone1m = 1000000;

  static const List<int> _bandStepCounts = [20, 18, 27, 45];

  /// Trunk / base growth steps per band (must sum to [totalTrunkGrowthSteps]).
  static const List<int> bandTrunkStepCounts = [12, 4, 5, 5];
  static const int totalTrunkGrowthSteps = 26;

  static final List<int> stepCosts = _buildStepCosts();
  static final List<CherryBlossomGrowthFocus> stepFocuses = _buildStepFocuses();
  static final List<int> _cumulativeCosts = _buildCumulative();

  static int get totalSteps => stepCosts.length;

  static int get stepsAt1k => _bandStepCounts[0];
  static int get stepsAt10k => _bandStepCounts[0] + _bandStepCounts[1];
  static int get stepsAt100k =>
      _bandStepCounts[0] + _bandStepCounts[1] + _bandStepCounts[2];
  static int get stepsAt1m => totalSteps;

  /// Strictly increasing costs within a band; sums exactly to [total].
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
      assert(costs[i] > costs[i - 1], 'costs must increase within band');
    }
    return costs;
  }

  static List<int> _buildStepCosts() {
    final costs = <int>[
      ..._distributeIncreasing(1000, _bandStepCounts[0]),
      ..._distributeIncreasing(9000, _bandStepCounts[1]),
      ..._distributeIncreasing(90000, _bandStepCounts[2]),
      ..._distributeIncreasing(900000, _bandStepCounts[3]),
    ];
    final totalBandSteps =
        _bandStepCounts.fold<int>(0, (sum, count) => sum + count);
    assert(costs.length == totalBandSteps);
    assert(costs.fold<int>(0, (a, b) => a + b) == milestone1m);
    assert(_cumulativeAt(_bandStepCounts[0], costs) == milestone1k);
    assert(
      _cumulativeAt(_bandStepCounts[0] + _bandStepCounts[1], costs) ==
          milestone10k,
    );
    assert(
      _cumulativeAt(
        _bandStepCounts[0] + _bandStepCounts[1] + _bandStepCounts[2],
        costs,
      ) ==
          milestone100k,
    );
    assert(_cumulativeAt(totalBandSteps, costs) == milestone1m);
    return costs;
  }

  static int _cumulativeAt(int stepIndex, List<int> costs) {
    var sum = 0;
    for (var i = 0; i < stepIndex && i < costs.length; i++) {
      sum += costs[i];
    }
    return sum;
  }

  static List<int> _buildCumulative() {
    var running = 0;
    return stepCosts.map((c) {
      running += c;
      return running;
    }).toList();
  }

  static List<CherryBlossomGrowthFocus> _buildStepFocuses() {
    final focuses = <CherryBlossomGrowthFocus>[];

    void band0() {
      // Steps 1–6: trunk emerges; 7–12: trunk character; 13–16: four main branches.
      for (var i = 0; i < 6; i++) {
        focuses.add(const CherryBlossomGrowthFocus(kind: CherryBlossomGrowthKind.base));
      }
      for (var i = 0; i < 6; i++) {
        focuses.add(const CherryBlossomGrowthFocus(kind: CherryBlossomGrowthKind.base));
      }
      for (var slot = 0; slot < 4; slot++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.branch,
          slotIndex: slot,
        ));
      }
      // Steps 17–20: tip blossom clusters (one per main branch).
      for (var slot = 0; slot < 4; slot++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.leaf,
          slotIndex: slot,
        ));
      }
    }

    void band1() {
      // Trunk matures; extend main branches; mid-canopy blossom density.
      for (var i = 0; i < 4; i++) {
        focuses.add(const CherryBlossomGrowthFocus(kind: CherryBlossomGrowthKind.base));
      }
      for (var slot = 0; slot < 4; slot++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.branch,
          slotIndex: slot,
        ));
      }
      for (var i = 0; i < 10; i++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.leaf,
          slotIndex: i % 12,
        ));
      }
    }

    void band2() {
      // Wider canopy skirt (L3/R3), deeper layers, dome fill.
      for (var i = 0; i < 5; i++) {
        focuses.add(const CherryBlossomGrowthFocus(kind: CherryBlossomGrowthKind.base));
      }
      for (var slot = 0; slot < 6; slot++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.branch,
          slotIndex: slot,
        ));
      }
      for (var i = 0; i < 16; i++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.leaf,
          slotIndex: i % 18,
        ));
      }
    }

    void band3() {
      for (var i = 0; i < 5; i++) {
        focuses.add(const CherryBlossomGrowthFocus(kind: CherryBlossomGrowthKind.base));
      }
      for (var slot = 0; slot < 8; slot++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.branch,
          slotIndex: slot,
        ));
      }
      for (var i = 0; i < 32; i++) {
        focuses.add(CherryBlossomGrowthFocus(
          kind: CherryBlossomGrowthKind.leaf,
          slotIndex: i % 24,
        ));
      }
    }

    band0();
    band1();
    band2();
    band3();
    final expectedSteps =
        _bandStepCounts.fold<int>(0, (sum, count) => sum + count);
    assert(focuses.length == expectedSteps);
    assert(
      bandTrunkStepCounts.fold<int>(0, (a, b) => a + b) == totalTrunkGrowthSteps,
    );
    return focuses;
  }

  /// Max branch slot that has received at least one growth focus by [completedSteps].
  static int maxBranchSlotUnlocked(int completedSteps) {
    var maxSlot = -1;
    final limit = completedSteps.clamp(0, totalSteps);
    for (var i = 0; i < limit; i++) {
      final f = stepFocuses[i];
      if (f.kind == CherryBlossomGrowthKind.branch) {
        maxSlot = math.max(maxSlot, f.slotIndex);
      }
    }
    return maxSlot;
  }

  static int cumulativeInvestment(int completedSteps) {
    if (completedSteps <= 0) return 0;
    if (completedSteps >= totalSteps) return milestone1m;
    return _cumulativeCosts[completedSteps - 1];
  }

  static int stepIndexForInvestment(int invested) {
    if (invested <= 0) return 0;
    if (invested >= milestone1m) return totalSteps;
    for (var i = 0; i < _cumulativeCosts.length; i++) {
      if (_cumulativeCosts[i] > invested) return i;
    }
    return totalSteps;
  }

  static CherryBlossomVisualBand bandForStep(int completedSteps) {
    if (completedSteps >= stepsAt1m) return CherryBlossomVisualBand.perfect;
    if (completedSteps >= stepsAt100k) return CherryBlossomVisualBand.great;
    if (completedSteps >= stepsAt10k) return CherryBlossomVisualBand.good;
    if (completedSteps >= stepsAt1k) return CherryBlossomVisualBand.basic;
    return CherryBlossomVisualBand.seedling;
  }

  static CherryBlossomVisualBand bandForInvestment(int invested) {
    if (invested >= milestone1m) return CherryBlossomVisualBand.perfect;
    if (invested >= milestone100k) return CherryBlossomVisualBand.great;
    if (invested >= milestone10k) return CherryBlossomVisualBand.good;
    if (invested >= milestone1k) return CherryBlossomVisualBand.basic;
    return CherryBlossomVisualBand.seedling;
  }

  static String stageLabel(CherryBlossomVisualBand band) => switch (band) {
        CherryBlossomVisualBand.seedling => 'Bare Beginning',
        CherryBlossomVisualBand.basic => 'Early Spring Morning',
        CherryBlossomVisualBand.good => 'Midday Spring',
        CherryBlossomVisualBand.great => 'Golden Afternoon',
        CherryBlossomVisualBand.perfect => 'Transcendent Twilight',
      };

  static String? nextStageLabel(int invested) {
    final next = _nextMilestone(invested);
    if (next == null) return null;
    return stageLabel(bandForInvestment(next));
  }

  static int? _nextMilestone(int invested) {
    if (invested < milestone1k) return milestone1k;
    if (invested < milestone10k) return milestone10k;
    if (invested < milestone100k) return milestone100k;
    if (invested < milestone1m) return milestone1m;
    return null;
  }

  /// Derives substage levels for painting from completed steps.
  static ({
    int trunkSegments,
    List<int> branchLevels,
    List<int> leafLevels,
  }) deriveLevels(int completedSteps) {
    final branches = List<int>.filled(8, 0);
    final leaves = List<int>.filled(24, 0);
    var trunk = 0;
    final limit = completedSteps.clamp(0, totalSteps);
    for (var i = 0; i < limit; i++) {
      final f = stepFocuses[i];
      switch (f.kind) {
        case CherryBlossomGrowthKind.base:
          trunk++;
        case CherryBlossomGrowthKind.branch:
          branches[f.slotIndex]++;
        case CherryBlossomGrowthKind.leaf:
          leaves[f.slotIndex]++;
      }
    }
    return (trunkSegments: trunk, branchLevels: branches, leafLevels: leaves);
  }
}
