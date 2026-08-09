import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_bonsai_tile.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_peace_petals.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_decor_visual.dart';

void main() {
  test('path claim bonsai kinds exist in catalog and not in shop', () {
    expect(decorEntryByKind(zenPeaceBonsaiKind)?.themeId, VisualThemeId.zenGarden);
    expect(decorEntryByKind(zenPowerBonsaiKind)?.themeId, VisualThemeId.zenGarden);
    expect(decorPrice(zenPeaceBonsaiKind), 0);
    expect(decorPrice(zenPowerBonsaiKind), 0);
    expect(
      zenDecorShopCatalog().any((e) => isZenPathClaimBonsaiKind(e.id)),
      isFalse,
    );
    expect(
      decorCatalogFor(VisualThemeId.zenGarden)
          .any((e) => e.id == zenPeaceBonsaiKind),
      isTrue,
    );
  });

  test('path claim kinds map to finale bonsai garden keys', () {
    expect(zenPathClaimBonsaiGardenKey(zenPeaceBonsaiKind), 'stage_7_peace');
    expect(zenPathClaimBonsaiGardenKey(zenPowerBonsaiKind), 'stage_7_power');
    expect(zenPathClaimBonsaiGardenKey('zen.moss_rock'), isNull);
  });

  test('purchaseDecor rejects path claim bonsai kinds', () {
    final engine = ProgressiveGardenEngine();
    const garden = GardenState(pointsBalance: 10_000);
    final peace = engine.purchaseDecor(garden, zenPeaceBonsaiKind);
    final power = engine.purchaseDecor(garden, zenPowerBonsaiKind);
    expect(peace.isSuccess, isFalse);
    expect(power.isSuccess, isFalse);
    expect(peace.error, contains('Achievement'));
  });

  test('sellDecorInventoryItem rejects path claim bonsai', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_peace_1',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
    );
    const garden = GardenState(
      pointsBalance: 100,
      decorInventory: [item],
    );
    final sold = engine.sellDecorInventoryItem(garden, item.id);
    expect(sold.isSuccess, isFalse);
    expect(sold.error, contains('cannot be sold'));
    expect(garden.decorInventory.length, 1);
  });

  test('stashDecorToInventory allows path claim bonsai', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_peace_placed',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
      positionX: 0.4,
      positionY: 0.5,
    );
    const garden = GardenState(pointsBalance: 100, decor: [item]);
    final stashed = engine.stashDecorToInventory(garden, item.id);
    expect(stashed.isSuccess, isTrue);
    expect(stashed.state!.decor, isEmpty);
    expect(stashed.state!.decorInventory.single.id, item.id);
  });

  test('bulk stash moves path claim bonsai with other decor', () {
    final engine = ProgressiveGardenEngine();
    const path = DecorItem(
      id: 'path_power_placed',
      themeId: VisualThemeId.zenGarden,
      kind: zenPowerBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
    );
    const rock = DecorItem(
      id: 'rock_1',
      themeId: VisualThemeId.zenGarden,
      kind: 'zen.moss_rock',
    );
    const garden = GardenState(pointsBalance: 100, decor: [path, rock]);
    final bulk = engine.stashDecorsToInventoryBulk(garden, {path.id, rock.id});
    expect(bulk.isSuccess, isTrue);
    expect(bulk.state!.decor, isEmpty);
    expect(bulk.state!.decorInventory.map((d) => d.id).toSet(), {path.id, rock.id});
  });

  test('advance and restart growth reject path claim bonsai', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_peace_grown',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
    );
    const garden = GardenState(pointsBalance: 10_000, decor: [item]);
    final grow = engine.advanceDecorGrowth(
      state: garden,
      decorId: item.id,
      now: DateTime(2026, 8, 9),
    );
    expect(grow.isSuccess, isFalse);
    expect(grow.error, contains('cannot grow'));

    final restart = engine.restartDecorGrowthCycle(
      state: garden,
      decorId: item.id,
    );
    expect(restart.isSuccess, isFalse);
    expect(restart.error, contains('cannot restart'));
  });

  test('purchasePathBonsaiMutation spends PV first then points', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_peace_mut',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
    );
    const garden = GardenState(
      pointsBalance: 40_000,
      progressiveVisualsPointsBalance: 70_000,
      decor: [item],
    );
    final bought = engine.purchasePathBonsaiMutation(garden, item.id);
    expect(bought.isSuccess, isTrue);
    expect(bought.state!.decor.single.mutation, MutationKind.invertedColors);
    expect(bought.state!.decor.single.mutationUnlocked, isTrue);
    expect(bought.state!.progressiveVisualsPointsBalance, 0);
    expect(bought.state!.pointsBalance, 10_000);
    expect(
      bought.state!.lifetimeZenPointsSpent,
      zenPathBonsaiMutationPointCost,
    );
  });

  test('purchasePathBonsaiMutation allows combined wallets at exact cost', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_power_mut',
      themeId: VisualThemeId.zenGarden,
      kind: zenPowerBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
    );
    const garden = GardenState(
      pointsBalance: 30_000,
      progressiveVisualsPointsBalance: 70_000,
      decorInventory: [item],
    );
    final bought = engine.purchasePathBonsaiMutation(garden, item.id);
    expect(bought.isSuccess, isTrue);
    expect(bought.state!.decorInventory.single.mutation, MutationKind.invertedColors);
    expect(bought.state!.decorInventory.single.mutationUnlocked, isTrue);
    expect(bought.state!.progressiveVisualsPointsBalance, 0);
    expect(bought.state!.pointsBalance, 0);
  });

  test('purchasePathBonsaiMutation rejects when combined wallets short', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_peace_broke',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
    );
    const garden = GardenState(
      pointsBalance: 20_000,
      progressiveVisualsPointsBalance: 30_000,
      decor: [item],
    );
    final bought = engine.purchasePathBonsaiMutation(garden, item.id);
    expect(bought.isSuccess, isFalse);
    expect(bought.error, contains('Not enough points'));
  });

  test('path bonsai inverted variant toggles free after unlock', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_peace_toggle',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
    );
    const garden = GardenState(
      pointsBalance: zenPathBonsaiMutationPointCost,
      decor: [item],
    );
    final bought = engine.purchasePathBonsaiMutation(garden, item.id);
    expect(bought.isSuccess, isTrue);
    final unlocked = bought.state!;
    expect(unlocked.pointsBalance, 0);

    final off = engine.setPathBonsaiMutationEnabled(
      unlocked,
      item.id,
      enabled: false,
    );
    expect(off.isSuccess, isTrue);
    expect(off.state!.decor.single.mutation, isNull);
    expect(off.state!.decor.single.mutationUnlocked, isTrue);
    expect(off.state!.pointsBalance, 0);
    expect(off.state!.decor.single.awaitingRegrowthForRemutation, isFalse);

    final on = engine.setPathBonsaiMutationEnabled(
      off.state!,
      item.id,
      enabled: true,
    );
    expect(on.isSuccess, isTrue);
    expect(on.state!.decor.single.mutation, MutationKind.invertedColors);
    expect(on.state!.pointsBalance, 0);
  });

  test('setPathBonsaiMutationEnabled rejects without unlock purchase', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_power_locked_mut',
      themeId: VisualThemeId.zenGarden,
      kind: zenPowerBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
    );
    const garden = GardenState(pointsBalance: 100, decor: [item]);
    final r = engine.setPathBonsaiMutationEnabled(
      garden,
      item.id,
      enabled: true,
    );
    expect(r.isSuccess, isFalse);
    expect(r.error, contains('Unlock'));
  });

  test('purchasePathBonsaiMutation rejects when already unlocked', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'path_peace_owned',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
      mutationUnlocked: true,
    );
    const garden = GardenState(
      pointsBalance: zenPathBonsaiMutationPointCost,
      decor: [item],
    );
    final r = engine.purchasePathBonsaiMutation(garden, item.id);
    expect(r.isSuccess, isFalse);
    expect(r.error, contains('already'));
  });

  test('path claim petal mul scales with zen tile vs bonsai reference', () {
    final zenMul = CherryBlossomBonsaiTile.scaledBonsaiPetalMul(
      cellWidth: ZenDecorVisual.pathBonsaiWidth,
      bonsaiSizeMul: CherryBlossomPeacePetals.bonsaiSizeMul,
    );
    final refMul = CherryBlossomBonsaiTile.scaledBonsaiPetalMul(
      cellWidth: CherryBlossomBonsaiTile.petalScaleReferenceWidth,
      bonsaiSizeMul: CherryBlossomPeacePetals.bonsaiSizeMul,
    );
    expect(refMul, closeTo(CherryBlossomPeacePetals.bonsaiSizeMul, 0.0001));
    expect(
      zenMul / refMul,
      closeTo(
        ZenDecorVisual.pathBonsaiWidth /
            CherryBlossomBonsaiTile.petalScaleReferenceWidth,
        0.0001,
      ),
    );
  });
}
