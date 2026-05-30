import 'package:freezed_annotation/freezed_annotation.dart';

import 'decor_item.dart';
import 'garden_item.dart';

part 'garden_state.freezed.dart';

/// Points balance + sandbox contents for progressive visuals.
@freezed
class GardenState with _$GardenState {
  const GardenState._();

  const factory GardenState({
    required int pointsBalance,
    @Default(<GardenItem>[]) List<GardenItem> items,
    @Default(<DecorItem>[]) List<DecorItem> decor,
    @Default(<String, int>{}) Map<String, int> decorStash,
    @Default(<DecorItem>[]) List<DecorItem> decorInventory,
    @Default(<GardenItem>[]) List<GardenItem> plantInventory,
    @Default(false) bool freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
  }) = _GardenState;

  void validate() {
    assert(pointsBalance >= 0, 'pointsBalance must be non-negative');
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
