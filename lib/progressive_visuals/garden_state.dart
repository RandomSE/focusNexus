import 'decor_item.dart';
import 'garden_item.dart';

/// Points balance + sandbox contents for progressive visuals.
class GardenState {
  const GardenState({
    required this.pointsBalance,
    required this.items,
    this.decor = const [],
    this.decorStash = const {},
    this.freeFirstGrowthEverConsumed = false,
    this.freeFirstGrowthEligibleItemId,
  });

  final int pointsBalance;
  final List<GardenItem> items;

  /// Placed decorations (paths, ponds, …).
  final List<DecorItem> decor;

  /// Purchased but not yet placed (`kind` -> count).
  final Map<String, int> decorStash;

  /// After the first eligible plant uses free 0→1 growth, always true.
  final bool freeFirstGrowthEverConsumed;

  /// The first plant placed while [freeFirstGrowthEverConsumed] is false;
  /// only this id may use the free first growth. Cleared when consumed or plant removed.
  final String? freeFirstGrowthEligibleItemId;

  GardenState copyWith({
    int? pointsBalance,
    List<GardenItem>? items,
    List<DecorItem>? decor,
    Map<String, int>? decorStash,
    bool? freeFirstGrowthEverConsumed,
    String? freeFirstGrowthEligibleItemId,
    bool clearFreeFirstEligible = false,
  }) {
    return GardenState(
      pointsBalance: pointsBalance ?? this.pointsBalance,
      items: items ?? this.items,
      decor: decor ?? this.decor,
      decorStash: decorStash ?? this.decorStash,
      freeFirstGrowthEverConsumed:
          freeFirstGrowthEverConsumed ?? this.freeFirstGrowthEverConsumed,
      freeFirstGrowthEligibleItemId: clearFreeFirstEligible
          ? null
          : (freeFirstGrowthEligibleItemId ?? this.freeFirstGrowthEligibleItemId),
    );
  }
}
