import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Updates Word Bloom best score / order-streak counters and progress.
abstract final class WordBloomAchievements {
  static Future<List<Object>> recordRound({
    required KeyValueStorage storage,
    required AchievementService achievements,
    required int score,
    required int bestStreak,
    required bool endless,
  }) async {
    final scoreKey = endless
        ? StorageKeys.wordBloomBestEndless
        : StorageKeys.wordBloomBestDuration;
    final streakKey = endless
        ? StorageKeys.wordBloomBestEndlessStreak
        : StorageKeys.wordBloomBestStreak;

    final previousScore =
        int.tryParse(await storage.read(key: scoreKey) ?? '') ?? 0;
    final bestScore = score > previousScore ? score : previousScore;
    if (bestScore != previousScore) {
      await storage.write(key: scoreKey, value: '$bestScore');
    }

    final previousStreak =
        int.tryParse(await storage.read(key: streakKey) ?? '') ?? 0;
    final best = bestStreak > previousStreak ? bestStreak : previousStreak;
    if (best != previousStreak) {
      await storage.write(key: streakKey, value: '$best');
    }

    return achievements.updateProgressForTrackingKeys({scoreKey, streakKey});
  }
}
