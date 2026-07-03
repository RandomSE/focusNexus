import 'package:freezed_annotation/freezed_annotation.dart';

import 'cherry_blossom_tree_state.dart';
import 'decor_item.dart';
import 'garden_item.dart';
import 'json/garden_json_converters.dart';

part 'garden_persisted_payload.freezed.dart';
part 'garden_persisted_payload.g.dart';

/// JSON blob stored for zen garden layout (wallet points are separate).
@freezed
class GardenPersistedPayload with _$GardenPersistedPayload {
  const factory GardenPersistedPayload({
    @Default(<GardenItem>[]) List<GardenItem> items,
    @Default(<DecorItem>[]) List<DecorItem> decor,
    @DecorStashJsonConverter()
    @Default(<String, int>{}) Map<String, int> decorStash,
    @Default(<DecorItem>[]) List<DecorItem> decorInventory,
    @Default(<GardenItem>[]) List<GardenItem> plantInventory,
    @Default(false) bool freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
    bool? legacyFreeFirst,
    @Default(0) int lifetimeZenPointsSpent,
    @Default(false) bool cherryBlossomTreeUnlocked,
    @Default(false) bool suppressRestartGrowthPrompt,
    @Default(false) bool cherryBlossomUnlockToastShown,
    @Default(CherryBlossomTreeState()) CherryBlossomTreeState cherryBlossomTree,
  }) = _GardenPersistedPayload;

  factory GardenPersistedPayload.fromJson(Map<String, dynamic> json) =>
      _$GardenPersistedPayloadFromJson(json);
}
