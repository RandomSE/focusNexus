import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_achievement_sync.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('isCherryBlossomTreeMaxed', () {
    test('false for empty tree', () {
      expect(isCherryBlossomTreeMaxed(CherryBlossomTreeState.initial()), isFalse);
    });

    test('true for maxed tree', () {
      expect(
        isCherryBlossomTreeMaxed(CherryBlossomTreeEngine.maxedFinale()),
        isTrue,
      );
    });
  });

  group('syncZenGardenAchievements', () {
    test('writes unlock flag and updates achievement 112', () async {
      final storage = InMemoryKeyValueStorage();
      final achievements = AchievementService(storage: storage);
      await achievements.initialize();

      final ready = await syncZenGardenAchievements(
        storage: storage,
        achievements: achievements,
        garden: const GardenState(
          pointsBalance: 12000,
          cherryBlossomTreeUnlocked: true,
        ),
      );

      expect(
        await storage.read(key: StorageKeys.cherryBlossomTreeUnlockedFlag),
        '1',
      );
      expect(ready.newlyReady.any((a) => a.id == '112'), isTrue);
      expect(ready.progressed, isTrue);
      final sakura = achievements.all.firstWhere((a) => a.id == '112');
      expect(sakura.progress, 100);
    });

    test('writes maxed flag and updates achievement 113', () async {
      final storage = InMemoryKeyValueStorage();
      final achievements = AchievementService(storage: storage);
      await achievements.initialize();

      final ready = await syncZenGardenAchievements(
        storage: storage,
        achievements: achievements,
        garden: GardenState(
          pointsBalance: 0,
          cherryBlossomTreeUnlocked: true,
          cherryBlossomTree: CherryBlossomTreeEngine.maxedFinale(),
        ),
      );

      expect(
        await storage.read(key: StorageKeys.cherryBlossomTreeMaxedFlag),
        '1',
      );
      expect(ready.newlyReady.any((a) => a.id == '113'), isTrue);
      expect(ready.progressed, isTrue);
    });
  });
}
