import 'dart:math';

import 'decor_catalog.dart';
import 'decor_item.dart';
import 'garden_item.dart';
import 'garden_op_result.dart';
import 'garden_state.dart';
import 'garden_valuation.dart';
import 'mutation_kind.dart';
import 'stage_transition_rule.dart';
import 'visual_theme_id.dart';

/// Default progression (5× costs vs original); tests use these or custom lists.
List<StageTransitionRule> defaultTransitionRules() {
  return const [
    StageTransitionRule(
      fromStageIndex: 0,
      pointCost: 50,
      waitBeforeNextAdvance: Duration(hours: 2),
      skipWaitPointCost: 75,
    ),
    StageTransitionRule(
      fromStageIndex: 1,
      pointCost: 0,
      waitBeforeNextAdvance: Duration(hours: 1),
      skipWaitPointCost: 75,
    ),
    StageTransitionRule(
      fromStageIndex: 2,
      pointCost: 40,
      waitBeforeNextAdvance: Duration(hours: 1),
      skipWaitPointCost: 75,
    ),
    StageTransitionRule(
      fromStageIndex: 3,
      pointCost: 60,
      waitBeforeNextAdvance: Duration(hours: 2),
      skipWaitPointCost: 75,
    ),
  ];
}

class ProgressiveGardenEngine {
  ProgressiveGardenEngine({
    List<StageTransitionRule>? transitionRules,
    this.mutationProbability = 0.05, 
  }) : transitionRules = transitionRules ?? defaultTransitionRules();

  final List<StageTransitionRule> transitionRules;
  final double mutationProbability;

  StageTransitionRule _ruleFor(int fromStageIndex) {
    return transitionRules.firstWhere(
      (r) => r.fromStageIndex == fromStageIndex,
      orElse: () => throw StateError('No rule for stage $fromStageIndex'),
    );
  }

  GardenOpResult addPoints(GardenState state, int delta) {
    if (delta < 0) {
      return GardenOpResult.failure('Cannot add negative points');
    }
    return GardenOpResult.success(state.copyWith(pointsBalance: state.pointsBalance + delta));
  }

  GardenOpResult placeItem({
    required GardenState state,
    required String id,
    required VisualThemeId themeId,
    double x = 0.5,
    double y = 0.5,
  }) {
    if (state.items.any((e) => e.id == id)) {
      return GardenOpResult.failure('Item id already exists');
    }
    final placed = GardenItem(
      id: id,
      themeId: themeId,
      stageIndex: 0,
      positionX: x,
      positionY: y,
    );
    var next = state.copyWith(items: [...state.items, placed]);
    if (!next.freeFirstGrowthEverConsumed && next.freeFirstGrowthEligibleItemId == null) {
      next = next.copyWith(freeFirstGrowthEligibleItemId: id);
    }
    return GardenOpResult.success(next);
  }

  GardenOpResult removeItem(GardenState state, String id) =>
      stashPlantToInventory(state, id);

  GardenOpResult removeItemsBulk(GardenState state, Set<String> ids) =>
      stashPlantsToInventoryBulk(state, ids);

  GardenOpResult moveItem(
    GardenState state,
    String id, {
    required double x,
    required double y,
  }) {
    final idx = state.items.indexWhere((e) => e.id == id);
    if (idx < 0) {
      return GardenOpResult.failure('Item not found');
    }
    final updated = state.items[idx].copyWith(positionX: x, positionY: y);
    final next = [...state.items]..[idx] = updated;
    return GardenOpResult.success(state.copyWith(items: next));
  }

  GardenOpResult purchaseDecor(GardenState state, String kind, {int quantity = 1}) {
    if (quantity < 1) {
      return GardenOpResult.failure('Invalid quantity');
    }
    final price = decorPrice(kind);
    if (price == null) {
      return GardenOpResult.failure('Unknown decoration');
    }
    final total = price * quantity;
    if (state.pointsBalance < total) {
      return GardenOpResult.failure('Not enough points');
    }
    final baseMs = DateTime.now().microsecondsSinceEpoch;
    final added = List<DecorItem>.generate(quantity, (i) {
      return DecorItem(
        id: 'inv_${baseMs}_$i',
        themeId: VisualThemeId.zenGarden,
        kind: kind,
      );
    });
    return GardenOpResult.success(
      state.copyWith(
        pointsBalance: state.pointsBalance - total,
        decorInventory: [...state.decorInventory, ...added],
      ),
    );
  }

  int _inventoryCount(GardenState state, String kind) {
    return state.decorInventory.where((d) => d.kind == kind).length;
  }

  GardenOpResult placeDecorFromStash({
    required GardenState state,
    required String kind,
    required String id,
    required double x,
    required double y,
    required VisualThemeId themeId,
  }) {
    if (decorEntryByKind(kind) == null) {
      return GardenOpResult.failure('Unknown decoration');
    }
    if (_inventoryCount(state, kind) <= 0) {
      return GardenOpResult.failure('Buy this decoration first, or none left in inventory');
    }
    if (state.decor.any((d) => d.id == id)) {
      return GardenOpResult.failure('Decoration id already exists');
    }
    final invIdx = state.decorInventory.indexWhere((d) => d.kind == kind);
    final inv = state.decorInventory[invIdx];
    final decor = inv.copyWith(
      id: id,
      themeId: themeId,
      positionX: x,
      positionY: y,
    );
    final nextInv = [...state.decorInventory]..removeAt(invIdx);
    return GardenOpResult.success(
      state.copyWith(
        decor: [...state.decor, decor],
        decorInventory: nextInv,
      ),
    );
  }

  GardenOpResult placeDecorFromInventory({
    required GardenState state,
    required String inventoryItemId,
    required double x,
    required double y,
  }) {
    final invIdx = state.decorInventory.indexWhere((d) => d.id == inventoryItemId);
    if (invIdx < 0) {
      return GardenOpResult.failure('Item not in inventory');
    }
    final inv = state.decorInventory[invIdx];
    if (state.decor.any((d) => d.id == inventoryItemId)) {
      return GardenOpResult.failure('Decoration already placed');
    }
    final decor = inv.copyWith(positionX: x, positionY: y);
    final nextInv = [...state.decorInventory]..removeAt(invIdx);
    return GardenOpResult.success(
      state.copyWith(
        decor: [...state.decor, decor],
        decorInventory: nextInv,
      ),
    );
  }

  GardenOpResult stashDecorToInventory(GardenState state, String id) {
    final idx = state.decor.indexWhere((e) => e.id == id);
    if (idx < 0) {
      return GardenOpResult.failure('Decoration not found');
    }
    final item = state.decor[idx];
    final nextDecor = [...state.decor]..removeAt(idx);
    return GardenOpResult.success(
      state.copyWith(
        decor: nextDecor,
        decorInventory: [...state.decorInventory, item],
      ),
    );
  }

  GardenOpResult stashDecorsToInventoryBulk(GardenState state, Set<String> ids) {
    if (ids.isEmpty) {
      return GardenOpResult.failure('Nothing selected');
    }
    var next = state;
    var moved = 0;
    for (final id in ids) {
      final r = stashDecorToInventory(next, id);
      if (r.isSuccess) {
        next = r.state!;
        moved++;
      }
    }
    if (moved == 0) {
      return GardenOpResult.failure('No matching decorations to remove');
    }
    return GardenOpResult.success(next);
  }

  GardenOpResult sellDecorInventoryItem(GardenState state, String inventoryItemId) {
    final idx = state.decorInventory.indexWhere((d) => d.id == inventoryItemId);
    if (idx < 0) {
      return GardenOpResult.failure('Item not in inventory');
    }
    final item = state.decorInventory[idx];
    final value = decorSellValue(item);
    final nextInv = [...state.decorInventory]..removeAt(idx);
    return GardenOpResult.success(
      state.copyWith(
        decorInventory: nextInv,
        pointsBalance: state.pointsBalance + value,
      ),
    );
  }

  GardenOpResult stashPlantToInventory(GardenState state, String id) {
    final idx = state.items.indexWhere((e) => e.id == id);
    if (idx < 0) {
      return GardenOpResult.failure('Item not found');
    }
    final item = state.items[idx];
    final nextItems = [...state.items]..removeAt(idx);
    var next = state.copyWith(
      items: nextItems,
      plantInventory: [...state.plantInventory, item],
    );
    if (state.freeFirstGrowthEligibleItemId == id) {
      next = next.withoutFreeFirstEligible();
    }
    return GardenOpResult.success(next);
  }

  GardenOpResult stashPlantsToInventoryBulk(GardenState state, Set<String> ids) {
    if (ids.isEmpty) {
      return GardenOpResult.failure('Nothing selected');
    }
    var next = state;
    var moved = 0;
    for (final id in ids) {
      final r = stashPlantToInventory(next, id);
      if (r.isSuccess) {
        next = r.state!;
        moved++;
      }
    }
    if (moved == 0) {
      return GardenOpResult.failure('No matching plants to remove');
    }
    return GardenOpResult.success(next);
  }

  GardenOpResult sellPlantInventoryItem(GardenState state, String inventoryItemId) {
    final idx = state.plantInventory.indexWhere((p) => p.id == inventoryItemId);
    if (idx < 0) {
      return GardenOpResult.failure('Item not in inventory');
    }
    final item = state.plantInventory[idx];
    final value = plantSellValue(item);
    final nextInv = [...state.plantInventory]..removeAt(idx);
    return GardenOpResult.success(
      state.copyWith(
        plantInventory: nextInv,
        pointsBalance: state.pointsBalance + value,
      ),
    );
  }

  GardenOpResult removeDecor(GardenState state, String id) =>
      stashDecorToInventory(state, id);

  GardenOpResult removeDecorsBulk(GardenState state, Set<String> ids) =>
      stashDecorsToInventoryBulk(state, ids);

  GardenOpResult placePlantFromInventory({
    required GardenState state,
    required String inventoryItemId,
    required double x,
    required double y,
  }) {
    final idx = state.plantInventory.indexWhere((p) => p.id == inventoryItemId);
    if (idx < 0) {
      return GardenOpResult.failure('Item not in inventory');
    }
    if (state.items.any((p) => p.id == inventoryItemId)) {
      return GardenOpResult.failure('Plant already placed');
    }
    final inv = state.plantInventory[idx];
    final placed = inv.copyWith(positionX: x, positionY: y);
    final nextInv = [...state.plantInventory]..removeAt(idx);
    return GardenOpResult.success(
      state.copyWith(
        items: [...state.items, placed],
        plantInventory: nextInv,
      ),
    );
  }

  GardenOpResult moveDecor(
    GardenState state,
    String id, {
    required double x,
    required double y,
  }) {
    final idx = state.decor.indexWhere((e) => e.id == id);
    if (idx < 0) {
      return GardenOpResult.failure('Decoration not found');
    }
    final updated = state.decor[idx].copyWith(positionX: x, positionY: y);
    final next = [...state.decor]..[idx] = updated;
    return GardenOpResult.success(state.copyWith(decor: next));
  }

  GardenOpResult moveItemsBulk(
    GardenState state,
    Map<String, ({double x, double y})> plantPositions,
  ) {
    if (plantPositions.isEmpty) {
      return GardenOpResult.failure('Nothing to move');
    }
    var next = state;
    for (final entry in plantPositions.entries) {
      final r = moveItem(next, entry.key, x: entry.value.x, y: entry.value.y);
      if (r.isSuccess) next = r.state!;
    }
    return GardenOpResult.success(next);
  }

  GardenOpResult moveDecorsBulk(
    GardenState state,
    Map<String, ({double x, double y})> decorPositions,
  ) {
    if (decorPositions.isEmpty) {
      return GardenOpResult.failure('Nothing to move');
    }
    var next = state;
    for (final entry in decorPositions.entries) {
      final r = moveDecor(next, entry.key, x: entry.value.x, y: entry.value.y);
      if (r.isSuccess) next = r.state!;
    }
    return GardenOpResult.success(next);
  }

  GardenOpResult skipGrowthWait(
    GardenState state,
    String itemId,
    DateTime now,
  ) {
    final idx = state.items.indexWhere((e) => e.id == itemId);
    if (idx < 0) {
      return GardenOpResult.failure('Item not found');
    }
    final item = state.items[idx];
    if (item.nextAdvanceAllowedAt == null) {
      return GardenOpResult.failure('No active growth wait');
    }
    if (!now.isBefore(item.nextAdvanceAllowedAt!)) {
      return GardenOpResult.failure('Wait already finished');
    }
    final cost = item.pendingSkipWaitCost ?? 0;
    if (state.pointsBalance < cost) {
      return GardenOpResult.failure('Not enough points to skip wait');
    }
    final cleared = item.clearedAdvanceLock();
    final nextItems = [...state.items]..[idx] = cleared;
    return GardenOpResult.success(
      state.copyWith(
        items: nextItems,
        pointsBalance: state.pointsBalance - cost,
      ),
    );
  }

  GardenOpResult skipDecorGrowthWait(
    GardenState state,
    String decorId,
    DateTime now,
  ) {
    final idx = state.decor.indexWhere((e) => e.id == decorId);
    if (idx < 0) {
      return GardenOpResult.failure('Decoration not found');
    }
    final d = state.decor[idx];
    if (d.nextAdvanceAllowedAt == null) {
      return GardenOpResult.failure('No active growth wait');
    }
    if (!now.isBefore(d.nextAdvanceAllowedAt!)) {
      return GardenOpResult.failure('Wait already finished');
    }
    final cost = d.pendingSkipWaitCost ?? 0;
    if (state.pointsBalance < cost) {
      return GardenOpResult.failure('Not enough points to skip wait');
    }
    final cleared = d.clearedAdvanceLock();
    final nextDecor = [...state.decor]..[idx] = cleared;
    return GardenOpResult.success(
      state.copyWith(
        decor: nextDecor,
        pointsBalance: state.pointsBalance - cost,
      ),
    );
  }

  GardenOpResult advanceGrowth({
    required GardenState state,
    required String itemId,
    required DateTime now,
    Random? random,
  }) {
    final idx = state.items.indexWhere((e) => e.id == itemId);
    if (idx < 0) {
      return GardenOpResult.failure('Item not found');
    }
    var item = state.items[idx];
    if (item.stageIndex >= GardenItem.maxStageIndex) {
      return GardenOpResult.failure('Already fully grown');
    }
    if (item.nextAdvanceAllowedAt != null && now.isBefore(item.nextAdvanceAllowedAt!)) {
      return GardenOpResult.failure('Growth wait in progress');
    }

    final fromStage = item.stageIndex;
    final rule = _ruleFor(fromStage);
    var cost = rule.pointCost;
    var everConsumed = state.freeFirstGrowthEverConsumed;
    final eligible = state.freeFirstGrowthEligibleItemId;
    if (fromStage == 0 &&
        !everConsumed &&
        eligible != null &&
        itemId == eligible) {
      cost = 0;
      everConsumed = true;
    } else if (item.regrowthDiscountActive) {
      cost = (cost + 4) ~/ 5;
    }
    if (state.pointsBalance < cost) {
      return GardenOpResult.failure('Not enough points to grow');
    }

    final newStage = item.stageIndex + 1;
    var balance = state.pointsBalance - cost;
    var nextItem = item.copyWith(stageIndex: newStage).clearedAdvanceLock();

    final skipOverride = (item.regrowthDiscountActive && rule.skipWaitPointCost != null)
        ? (rule.skipWaitPointCost! + 4) ~/ 5
        : null;
    _applyPostAdvanceWait(
      rule,
      newStage,
      now,
      (at, skip) {
        nextItem = nextItem.copyWith(
          nextAdvanceAllowedAt: at,
          pendingSkipWaitCost: skip,
        );
      },
      skipCostOverride: skipOverride,
    );

    nextItem = _maybeApplyMutation(
      item: nextItem,
      random: random ?? Random(),
    );

    final nextItems = [...state.items]..[idx] = nextItem;
    return GardenOpResult.success(
      state.copyWith(
        pointsBalance: balance,
        items: nextItems,
        freeFirstGrowthEverConsumed: everConsumed,
        freeFirstGrowthEligibleItemId:
            everConsumed ? null : state.freeFirstGrowthEligibleItemId,
      ),
    );
  }

  void _applyPostAdvanceWait(
    StageTransitionRule rule,
    int newStage,
    DateTime now,
    void Function(DateTime at, int skip) apply, {
    int? skipCostOverride,
  }) {
    if (rule.waitBeforeNextAdvance == null || rule.skipWaitPointCost == null) {
      return;
    }
    if (newStage >= GardenItem.maxStageIndex) {
      return;
    }
    final skip = skipCostOverride ?? rule.skipWaitPointCost!;
    apply(
      now.add(rule.waitBeforeNextAdvance!),
      skip,
    );
  }

  GardenOpResult advanceDecorGrowth({
    required GardenState state,
    required String decorId,
    required DateTime now,
    Random? random,
  }) {
    final idx = state.decor.indexWhere((e) => e.id == decorId);
    if (idx < 0) {
      return GardenOpResult.failure('Decoration not found');
    }
    var d = state.decor[idx];
    if (d.stageIndex >= DecorItem.maxStageIndex) {
      return GardenOpResult.failure('Already fully grown');
    }
    if (d.nextAdvanceAllowedAt != null && now.isBefore(d.nextAdvanceAllowedAt!)) {
      return GardenOpResult.failure('Growth wait in progress');
    }

    final rule = _ruleFor(d.stageIndex);
    final cost = rule.pointCost;
    if (state.pointsBalance < cost) {
      return GardenOpResult.failure('Not enough points to grow');
    }

    final newStage = d.stageIndex + 1;
    var balance = state.pointsBalance - cost;
    var nextDecor = d.copyWith(stageIndex: newStage).clearedAdvanceLock();

    _applyPostAdvanceWait(rule, newStage, now, (at, skip) {
      nextDecor = nextDecor.copyWith(
        nextAdvanceAllowedAt: at,
        pendingSkipWaitCost: skip,
      );
    });

    nextDecor = _maybeApplyDecorMutation(nextDecor, random ?? Random());

    final list = [...state.decor]..[idx] = nextDecor;
    return GardenOpResult.success(
      state.copyWith(
        pointsBalance: balance,
        decor: list,
      ),
    );
  }

  GardenItem _maybeApplyMutation({
    required GardenItem item,
    required Random random,
  }) {
    if (item.stageIndex != GardenItem.maxStageIndex) {
      return item;
    }
    if (item.awaitingRegrowthForRemutation) {
      return item;
    }
    if (item.mutation != null || item.mutationRolledThisCycle) {
      return item;
    }
    final roll = random.nextDouble();
    if (roll > mutationProbability) {
      return item.copyWith(mutationRolledThisCycle: true);
    }
    return item.copyWith(
      mutation: MutationKind.invertedColors,
      mutationRolledThisCycle: true,
    );
  }

  DecorItem _maybeApplyDecorMutation(DecorItem d, Random random) {
    if (d.stageIndex != DecorItem.maxStageIndex) {
      return d;
    }
    if (d.awaitingRegrowthForRemutation) {
      return d;
    }
    if (d.mutation != null || d.mutationRolledThisCycle) {
      return d;
    }
    final roll = random.nextDouble();
    if (roll > mutationProbability) {
      return d.copyWith(mutationRolledThisCycle: true);
    }
    return d.copyWith(
      mutation: MutationKind.invertedColors,
      mutationRolledThisCycle: true,
    );
  }

  GardenOpResult removeMutation(GardenState state, String itemId) {
    final idx = state.items.indexWhere((e) => e.id == itemId);
    if (idx < 0) {
      return GardenOpResult.failure('Item not found');
    }
    final item = state.items[idx];
    if (item.mutation == null) {
      return GardenOpResult.failure('No active mutation');
    }
    final updated = item.copyWith(
      mutation: null,
      awaitingRegrowthForRemutation: true,
      mutationRolledThisCycle: false,
    );
    final nextItems = [...state.items]..[idx] = updated;
    return GardenOpResult.success(state.copyWith(items: nextItems));
  }

  GardenOpResult removeDecorMutation(GardenState state, String decorId) {
    final idx = state.decor.indexWhere((e) => e.id == decorId);
    if (idx < 0) {
      return GardenOpResult.failure('Decoration not found');
    }
    final d = state.decor[idx];
    if (d.mutation == null) {
      return GardenOpResult.failure('No active mutation');
    }
    final updated = d.copyWith(
      mutation: null,
      awaitingRegrowthForRemutation: true,
      mutationRolledThisCycle: false,
    );
    final next = [...state.decor]..[idx] = updated;
    return GardenOpResult.success(state.copyWith(decor: next));
  }

  GardenOpResult restartGrowthCycle({
    required GardenState state,
    required String itemId,
    int pointCost = 0,
  }) {
    final idx = state.items.indexWhere((e) => e.id == itemId);
    if (idx < 0) {
      return GardenOpResult.failure('Item not found');
    }
    if (state.pointsBalance < pointCost) {
      return GardenOpResult.failure('Not enough points to restart growth');
    }
    final item = state.items[idx]
        .copyWith(
          stageIndex: 0,
          mutation: null,
          awaitingRegrowthForRemutation: false,
          mutationRolledThisCycle: false,
          regrowthDiscountActive: true,
        )
        .clearedAdvanceLock();
    final nextItems = [...state.items]..[idx] = item;
    return GardenOpResult.success(
      state.copyWith(
        items: nextItems,
        pointsBalance: state.pointsBalance - pointCost,
      ),
    );
  }

  GardenOpResult restartDecorGrowthCycle({
    required GardenState state,
    required String decorId,
    int pointCost = 0,
  }) {
    final idx = state.decor.indexWhere((e) => e.id == decorId);
    if (idx < 0) {
      return GardenOpResult.failure('Decoration not found');
    }
    if (state.pointsBalance < pointCost) {
      return GardenOpResult.failure('Not enough points to restart growth');
    }
    final d = state.decor[idx]
        .copyWith(
          stageIndex: 0,
          mutation: null,
          awaitingRegrowthForRemutation: false,
          mutationRolledThisCycle: false,
        )
        .clearedAdvanceLock();
    final next = [...state.decor]..[idx] = d;
    return GardenOpResult.success(
      state.copyWith(
        decor: next,
        pointsBalance: state.pointsBalance - pointCost,
      ),
    );
  }
}
