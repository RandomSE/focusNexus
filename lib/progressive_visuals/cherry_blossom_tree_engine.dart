import 'cherry_blossom_bonsai_ref.dart';
import 'cherry_blossom_prestige_path.dart';
import 'cherry_blossom_stage_catalog.dart';
import 'cherry_blossom_tree_state.dart';
import 'garden_state.dart';
import 'garden_zen_spend.dart';

/// Result of a cherry blossom tree operation.
class CherryBlossomOpResult {
  const CherryBlossomOpResult._({
    this.state,
    this.error,
    this.message,
    this.prestiged = false,
    this.fromStageIndex,
    this.toStageIndex,
  });

  final GardenState? state;
  final String? error;
  final String? message;
  final bool prestiged;
  final int? fromStageIndex;
  final int? toStageIndex;

  bool get isSuccess => error == null && state != null;

  factory CherryBlossomOpResult.success(
    GardenState state, {
    String? message,
    bool prestiged = false,
    int? fromStageIndex,
    int? toStageIndex,
  }) =>
      CherryBlossomOpResult._(
        state: state,
        message: message,
        prestiged: prestiged,
        fromStageIndex: fromStageIndex,
        toStageIndex: toStageIndex,
      );

  factory CherryBlossomOpResult.failure(String message) =>
      CherryBlossomOpResult._(error: message);
}

class CherryBlossomTreeEngine {
  CherryBlossomTreeState get tree => _tree;
  final CherryBlossomTreeState _tree;

  CherryBlossomTreeEngine([CherryBlossomTreeState? tree])
      : _tree = (tree ?? CherryBlossomTreeState.initial()).normalized();

  int? nextGrowCost() => CherryBlossomStageCatalog.costForGrow(
        stageIndex: _tree.stageIndex,
        growthStepsInStage: _tree.growthStepsInStage,
      );

  int? prestigeCost() => CherryBlossomStageCatalog.costForPrestige(
        stageIndex: _tree.stageIndex,
        growthStepsInStage: _tree.growthStepsInStage,
      );

  int pathSwitchCost(CherryBlossomPrestigePath path) =>
      _tree.isFinalePathUnlocked(path)
          ? 0
          : CherryBlossomStageCatalog.pathSwitchCost;

  bool canGrow() => _tree.canGrowMore;
  bool canPrestige() => _tree.canPrestige;

  bool canAffordGrow(int walletBalance) {
    final cost = nextGrowCost();
    return cost != null && walletBalance >= cost;
  }

  bool canAffordPrestige(int walletBalance) {
    final cost = prestigeCost();
    return cost != null && walletBalance >= cost;
  }

  bool canAffordPathSwitch(int walletBalance, CherryBlossomPrestigePath path) {
    final cost = pathSwitchCost(path);
    return cost == 0 || walletBalance >= cost;
  }

  int maxGrowCost(int walletBalance) {
    if (!canGrow()) return 0;
    var balance = walletBalance;
    var total = 0;
    var steps = _tree.growthStepsInStage;
    while (steps < CherryBlossomStageCatalog.levelsPerStage - 1) {
      final cost = CherryBlossomStageCatalog.costForGrow(
        stageIndex: _tree.stageIndex,
        growthStepsInStage: steps,
      );
      if (cost == null || balance < cost) break;
      total += cost;
      balance -= cost;
      steps++;
    }
    return total;
  }

  int maxGrowSteps(int walletBalance) {
    if (!canGrow()) return 0;
    var balance = walletBalance;
    var steps = 0;
    var cursor = _tree.growthStepsInStage;
    while (cursor < CherryBlossomStageCatalog.levelsPerStage - 1) {
      final cost = CherryBlossomStageCatalog.costForGrow(
        stageIndex: _tree.stageIndex,
        growthStepsInStage: cursor,
      );
      if (cost == null || balance < cost) break;
      balance -= cost;
      cursor++;
      steps++;
    }
    return steps;
  }

  CherryBlossomOpResult growOne(GardenState garden) {
    if (!canGrow()) {
      return CherryBlossomOpResult.failure(
        'Stage is complete - prestige to continue',
      );
    }
    final cost = nextGrowCost()!;
    if (garden.pointsBalance < cost) {
      return CherryBlossomOpResult.failure('Not enough points');
    }
    final nextTree = _afterGrow(_tree, steps: 1);
    final spent = applyZenSpend(garden, cost);
    return CherryBlossomOpResult.success(
      spent.copyWith(cherryBlossomTree: nextTree),
    );
  }

  CherryBlossomOpResult growToAffordableMax(GardenState garden) {
    final steps = maxGrowSteps(garden.pointsBalance);
    if (steps <= 0) {
      return CherryBlossomOpResult.failure('Not enough points for any growth');
    }
    var tree = _tree;
    var spentTotal = 0;
    for (var i = 0; i < steps; i++) {
      final cost = CherryBlossomStageCatalog.costForGrow(
        stageIndex: tree.stageIndex,
        growthStepsInStage: tree.growthStepsInStage,
      )!;
      spentTotal += cost;
      tree = _afterGrow(tree, steps: 1);
    }
    final spent = applyZenSpend(garden, spentTotal);
    return CherryBlossomOpResult.success(
      spent.copyWith(cherryBlossomTree: tree),
    );
  }

  CherryBlossomOpResult prestige(
    GardenState garden, {
    CherryBlossomPrestigePath? path,
  }) {
    if (!canPrestige()) {
      return CherryBlossomOpResult.failure('Complete this stage before prestiging');
    }
    if (_tree.stageIndex == CherryBlossomStageCatalog.maxPlayableStage &&
        path == null) {
      return CherryBlossomOpResult.failure('Choose Power or Peace to continue');
    }

    final cost = prestigeCost()!;
    if (garden.pointsBalance < cost) {
      return CherryBlossomOpResult.failure('Not enough points');
    }

    final fromStage = _tree.stageIndex;
    final nextStage = fromStage + 1;
    final bonsai = Map<int, int>.from(_tree.bonsaiFilledSlots);
    bonsai[fromStage] = CherryBlossomStageCatalog.levelsPerStage;

    var peaceCount = _tree.peaceBonsaiCount;
    var powerCount = _tree.powerBonsaiCount;
    final unlocked = List<CherryBlossomPrestigePath>.from(_tree.unlockedFinalePaths);
    if (nextStage == CherryBlossomStageCatalog.finaleStage && path != null) {
      unlocked.add(path);
      if (path == CherryBlossomPrestigePath.peace) {
        peaceCount = CherryBlossomStageCatalog.levelsPerStage;
      } else {
        powerCount = CherryBlossomStageCatalog.levelsPerStage;
      }
    }

    final nextTree = _tree.copyWith(
      stageIndex: nextStage,
      growthStepsInStage: nextStage == CherryBlossomStageCatalog.finaleStage ? 1 : 0,
      prestigePath: nextStage == CherryBlossomStageCatalog.finaleStage ? path : null,
      bonsaiFilledSlots: bonsai,
      peaceBonsaiCount: peaceCount,
      powerBonsaiCount: powerCount,
      unlockedFinalePaths: unlocked,
      highestStageUnlocked: nextStage > _tree.highestStageUnlocked
          ? nextStage
          : _tree.highestStageUnlocked,
    ).normalized();

    final spent = applyZenSpend(garden, cost);
    return CherryBlossomOpResult.success(
      spent.copyWith(cherryBlossomTree: nextTree),
      message: 'Prestiged to ${nextTree.stageLabel}',
      prestiged: true,
      fromStageIndex: fromStage,
      toStageIndex: nextStage,
    );
  }

  CherryBlossomOpResult switchFinalePath(
    GardenState garden,
    CherryBlossomPrestigePath path,
  ) {
    if (!_tree.isFinale) {
      return CherryBlossomOpResult.failure('Only available on the finale tree');
    }
    if (_tree.prestigePath == path) {
      return CherryBlossomOpResult.failure('Already on this path');
    }

    final alreadyUnlocked = _tree.isFinalePathUnlocked(path);
    final cost = pathSwitchCost(path);
    if (!alreadyUnlocked && garden.pointsBalance < cost) {
      return CherryBlossomOpResult.failure('Not enough points');
    }

    var peaceCount = _tree.peaceBonsaiCount;
    var powerCount = _tree.powerBonsaiCount;
    final unlocked = List<CherryBlossomPrestigePath>.from(_tree.unlockedFinalePaths);
    if (!alreadyUnlocked) {
      unlocked.add(path);
      if (path == CherryBlossomPrestigePath.peace) {
        peaceCount = CherryBlossomStageCatalog.levelsPerStage;
      } else {
        powerCount = CherryBlossomStageCatalog.levelsPerStage;
      }
    }

    final nextTree = _tree.copyWith(
      prestigePath: path,
      peaceBonsaiCount: peaceCount,
      powerBonsaiCount: powerCount,
      unlockedFinalePaths: unlocked,
    ).normalized();

    final spent = cost == 0 ? garden : applyZenSpend(garden, cost);
    return CherryBlossomOpResult.success(
      spent.copyWith(cherryBlossomTree: nextTree),
      message: alreadyUnlocked
          ? 'Switched to ${nextTree.stageLabel}'
          : 'Unlocked ${nextTree.stageLabel}',
    );
  }

  CherryBlossomOpResult setGardenSlot({
    required GardenState garden,
    required int slotIndex,
    required String? bonsaiKey,
  }) {
    if (slotIndex < 0 || slotIndex >= CherryBlossomBonsaiRef.gardenSlotCount) {
      return CherryBlossomOpResult.failure('Invalid garden slot');
    }
    if (bonsaiKey != null && !_tree.unlockedBonsaiKeys.contains(bonsaiKey)) {
      return CherryBlossomOpResult.failure('Bonsai not unlocked');
    }
    final slots = List<String?>.from(_tree.gardenSlots);
    slots[slotIndex] = bonsaiKey;
    final nextTree =
        _tree.copyWith(customBonsaiGardenSlots: slots).normalized();
    return CherryBlossomOpResult.success(
      garden.copyWith(cherryBlossomTree: nextTree),
    );
  }

  static CherryBlossomTreeState _afterGrow(
    CherryBlossomTreeState tree, {
    required int steps,
  }) {
    final stage = tree.stageIndex;
    final nextSteps = tree.growthStepsInStage + steps;
    final bonsai = Map<int, int>.from(tree.bonsaiFilledSlots);
    bonsai[stage] = (bonsai[stage] ?? 0) + steps;
    return tree
        .copyWith(
          growthStepsInStage: nextSteps,
          bonsaiFilledSlots: bonsai,
          highestStageUnlocked: stage > tree.highestStageUnlocked
              ? stage
              : tree.highestStageUnlocked,
        )
        .normalized();
  }

  static CherryBlossomTreeState maxedStageSix() {
    var tree = CherryBlossomTreeState.initial();
    for (var stage = 0;
        stage <= CherryBlossomStageCatalog.maxPlayableStage;
        stage++) {
      tree = tree.copyWith(
        stageIndex: stage,
        growthStepsInStage: CherryBlossomStageCatalog.levelsPerStage - 1,
        highestStageUnlocked: stage,
        bonsaiFilledSlots: {
          ...tree.bonsaiFilledSlots,
          stage: CherryBlossomStageCatalog.levelsPerStage - 1,
        },
      ).normalized();
    }
    return tree;
  }

  static CherryBlossomTreeState maxedFinale({
    CherryBlossomPrestigePath path = CherryBlossomPrestigePath.peace,
  }) {
    return CherryBlossomTreeState(
      stageIndex: CherryBlossomStageCatalog.finaleStage,
      growthStepsInStage: 1,
      prestigePath: path,
      highestStageUnlocked: CherryBlossomStageCatalog.finaleStage,
      bonsaiFilledSlots: {
        for (var i = 0; i <= CherryBlossomStageCatalog.maxPlayableStage; i++)
          i: CherryBlossomStageCatalog.levelsPerStage,
      },
      peaceBonsaiCount: CherryBlossomStageCatalog.levelsPerStage,
      powerBonsaiCount: 0,
      unlockedFinalePaths: const [CherryBlossomPrestigePath.peace],
    ).normalized();
  }
}
