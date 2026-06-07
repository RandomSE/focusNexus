import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';

part 'zen_garden_shop_provider.g.dart';

/// In-sheet cart garden for the zen decoration shop bottom sheet.
@riverpod
class ZenGardenShopCart extends _$ZenGardenShopCart {
  @override
  GardenState build(GardenState initial) => initial;

  void setGarden(GardenState garden) => state = garden;
}
