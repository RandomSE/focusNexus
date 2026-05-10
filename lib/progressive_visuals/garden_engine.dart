import 'dart:math';

import 'decor_catalog.dart';
import 'decor_item.dart';
import 'garden_item.dart';
import 'garden_state.dart';
import 'mutation_kind.dart';
import 'stage_transition_rule.dart';
import 'visual_theme_id.dart';

class GardenOpResult {
  const GardenOpResult._(this.state, this.error);

  final GardenState? state;
  final String? error;

  bool get isSuccess => error == null && state != null;

  static GardenOpResult success(GardenState state) => GardenOpResult._(state, null);

  static GardenOpResult failure(String message) => GardenOpResult._(null, message);
}

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

  GardenOpResult removeItem(GardenState state, String id) {
    final nextItems = state.items.where((e) => e.id != id).toList();
    if (nextItems.length == state.items.length) {
      return GardenOpResult.failure('Item not found');
    }
    var next = state.copyWith(items: nextItems);
    if (state.freeFirstGrowthEligibleItemId == id) {
      next = next.copyWith(clearFreeFirstEligible: true);
    }
    return GardenOpResult.success(next);
  }

  GardenOpResult removeItemsBulk(GardenState state, Set<String> ids) {
    if (ids.isEmpty) {
      return GardenOpResult.failure('Nothing selected');
    }
    var next = state;
    var removed = 0;
    for (final id in ids) {
      final r = removeItem(next, id);
      if (r.isSuccess) {
        next = r.state!;
        removed++;
      }
    }
    if (removed == 0) {
      return GardenOpResult.failure('No matching plants to remove');
    }
    return GardenOpResult.success(next);
  }

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
    final stash = Map<String, int>.from(state.decorStash);
    stash[kind] = (stash[kind] ?? 0) + quantity;
    return GardenOpResult.success(
      state.copyWith(
        pointsBalance: state.pointsBalance - total,
        decorStash: stash,
      ),
    );
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
    final count = state.decorStash[kind] ?? 0;
    if (count <= 0) {
      return GardenOpResult.failure('Buy this decoration first, or none left in inventory');
    }
    if (state.decor.any((d) => d.id == id)) {
      return GardenOpResult.failure('Decoration id already exists');
    }
    final stash = Map<String, int>.from(state.decorStash);
    if (count <= 1) {
      stash.remove(kind);
    } else {
      stash[kind] = count - 1;
    }
    final decor = DecorItem(
      id: id,
      themeId: themeId,
      kind: kind,
      positionX: x,
      positionY: y,
      stageIndex: 0,
    );
    return GardenOpResult.success(
      state.copyWith(
        decor: [...state.decor, decor],
        decorStash: stash,
      ),
    );
  }

  GardenOpResult removeDecor(GardenState state, String id) {
    final nextDecor = state.decor.where((e) => e.id != id).toList();
    if (nextDecor.length == state.decor.length) {
      return GardenOpResult.failure('Decoration not found');
    }
    return GardenOpResult.success(state.copyWith(decor: nextDecor));
  }

  GardenOpResult removeDecorsBulk(GardenState state, Set<String> ids) {
    if (ids.isEmpty) {
      return GardenOpResult.failure('Nothing selected');
    }
    final nextDecor = state.decor.where((e) => !ids.contains(e.id)).toList();
    if (nextDecor.length == state.decor.length) {
      return GardenOpResult.failure('No matching decorations to remove');
    }
    return GardenOpResult.success(state.copyWith(decor: nextDecor));
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
    final cleared = item.copyWith(
      clearNextAdvanceAllowedAt: true,
      clearPendingSkipWaitCost: true,
    );
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
    final cleared = d.copyWith(
      clearNextAdvanceAllowedAt: true,
      clearPendingSkipWaitCost: true,
    );
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
    var nextItem = item.copyWith(
      stageIndex: newStage,
      clearNextAdvanceAllowedAt: true,
      clearPendingSkipWaitCost: true,
    );

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
        clearFreeFirstEligible: everConsumed,
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
    var nextDecor = d.copyWith(
      stageIndex: newStage,
      clearNextAdvanceAllowedAt: true,
      clearPendingSkipWaitCost: true,
    );

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
      clearMutation: true,
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
      clearMutation: true,
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
    final item = state.items[idx].copyWith(
      stageIndex: 0,
      clearMutation: true,
      clearNextAdvanceAllowedAt: true,
      clearPendingSkipWaitCost: true,
      awaitingRegrowthForRemutation: false,
      mutationRolledThisCycle: false,
      regrowthDiscountActive: true,
    );
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
    final d = state.decor[idx].copyWith(
      stageIndex: 0,
      clearMutation: true,
      clearNextAdvanceAllowedAt: true,
      clearPendingSkipWaitCost: true,
      awaitingRegrowthForRemutation: false,
      mutationRolledThisCycle: false,
    );
    final next = [...state.decor]..[idx] = d;
    return GardenOpResult.success(
      state.copyWith(
        decor: next,
        pointsBalance: state.pointsBalance - pointCost,
      ),
    );
  }
}
