import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Whether the cherry blossom tree has reached the stage-7 finale.
bool isCherryBlossomTreeMaxed(CherryBlossomTreeState tree) {
  final normalized = tree.normalized();
  return normalized.isFinale && normalized.growthStepsInStage >= 1;
}

/// Writes zen-garden achievement counters only when flags newly flip on.
Future<List<Achievement>> syncZenGardenAchievements({
  required KeyValueStorage storage,
  required AchievementService achievements,
  required GardenState garden,
}) async {
  final keys = <String>{};

  if (garden.cherryBlossomTreeUnlocked) {
    final existing = await storage.read(key: StorageKeys.cherryBlossomTreeUnlockedFlag);
    if (existing != '1') {
      await storage.write(
        key: StorageKeys.cherryBlossomTreeUnlockedFlag,
        value: '1',
      );
      keys.add(StorageKeys.cherryBlossomTreeUnlockedFlag);
    }
  }

  if (isCherryBlossomTreeMaxed(garden.cherryBlossomTree)) {
    final existing = await storage.read(key: StorageKeys.cherryBlossomTreeMaxedFlag);
    if (existing != '1') {
      await storage.write(
        key: StorageKeys.cherryBlossomTreeMaxedFlag,
        value: '1',
      );
      keys.add(StorageKeys.cherryBlossomTreeMaxedFlag);
    }
  }

  if (keys.isEmpty) return const [];
  return achievements.updateProgressForTrackingKeys(keys);
}
