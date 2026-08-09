import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_achievements.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rain catcher achievements 168-187 titles and reward ladder', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    expect(service.getById('168')!.title, 'Rain Catcher I');
    expect(service.getById('168')!.reward, '40 points');
    expect(service.getById('168')!.isSecret, isFalse);
    expect(
      service.getById('168')!.task,
      contains('${RainCatcherConstants.durationTiers[0]}'),
    );
    expect(service.getById('172')!.title, 'Rain Catcher V');
    expect(
      service.getById('172')!.task,
      contains('${RainCatcherConstants.durationMaxAchievement}'),
    );
    expect(service.getById('173')!.title, 'Endless Deluge I');
    expect(
      service.getById('173')!.task,
      contains('${RainCatcherConstants.endlessTiers.first}'),
    );
    expect(service.getById('187')!.title, 'Endless Deluge IX');
    expect(
      service.getById('187')!.task,
      contains('${RainCatcherConstants.endlessTarget}'),
    );

    expect(service.getById('174')!.title, 'Rain Streak I');
    expect(
      service.getById('174')!.task,
      contains('${RainCatcherConstants.streakTiers.first}'),
    );
    expect(service.getById('178')!.title, 'Rain Streak V');
    expect(
      service.getById('178')!.task,
      contains('${RainCatcherConstants.streakMaxAchievement}'),
    );
    expect(service.getById('179')!.title, 'Endless Rain Streak');
    expect(
      service.getById('179')!.task,
      contains('${RainCatcherConstants.endlessStreakTarget}'),
    );
  });

  test('Duration vs Endless use distinct score and streak storage keys', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 60,
      bestStreak: 15,
      endless: false,
    );
    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 170,
      bestStreak: 40,
      endless: true,
    );

    expect(
      await storage.read(key: StorageKeys.rainCatcherBestDuration),
      '60',
    );
    expect(
      await storage.read(key: StorageKeys.rainCatcherBestEndless),
      '170',
    );
    expect(await storage.read(key: StorageKeys.rainCatcherBestStreak), '15');
    expect(
      await storage.read(key: StorageKeys.rainCatcherBestEndlessStreak),
      '40',
    );
  });

  test('best score is monotonic and distinct from points', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 130,
      bestStreak: 1,
      endless: false,
    );
    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 30,
      bestStreak: 0,
      endless: false,
    );

    expect(
      await storage.read(key: StorageKeys.rainCatcherBestDuration),
      '130',
    );
    expect(service.getById('168')!.progress, 100);
    expect(service.getById('169')!.progress, 100);
    expect(service.getById('170')!.progress, 100);
    expect(service.getById('171')!.progress, 100);
    expect(service.getById('172')!.progress, lessThan(100));
  });

  test('duration best advances Rain Catcher progress at score thresholds', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: RainCatcherConstants.durationTiers[2],
      bestStreak: 0,
      endless: false,
    );

    expect(service.getById('168')!.progress, 100);
    expect(service.getById('169')!.progress, 100);
    expect(service.getById('170')!.progress, 100);
    expect(service.getById('171')!.progress, lessThan(100));
  });

  test('endless best advances Endless Deluge progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 80,
      bestStreak: 0,
      endless: true,
    );
    expect(service.getById('173')!.progress, 100);
    expect(service.getById('187')!.progress, lessThan(100));

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: RainCatcherConstants.endlessTarget,
      bestStreak: 0,
      endless: true,
    );
    expect(service.getById('187')!.progress, 100);
  });

  test('duration catch streak advances Rain Streak progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 5,
      bestStreak: RainCatcherConstants.streakTiers[1],
      endless: false,
    );

    expect(service.getById('174')!.progress, 100);
    expect(service.getById('175')!.progress, 100);
    expect(service.getById('176')!.progress, lessThan(100));
    expect(
      await storage.read(key: StorageKeys.rainCatcherBestStreak),
      '${RainCatcherConstants.streakTiers[1]}',
    );
  });

  test('endless catch streak advances Endless Rain Streak progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 50,
      bestStreak: 88,
      endless: true,
    );
    expect(service.getById('179')!.progress, lessThan(100));

    await RainCatcherAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 50,
      bestStreak: RainCatcherConstants.endlessStreakTarget,
      endless: true,
    );
    expect(service.getById('179')!.progress, 100);
  });

  test(
    'rain catcher reps sit after word bloom so indexWhere maps 168 and 174 correctly',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      final index168 = service.all.indexWhere((a) => a.id == '168');
      expect(index168, greaterThan(-1));
      expect(
        service.achievementRepetitions[index168],
        AchievementService.rainCatcherDurationRepetitions.first,
      );
      final index173 = service.all.indexWhere((a) => a.id == '173');
      expect(
        service.achievementRepetitions[index173],
        AchievementService.rainCatcherEndlessRepetitions.first,
      );
      final index187 = service.all.indexWhere((a) => a.id == '187');
      expect(
        service.achievementRepetitions[index187],
        AchievementService.rainCatcherEndlessRepetitions.last,
      );
      final index174 = service.all.indexWhere((a) => a.id == '174');
      expect(
        service.achievementRepetitions[index174],
        AchievementService.rainCatcherStreakRepetitions.first,
      );
      final index179 = service.all.indexWhere((a) => a.id == '179');
      expect(
        service.achievementRepetitions[index179],
        AchievementService.rainCatcherEndlessStreakRepetition,
      );
    },
  );
}
