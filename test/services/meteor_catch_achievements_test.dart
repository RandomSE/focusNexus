import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/meteor_catch/meteor_catch_achievements.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'meteor achievements 136-140 titles and Firefly/Stone reward ladder',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      expect(service.getById('136')!.title, 'Meteor Shower I');
      expect(service.getById('136')!.reward, '100 points');
      expect(service.getById('136')!.isSecret, isFalse);
      expect(service.getById('137')!.title, 'Meteor Shower II');
      expect(service.getById('137')!.reward, '250 points');
      expect(service.getById('138')!.title, 'Meteor Shower III');
      expect(service.getById('138')!.reward, '500 points');
      expect(service.getById('139')!.title, 'Meteor Shower IV');
      expect(service.getById('139')!.reward, '1000 points');
      expect(service.getById('140')!.title, 'Endless Skies');
      expect(service.getById('140')!.reward, '2500 points');
      expect(service.getById('140')!.isSecret, isFalse);
    },
  );

  test('meteor streak achievements 150-155 titles and rewards', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    expect(service.getById('150')!.title, 'Meteor Streak I');
    expect(service.getById('150')!.reward, '100 points');
    expect(service.getById('151')!.reward, '250 points');
    expect(service.getById('152')!.reward, '500 points');
    expect(service.getById('153')!.reward, '1000 points');
    expect(service.getById('154')!.reward, '2500 points');
    expect(service.getById('155')!.title, 'Endless Streak');
    expect(service.getById('155')!.reward, '2500 points');
    expect(service.getById('155')!.task, contains('100'));
  });

  test('Duration vs Endless use distinct storage keys', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 40,
      bestStreak: 5,
      endless: false,
    );
    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 120,
      bestStreak: 12,
      endless: true,
    );

    expect(await storage.read(key: StorageKeys.meteorCatchBestDuration), '40');
    expect(await storage.read(key: StorageKeys.meteorCatchBestEndless), '120');
    expect(await storage.read(key: StorageKeys.meteorCatchBestStreak), '5');
    expect(
      await storage.read(key: StorageKeys.meteorCatchBestEndlessStreak),
      '12',
    );
  });

  test('best-score is monotonic (lower rounds do not reduce best)', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 60,
      bestStreak: 0,
      endless: false,
    );
    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 30,
      bestStreak: 0,
      endless: false,
    );

    expect(await storage.read(key: StorageKeys.meteorCatchBestDuration), '60');
    expect(service.getById('136')!.progress, 100);
    expect(service.getById('137')!.progress, 100);
    expect(service.getById('138')!.progress, lessThan(100));
  });

  test('duration best score advances Meteor Shower progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 50,
      bestStreak: 0,
      endless: false,
    );

    expect(await storage.read(key: StorageKeys.meteorCatchBestDuration), '50');
    expect(service.getById('136')!.progress, 100);
    expect(service.getById('137')!.progress, 100);
    expect(service.getById('138')!.progress, lessThan(100));
  });

  test('endless best score advances Endless Skies progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 125,
      bestStreak: 0,
      endless: true,
    );
    expect(service.getById('140')!.progress, 50);

    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 250,
      bestStreak: 0,
      endless: true,
    );
    expect(service.getById('140')!.progress, 100);
  });

  test(
    'duration streak advances Meteor Streak progress without changing score',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      await MeteorCatchAchievements.recordRound(
        storage: storage,
        achievements: service,
        score: 0,
        bestStreak: 25,
        endless: false,
      );

      expect(await storage.read(key: StorageKeys.meteorCatchBestStreak), '25');
      expect(service.getById('150')!.progress, 100);
      expect(service.getById('151')!.progress, 100);
      expect(service.getById('152')!.progress, lessThan(100));
      expect(service.getById('136')!.progress, 0);
    },
  );

  test('endless streak advances Endless Streak progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 0,
      bestStreak: 50,
      endless: true,
    );
    expect(service.getById('155')!.progress, 50);

    await MeteorCatchAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 0,
      bestStreak: 100,
      endless: true,
    );
    expect(service.getById('155')!.progress, 100);
  });
}
