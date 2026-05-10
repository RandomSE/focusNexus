import 'mutation_kind.dart';
import 'visual_theme_id.dart';

/// One placeable progressive entity in the sandbox (plant, coral polyp, star, …).
class GardenItem {
  const GardenItem({
    required this.id,
    required this.themeId,
    required this.stageIndex,
    this.positionX = 0,
    this.positionY = 0,
    this.nextAdvanceAllowedAt,
    this.pendingSkipWaitCost,
    this.mutation,
    this.awaitingRegrowthForRemutation = false,
    this.mutationRolledThisCycle = false,
    this.regrowthDiscountActive = false,
  });

  final String id;
  final VisualThemeId themeId;

  /// Index into [GrowthStage] (0 = seed).
  final int stageIndex;

  /// Normalized sandbox coordinates (0–1) for free placement.
  final double positionX;
  final double positionY;

  /// When non-null, advancing again is blocked until [DateTime.now] passes this
  /// (or the user skips with points).
  final DateTime? nextAdvanceAllowedAt;

  /// Cost to clear [nextAdvanceAllowedAt] when set.
  final int? pendingSkipWaitCost;

  final MutationKind? mutation;

  /// After the user removes a mutation, new rolls require a full regrowth cycle.
  final bool awaitingRegrowthForRemutation;

  /// Prevents duplicate rolls while staying at the final stage.
  final bool mutationRolledThisCycle;

  /// After [restartGrowthCycle], grow and skip-wait costs use 1/5 of the rule
  /// table (does not stack with free-first growth; free-first wins when applicable).
  final bool regrowthDiscountActive;

  static const int maxStageIndex = 4; // GrowthStage.mature

  bool get isFullyGrown => stageIndex >= maxStageIndex;

  GardenItem copyWith({
    VisualThemeId? themeId,
    int? stageIndex,
    double? positionX,
    double? positionY,
    DateTime? nextAdvanceAllowedAt,
    bool clearNextAdvanceAllowedAt = false,
    int? pendingSkipWaitCost,
    bool clearPendingSkipWaitCost = false,
    MutationKind? mutation,
    bool clearMutation = false,
    bool? awaitingRegrowthForRemutation,
    bool? mutationRolledThisCycle,
    bool? regrowthDiscountActive,
  }) {
    return GardenItem(
      id: id,
      themeId: themeId ?? this.themeId,
      stageIndex: stageIndex ?? this.stageIndex,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      nextAdvanceAllowedAt: clearNextAdvanceAllowedAt
          ? null
          : (nextAdvanceAllowedAt ?? this.nextAdvanceAllowedAt),
      pendingSkipWaitCost: clearPendingSkipWaitCost
          ? null
          : (pendingSkipWaitCost ?? this.pendingSkipWaitCost),
      mutation: clearMutation ? null : (mutation ?? this.mutation),
      awaitingRegrowthForRemutation:
          awaitingRegrowthForRemutation ?? this.awaitingRegrowthForRemutation,
      mutationRolledThisCycle: mutationRolledThisCycle ?? this.mutationRolledThisCycle,
      regrowthDiscountActive: regrowthDiscountActive ?? this.regrowthDiscountActive,
    );
  }
}
