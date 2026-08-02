import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Updates Breath Pacer best scores and achievement progress after a round.
abstract final class BreathPacerAchievements {
  static Future<List<Achievement>> recordRound({
    required KeyValueStorage storage,
    required AchievementService achievements,
    required int score,
    required bool endless,
  }) async {
    final key = endless
        ? StorageKeys.breathPacerBestEndless
        : StorageKeys.breathPacerBestDuration;
    final previous = int.tryParse(await storage.read(key: key) ?? '') ?? 0;
    final best = score > previous ? score : previous;
    if (best != previous) {
      await storage.write(key: key, value: '$best');
    }
    return achievements.updateProgressForTrackingKeys({key});
  }
}
