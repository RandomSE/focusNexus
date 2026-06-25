import 'package:freezed_annotation/freezed_annotation.dart';

import 'garden_item.dart';
import 'json/garden_json_converters.dart';
import 'mutation_kind.dart';
import 'visual_theme_id.dart';

part 'decor_item.freezed.dart';
part 'decor_item.g.dart';

/// Sandbox object with the same growth stages as plants (shared rules per screen).
@freezed
class DecorItem with _$DecorItem {
  const DecorItem._();

  const factory DecorItem({
    required String id,
    @VisualThemeIdJsonConverter() required VisualThemeId themeId,
    required String kind,
    @Default(0.5) double positionX,
    @Default(0.5) double positionY,
    @Default(0) int stageIndex,
    DateTime? nextAdvanceAllowedAt,
    int? pendingSkipWaitCost,
    @MutationKindJsonConverter() MutationKind? mutation,
    @Default(false) bool awaitingRegrowthForRemutation,
    @Default(false) bool mutationRolledThisCycle,
    @Default(0) int rebirthCount,
  }) = _DecorItem;

  factory DecorItem.fromJson(Map<String, dynamic> json) =>
      _$DecorItemFromJson(json);

  static const int maxStageIndex = GardenItem.maxStageIndex;

  bool get isFullyGrown => stageIndex >= maxStageIndex;

  void validate() {
    assert(id.isNotEmpty, 'id must not be empty');
    assert(kind.isNotEmpty, 'kind must not be empty');
    assert(
      stageIndex >= 0 && stageIndex <= maxStageIndex,
      'stageIndex out of range',
    );
  }

  DecorItem clearedAdvanceLock() => copyWith(
        nextAdvanceAllowedAt: null,
        pendingSkipWaitCost: null,
      );
}
