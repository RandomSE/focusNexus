import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_achievements.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('word bloom achievements 156-167 titles and reward ladder', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    expect(service.getById('156')!.title, 'Word Bloom I');
    expect(service.getById('156')!.reward, '100 points');
    expect(service.getById('156')!.isSecret, isFalse);
    expect(service.getById('156')!.task, contains('50'));
    expect(service.getById('157')!.title, 'Word Bloom II');
    expect(service.getById('157')!.reward, '250 points');
    expect(service.getById('158')!.title, 'Word Bloom III');
    expect(service.getById('158')!.reward, '500 points');
    expect(service.getById('159')!.title, 'Word Bloom IV');
    expect(service.getById('159')!.reward, '1000 points');
    expect(service.getById('160')!.title, 'Word Bloom V');
    expect(service.getById('160')!.reward, '2500 points');
    expect(service.getById('160')!.task, contains('350'));
    expect(service.getById('161')!.title, 'Endless Lexicon');
    expect(service.getById('161')!.reward, '2500 points');
    expect(service.getById('161')!.task, contains('1000'));

    expect(service.getById('162')!.title, 'Order Streak I');
    expect(service.getById('162')!.reward, '100 points');
    expect(service.getById('163')!.title, 'Order Streak II');
    expect(service.getById('163')!.reward, '250 points');
    expect(service.getById('164')!.title, 'Order Streak III');
    expect(service.getById('164')!.reward, '500 points');
    expect(service.getById('165')!.title, 'Order Streak IV');
    expect(service.getById('165')!.reward, '1000 points');
    expect(service.getById('166')!.title, 'Order Streak V');
    expect(service.getById('166')!.reward, '2500 points');
    expect(service.getById('166')!.task, contains('15'));
    expect(service.getById('167')!.title, 'Endless Order');
    expect(service.getById('167')!.reward, '2500 points');
    expect(service.getById('167')!.task, contains('30'));
  });

  test('Duration vs Endless use distinct score and streak storage keys', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 120,
      bestStreak: 3,
      endless: false,
    );
    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 400,
      bestStreak: 8,
      endless: true,
    );

    expect(await storage.read(key: StorageKeys.wordBloomBestDuration), '120');
    expect(await storage.read(key: StorageKeys.wordBloomBestEndless), '400');
    expect(await storage.read(key: StorageKeys.wordBloomBestStreak), '3');
    expect(await storage.read(key: StorageKeys.wordBloomBestEndlessStreak), '8');
  });

  test('best score is monotonic and distinct from points', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 200,
      bestStreak: 1,
      endless: false,
    );
    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 40,
      bestStreak: 0,
      endless: false,
    );

    expect(await storage.read(key: StorageKeys.wordBloomBestDuration), '200');
    expect(service.getById('156')!.progress, 100);
    expect(service.getById('157')!.progress, 100);
    expect(service.getById('158')!.progress, 100);
    expect(service.getById('159')!.progress, lessThan(100));
  });

  test('duration best advances Word Bloom progress at score thresholds', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 175,
      bestStreak: 0,
      endless: false,
    );

    expect(service.getById('156')!.progress, 100);
    expect(service.getById('157')!.progress, 100);
    expect(service.getById('158')!.progress, 100);
    expect(service.getById('159')!.progress, lessThan(100));
  });

  test('endless best advances Endless Lexicon progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 500,
      bestStreak: 0,
      endless: true,
    );
    expect(service.getById('161')!.progress, lessThan(100));

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 1000,
      bestStreak: 0,
      endless: true,
    );
    expect(service.getById('161')!.progress, 100);
  });

  test('duration order streak advances Order Streak progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 10,
      bestStreak: 6,
      endless: false,
    );

    expect(service.getById('162')!.progress, 100);
    expect(service.getById('163')!.progress, 100);
    expect(service.getById('164')!.progress, lessThan(100));
    expect(await storage.read(key: StorageKeys.wordBloomBestStreak), '6');
  });

  test('endless order streak advances Endless Order progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 50,
      bestStreak: 20,
      endless: true,
    );
    expect(service.getById('167')!.progress, lessThan(100));

    await WordBloomAchievements.recordRound(
      storage: storage,
      achievements: service,
      score: 50,
      bestStreak: 30,
      endless: true,
    );
    expect(service.getById('167')!.progress, 100);
  });

  test(
    'word bloom reps sit after meteor so indexWhere maps 156 and 162 correctly',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();

      final index156 = service.all.indexWhere((a) => a.id == '156');
      expect(index156, greaterThan(-1));
      expect(
        service.achievementRepetitions[index156],
        AchievementService.wordBloomDurationRepetitions.first,
      );
      final index161 = service.all.indexWhere((a) => a.id == '161');
      expect(
        service.achievementRepetitions[index161],
        AchievementService.wordBloomEndlessRepetition,
      );
      final index162 = service.all.indexWhere((a) => a.id == '162');
      expect(
        service.achievementRepetitions[index162],
        AchievementService.wordBloomStreakRepetitions.first,
      );
      final index167 = service.all.indexWhere((a) => a.id == '167');
      expect(
        service.achievementRepetitions[index167],
        AchievementService.wordBloomEndlessStreakRepetition,
      );
    },
  );
}
