import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Updates Stone Balance height / timeout counters and achievement progress.
abstract final class StoneBalanceAchievements {
  static Future<List<Object>> recordRound({
    required KeyValueStorage storage,
    required AchievementService achievements,
    required int height,
    required bool endless,
    required bool finishedByTimeout,
  }) async {
    final keys = <String>{};

    final prevBest =
        int.tryParse(
          await storage.read(key: StorageKeys.stoneBalanceBestHeight) ?? '',
        ) ??
        0;
    if (height > prevBest) {
      await storage.write(
        key: StorageKeys.stoneBalanceBestHeight,
        value: '$height',
      );
    }
    keys.add(StorageKeys.stoneBalanceBestHeight);

    if (endless) {
      final prevEndless =
          int.tryParse(
            await storage.read(key: StorageKeys.stoneBalanceBestEndless) ?? '',
          ) ??
          0;
      if (height > prevEndless) {
        await storage.write(
          key: StorageKeys.stoneBalanceBestEndless,
          value: '$height',
        );
      }
      keys.add(StorageKeys.stoneBalanceBestEndless);
    }

    if (finishedByTimeout) {
      final prevTimeout =
          int.tryParse(
            await storage.read(
                  key: StorageKeys.stoneBalanceBestTimeoutHeight,
                ) ??
                '',
          ) ??
          0;
      if (height > prevTimeout) {
        await storage.write(
          key: StorageKeys.stoneBalanceBestTimeoutHeight,
          value: '$height',
        );
      }
      keys.add(StorageKeys.stoneBalanceBestTimeoutHeight);
    }

    return achievements.updateProgressForTrackingKeys(keys);
  }
}
