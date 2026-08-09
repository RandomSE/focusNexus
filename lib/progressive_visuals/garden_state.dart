import 'package:freezed_annotation/freezed_annotation.dart';

import 'cherry_blossom_tree_state.dart';
import 'decor_item.dart';
import 'garden_item.dart';

part 'garden_state.freezed.dart';

/// Points balance + sandbox contents for progressive visuals.
@freezed
class GardenState with _$GardenState {
  const GardenState._();

  const factory GardenState({
    required int pointsBalance,
    /// Progressive-visuals points; spent before [pointsBalance] on PV purchases.
    @Default(0) int progressiveVisualsPointsBalance,
    @Default(<GardenItem>[]) List<GardenItem> items,
    @Default(<DecorItem>[]) List<DecorItem> decor,
    @Default(<String, int>{}) Map<String, int> decorStash,
    @Default(<DecorItem>[]) List<DecorItem> decorInventory,
    @Default(<GardenItem>[]) List<GardenItem> plantInventory,
    @Default(false) bool freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
    @Default(0) int lifetimeZenPointsSpent,
    @Default(false) bool cherryBlossomTreeUnlocked,
    @Default(false) bool suppressRestartGrowthPrompt,
    @Default(false) bool cherryBlossomUnlockToastShown,
    @Default(CherryBlossomTreeState()) CherryBlossomTreeState cherryBlossomTree,
  }) = _GardenState;

  void validate() {
    assert(pointsBalance >= 0, 'pointsBalance must be non-negative');
    assert(
      progressiveVisualsPointsBalance >= 0,
      'progressiveVisualsPointsBalance must be non-negative',
    );
    for (final item in items) {
      item.validate();
    }
    for (final d in decor) {
      d.validate();
    }
  }

  /// Clears the free-first-growth eligible plant id.
  GardenState withoutFreeFirstEligible() =>
      copyWith(freeFirstGrowthEligibleItemId: null);
}
