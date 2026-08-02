import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Updates Firefly Jar best-catch counters and achievement progress after a round.
abstract final class FireflyJarAchievements {
  static Future<List<Object>> recordRound({
    required KeyValueStorage storage,
    required AchievementService achievements,
    required int catchCount,
    required bool endless,
  }) async {
    final key = endless
        ? StorageKeys.fireflyJarBestEndless
        : StorageKeys.fireflyJarBestDuration;
    final previous = int.tryParse(await storage.read(key: key) ?? '') ?? 0;
    final best = catchCount > previous ? catchCount : previous;
    if (best != previous) {
      await storage.write(key: key, value: '$best');
    }
    return achievements.updateProgressForTrackingKeys({key});
  }
}
