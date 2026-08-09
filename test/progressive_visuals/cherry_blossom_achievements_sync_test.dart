import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_achievement_sync.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  test('stage achievement reward helper tracks 10% of geometric stage totals', () {
    expect(cherryBlossomStageAchievementReward(0), 100); // max(100, 50)
    expect(cherryBlossomStageAchievementReward(1), 200); // 10% of 2000
    expect(cherryBlossomStageAchievementReward(2), 800); // 10% of 8000
    expect(
      cherryBlossomStageAchievementReward(6),
      (0.10 * CherryBlossomStageCatalog.stageTotalFor(6)).round(),
    );
  });

  test('sync flips stage and path flags once', () async {
    final storage = InMemoryKeyValueStorage();
    final achievements = AchievementService(storage: storage);
    await achievements.initialize();

    final garden = GardenState(
      pointsBalance: 0,
      cherryBlossomTreeUnlocked: true,
      cherryBlossomTree: const CherryBlossomTreeState(
        stageIndex: CherryBlossomStageCatalog.finaleStage,
        growthStepsInStage: 1,
        prestigePath: CherryBlossomPrestigePath.peace,
        unlockedFinalePaths: [CherryBlossomPrestigePath.peace],
      ),
    );

    final first = await syncZenGardenAchievements(
      storage: storage,
      achievements: achievements,
      garden: garden,
    );
    expect(first.newlyReady, isNotEmpty);
    expect(first.progressed, isTrue);
    expect(await storage.read(key: StorageKeys.cherryBlossomStage0CompleteFlag), '1');
    expect(await storage.read(key: StorageKeys.cherryBlossomPeacePathFlag), '1');

    final second = await syncZenGardenAchievements(
      storage: storage,
      achievements: achievements,
      garden: garden,
    );
    expect(second.newlyReady, isEmpty);
    expect(second.progressed, isFalse);
  });
}
