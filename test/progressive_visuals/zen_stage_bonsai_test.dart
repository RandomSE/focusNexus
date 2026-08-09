import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_decor_visual.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stage bonsai kinds map to garden keys and are shop-excluded', () {
    for (var i = 0; i < zenCherryStageBonsaiNames.length; i++) {
      final kind = zenStageBonsaiKind(i);
      expect(isZenLockedBonsaiKind(kind), isTrue);
      expect(isZenStageBonsaiKind(kind), isTrue);
      expect(isZenPathClaimBonsaiKind(kind), isFalse);
      expect(zenAchievementBonsaiGardenKey(kind), 'stage_$i');
      expect(decorEntryByKind(kind)?.label, contains(zenCherryStageBonsaiNames[i]));
      expect(decorPrice(kind), 0);
    }
    expect(
      zenDecorShopCatalog().any((e) => isZenLockedBonsaiKind(e.id)),
      isFalse,
    );
  });

  test('stage bonsai sell locked, stash allowed, no invert purchase', () {
    final engine = ProgressiveGardenEngine();
    const item = DecorItem(
      id: 'stage3',
      themeId: VisualThemeId.zenGarden,
      kind: 'zen.stage_3_bonsai',
      stageIndex: DecorItem.maxStageIndex,
      positionX: 0.4,
      positionY: 0.5,
    );
    const garden = GardenState(
      pointsBalance: 200000,
      decor: [item],
      decorInventory: [
        DecorItem(
          id: 'stage3_inv',
          themeId: VisualThemeId.zenGarden,
          kind: 'zen.stage_3_bonsai',
          stageIndex: DecorItem.maxStageIndex,
        ),
      ],
    );

    final sold = engine.sellDecorInventoryItem(garden, 'stage3_inv');
    expect(sold.isSuccess, isFalse);
    expect(sold.error, contains('cannot be sold'));

    final stashed = engine.stashDecorToInventory(garden, item.id);
    expect(stashed.isSuccess, isTrue);

    final mut = engine.purchasePathBonsaiMutation(garden, item.id);
    expect(mut.isSuccess, isFalse);
  });

  test('claiming cherry stage achievement grants matching zen bonsai', () async {
    final storage = InMemoryKeyValueStorage(initial: {StorageKeys.points: '500'});
    final points = PointsRepository(storage);
    final garden = GardenRepository(storage, points: points);
    final service = AchievementService(
      storage: storage,
      pointsRepository: points,
      gardenRepository: garden,
      soundService: SoundService(storage),
    );
    SoundService.suppressNativePlaybackForTesting = true;
    addTearDown(() => SoundService.suppressNativePlaybackForTesting = false);
    await service.initialize();

    await service.removeAchievement('143');
    await service.addAchievement(
      Achievement(
        id: '143',
        title: 'Cherry: Midday Spring',
        reward: zenStageBonsaiRewardText(2),
        task: 'Clear Cherry Blossom Tree stage Midday Spring',
        isSecret: false,
        progress: 100,
      ),
    );

    final before = await points.readBalance();
    await service.completeAchievement('143');
    expect(await points.readBalance(), before);

    final after = await garden.load();
    expect(after.decorInventory.single.kind, zenStageBonsaiKind(2));
    expect(after.decorInventory.single.stageIndex, DecorItem.maxStageIndex);
  });

  test('zen stage bonsai tile width scales vs bonsai garden reference', () {
    expect(ZenDecorVisual.pathBonsaiWidth, greaterThan(0));
    expect(
      ZenDecorVisual.pathBonsaiWidth /
          72, // CherryBlossomBonsaiTile.petalScaleReferenceWidth
      closeTo(88 / 72, 0.0001),
    );
  });
}
