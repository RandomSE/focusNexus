import 'package:freezed_annotation/freezed_annotation.dart';

import 'json/garden_json_converters.dart';
import 'mutation_kind.dart';
import 'visual_theme_id.dart';

part 'garden_item.freezed.dart';
part 'garden_item.g.dart';

/// One placeable progressive entity in the sandbox (plant, coral polyp, star, …).
@freezed
class GardenItem with _$GardenItem {
  const GardenItem._();

  const factory GardenItem({
    required String id,
    @VisualThemeIdJsonConverter() required VisualThemeId themeId,
    @Default(0) int stageIndex,
    @Default(0.5) double positionX,
    @Default(0.5) double positionY,
    DateTime? nextAdvanceAllowedAt,
    int? pendingSkipWaitCost,
    @MutationKindJsonConverter() MutationKind? mutation,
    @Default(false) bool awaitingRegrowthForRemutation,
    @Default(false) bool mutationRolledThisCycle,
    @Default(false) bool regrowthDiscountActive,
  }) = _GardenItem;

  factory GardenItem.fromJson(Map<String, dynamic> json) =>
      _$GardenItemFromJson(json);

  static const int maxStageIndex = 4;

  bool get isFullyGrown => stageIndex >= maxStageIndex;

  void validate() {
    assert(id.isNotEmpty, 'id must not be empty');
    assert(
      stageIndex >= 0 && stageIndex <= maxStageIndex,
      'stageIndex out of range',
    );
    assert(
      positionX >= 0 && positionX <= 1 && positionY >= 0 && positionY <= 1,
      'position must be normalized 0–1',
    );
  }

  /// Clears growth timer fields after an advance.
  GardenItem clearedAdvanceLock() => copyWith(
        nextAdvanceAllowedAt: null,
        pendingSkipWaitCost: null,
      );
}
