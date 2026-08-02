import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
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

/// Reward points for clearing a playable stage (10% of stage total, min 100).
int cherryBlossomStageAchievementReward(int stageIndex) {
  final total = CherryBlossomStageCatalog.stageTotalFor(stageIndex);
  final tenth = (0.10 * total).round();
  return tenth < 100 ? 100 : tenth;
}

Future<void> _flipFlagIfNeeded({
  required KeyValueStorage storage,
  required Set<String> keys,
  required String flagKey,
  required bool condition,
}) async {
  if (!condition) return;
  final existing = await storage.read(key: flagKey);
  if (existing == '1') return;
  await storage.write(key: flagKey, value: '1');
  keys.add(flagKey);
}

/// Writes zen-garden achievement counters only when flags newly flip on.
///
/// Returns newly completable achievements and whether any flags progressed.
Future<({List<Achievement> newlyReady, bool progressed})>
    syncZenGardenAchievements({
  required KeyValueStorage storage,
  required AchievementService achievements,
  required GardenState garden,
}) async {
  final keys = <String>{};
  final tree = garden.cherryBlossomTree.normalized();

  await _flipFlagIfNeeded(
    storage: storage,
    keys: keys,
    flagKey: StorageKeys.cherryBlossomTreeUnlockedFlag,
    condition: garden.cherryBlossomTreeUnlocked,
  );

  await _flipFlagIfNeeded(
    storage: storage,
    keys: keys,
    flagKey: StorageKeys.cherryBlossomTreeMaxedFlag,
    condition: isCherryBlossomTreeMaxed(garden.cherryBlossomTree),
  );

  for (var stage = 0; stage < CherryBlossomStageCatalog.stageCount; stage++) {
    final completed = tree.stageIndex > stage ||
        (stage == CherryBlossomStageCatalog.maxPlayableStage && tree.isFinale);
    await _flipFlagIfNeeded(
      storage: storage,
      keys: keys,
      flagKey: StorageKeys.cherryBlossomStageCompleteFlags[stage],
      condition: completed,
    );
  }

  final peaceUnlocked = tree.isFinalePathUnlocked(CherryBlossomPrestigePath.peace) ||
      tree.prestigePath == CherryBlossomPrestigePath.peace;
  final powerUnlocked = tree.isFinalePathUnlocked(CherryBlossomPrestigePath.power) ||
      tree.prestigePath == CherryBlossomPrestigePath.power;

  await _flipFlagIfNeeded(
    storage: storage,
    keys: keys,
    flagKey: StorageKeys.cherryBlossomPeacePathFlag,
    condition: peaceUnlocked,
  );
  await _flipFlagIfNeeded(
    storage: storage,
    keys: keys,
    flagKey: StorageKeys.cherryBlossomPowerPathFlag,
    condition: powerUnlocked,
  );

  if (keys.isEmpty) {
    return (newlyReady: const <Achievement>[], progressed: false);
  }
  final newlyReady = await achievements.updateProgressForTrackingKeys(keys);
  return (newlyReady: newlyReady, progressed: true);
}
