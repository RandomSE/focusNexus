import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';

/// One grouped row in the decor inventory UI.
class ZenDecorInventoryStack {
  const ZenDecorInventoryStack({
    required this.representative,
    required this.itemIds,
  });

  final DecorItem representative;
  final List<String> itemIds;

  String get kind => representative.kind;
  int get stageIndex => representative.stageIndex;
  MutationKind? get mutation => representative.mutation;
  int get count => itemIds.length;
  String get sellItemId => itemIds.first;
}

/// One grouped row in the plant inventory UI.
class ZenPlantInventoryStack {
  const ZenPlantInventoryStack({
    required this.representative,
    required this.itemIds,
  });

  final GardenItem representative;
  final List<String> itemIds;

  int get stageIndex => representative.stageIndex;
  MutationKind? get mutation => representative.mutation;
  int get count => itemIds.length;
  String get placeOrSellItemId => itemIds.first;
}

String decorInventoryStackKey(DecorItem d) =>
    '${d.kind}|${d.stageIndex}|${d.mutation?.name ?? ''}';

String plantInventoryStackKey(GardenItem p) =>
    '${p.themeId.name}|${p.stageIndex}|${p.mutation?.name ?? ''}';

String? nextDecorInventoryIdInStack(List<DecorItem> inventory, String stackKey) {
  for (final d in inventory) {
    if (decorInventoryStackKey(d) == stackKey) return d.id;
  }
  return null;
}

String? nextPlantInventoryIdInStack(List<GardenItem> inventory, String stackKey) {
  for (final p in inventory) {
    if (plantInventoryStackKey(p) == stackKey) return p.id;
  }
  return null;
}

bool decorInventoryStackContains(List<DecorItem> inventory, String stackKey) =>
    inventory.any((d) => decorInventoryStackKey(d) == stackKey);

bool plantInventoryStackContains(List<GardenItem> inventory, String stackKey) =>
    inventory.any((p) => plantInventoryStackKey(p) == stackKey);

List<ZenDecorInventoryStack> groupDecorInventory(List<DecorItem> items) {
  final buckets = <String, List<DecorItem>>{};
  for (final d in items) {
    buckets.putIfAbsent(decorInventoryStackKey(d), () => []).add(d);
  }
  final stacks = buckets.values
      .map(
        (list) => ZenDecorInventoryStack(
          representative: list.first,
          itemIds: list.map((e) => e.id).toList(),
        ),
      )
      .toList();
  stacks.sort((a, b) {
    final k = a.kind.compareTo(b.kind);
    if (k != 0) return k;
    return a.stageIndex.compareTo(b.stageIndex);
  });
  return stacks;
}

List<ZenPlantInventoryStack> groupPlantInventory(List<GardenItem> items) {
  final buckets = <String, List<GardenItem>>{};
  for (final p in items) {
    buckets.putIfAbsent(plantInventoryStackKey(p), () => []).add(p);
  }
  final stacks = buckets.values
      .map(
        (list) => ZenPlantInventoryStack(
          representative: list.first,
          itemIds: list.map((e) => e.id).toList(),
        ),
      )
      .toList();
  stacks.sort((a, b) => a.stageIndex.compareTo(b.stageIndex));
  return stacks;
}
