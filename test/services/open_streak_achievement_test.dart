import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('open-streak achievements 114-117', () {
    test('fresh initialize seeds open-streak track', () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      expect(service.getById('114'), isNotNull);
      expect(service.getById('115'), isNotNull);
      expect(service.getById('116'), isNotNull);
      final secret = service.getById('117')!;
      expect(secret.isSecret, isTrue);
      expect(secret.title, 'Ninety Sunrises');
      expect(service.all.length, 173);
    });

    test('upgrade path ensures 114-117 when missing', () async {
      final storage = InMemoryKeyValueStorage();
      final first = AchievementService(storage: storage);
      await first.initialize();
      await first.removeAchievement('114');
      await first.removeAchievement('115');
      await first.removeAchievement('116');
      await first.removeAchievement('117');
      first.resetInitializedForTesting();

      final upgraded = AchievementService(storage: storage);
      await upgraded.initialize();

      expect(upgraded.getById('114'), isNotNull);
      expect(upgraded.getById('117')!.isSecret, isTrue);
    });

    test('progress reaches 100% at 3/7/30/90 open days', () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      Future<void> setStreak(int days) async {
        await storage.write(
          key: StorageKeys.consecutiveDaysAppOpened,
          value: days.toString(),
        );
        await service.updateProgressForTrackingKeys({
          StorageKeys.consecutiveDaysAppOpened,
        });
      }

      await setStreak(3);
      expect(service.getById('114')!.progress, 100);
      expect(service.getById('115')!.progress, closeTo(42.9, 0.1));

      await setStreak(7);
      expect(service.getById('115')!.progress, 100);

      await setStreak(30);
      expect(service.getById('116')!.progress, 100);
      expect(service.getById('117')!.isSecret, isTrue);
      expect(service.getById('117')!.progress, closeTo(33.3, 0.1));

      await setStreak(90);
      expect(service.getById('117')!.progress, 100);
      expect(service.getById('117')!.isSecret, isTrue);
    });

    test('does not alter goal-completion streak mapping 88-93', () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      expect(
        service.getVariableForAchievement('88'),
        StorageKeys.consecutiveDaysWithGoalsCompleted,
      );
      expect(
        service.getVariableForAchievement('114'),
        StorageKeys.consecutiveDaysAppOpened,
      );
    });

    test('recomputeAllProgress updates zen and open-streak ids', () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      await storage.write(
        key: StorageKeys.cherryBlossomTreeUnlockedFlag,
        value: '1',
      );
      await storage.write(
        key: StorageKeys.consecutiveDaysAppOpened,
        value: '7',
      );

      await service.recomputeAllProgress();

      expect(service.getById('112')!.progress, 100);
      expect(service.getById('115')!.progress, 100);
      expect(service.getById('114')!.progress, 100);
    });
  });
}
