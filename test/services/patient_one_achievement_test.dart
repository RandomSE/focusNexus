import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_achievements.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Patient One secret achievement exists with 1000 point reward',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      final achievement = service.getById('130')!;
      expect(achievement.title, 'Patient One');
      expect(achievement.reward, '1000 points');
      expect(achievement.isSecret, isTrue);
      expect(
        service.getVariableForAchievement('130'),
        StorageKeys.breathBackgroundFullListenFlag,
      );
    },
  );

  test('full Breath background listen unlocks Patient One progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    final ready = await service.recordBreathBackgroundFullListen();
    expect(
      await storage.read(key: StorageKeys.breathBackgroundFullListenFlag),
      '1',
    );
    expect(service.getById('130')!.progress, 100);
    expect(ready.map((a) => a.id), contains('130'));

    // Idempotent: second listen does not re-fire.
    final again = await service.recordBreathBackgroundFullListen();
    expect(again, isEmpty);
  });

  test(
    'Breath score achievements use Duration and Endless best scores',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      expect(
        [for (var id = 131; id <= 135; id++) service.getById('$id')?.reward],
        [
          '100 points',
          '250 points',
          '500 points',
          '1000 points',
          '2500 points',
        ],
      );
      expect(
        service.getVariableForAchievement('134'),
        StorageKeys.breathPacerBestDuration,
      );
      expect(
        service.getVariableForAchievement('135'),
        StorageKeys.breathPacerBestEndless,
      );

      final durationReady = await BreathPacerAchievements.recordRound(
        storage: storage,
        achievements: service,
        score: 1000,
        endless: false,
      );
      expect(
        durationReady.map((achievement) => achievement.id),
        containsAll(['131', '132', '133']),
      );
      expect(service.getById('134')!.progress, lessThan(100));

      final endlessReady = await BreathPacerAchievements.recordRound(
        storage: storage,
        achievements: service,
        score: 5000,
        endless: true,
      );
      expect(
        endlessReady.map((achievement) => achievement.id),
        contains('135'),
      );
    },
  );

  test('lower Breath score does not replace a stored best score', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await BreathPacerAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 500,
      endless: false,
    );
    await BreathPacerAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 200,
      endless: false,
    );

    expect(await storage.read(key: StorageKeys.breathPacerBestDuration), '500');
  });
}
