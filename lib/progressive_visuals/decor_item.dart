import 'garden_item.dart';
import 'mutation_kind.dart';
import 'visual_theme_id.dart';

/// Sandbox object with the same growth stages as plants (shared rules per screen).
class DecorItem {
  const DecorItem({
    required this.id,
    required this.themeId,
    required this.kind,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.stageIndex = 0,
    this.nextAdvanceAllowedAt,
    this.pendingSkipWaitCost,
    this.mutation,
    this.awaitingRegrowthForRemutation = false,
    this.mutationRolledThisCycle = false,
  });

  final String id;
  final VisualThemeId themeId;
  final String kind;
  final double positionX;
  final double positionY;
  final int stageIndex;
  final DateTime? nextAdvanceAllowedAt;
  final int? pendingSkipWaitCost;
  final MutationKind? mutation;
  final bool awaitingRegrowthForRemutation;
  final bool mutationRolledThisCycle;

  static const int maxStageIndex = GardenItem.maxStageIndex;

  bool get isFullyGrown => stageIndex >= maxStageIndex;

  DecorItem copyWith({
    double? positionX,
    double? positionY,
    int? stageIndex,
    DateTime? nextAdvanceAllowedAt,
    bool clearNextAdvanceAllowedAt = false,
    int? pendingSkipWaitCost,
    bool clearPendingSkipWaitCost = false,
    MutationKind? mutation,
    bool clearMutation = false,
    bool? awaitingRegrowthForRemutation,
    bool? mutationRolledThisCycle,
  }) {
    return DecorItem(
      id: id,
      themeId: themeId,
      kind: kind,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      stageIndex: stageIndex ?? this.stageIndex,
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
    );
  }
}
