import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_achievements.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stone balance achievements 123-129 have expected rewards', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    expect(service.getById('123')!.reward, '100 points');
    expect(service.getById('124')!.reward, '250 points');
    expect(service.getById('125')!.reward, '500 points');
    expect(service.getById('126')!.reward, '1000 points');
    expect(service.getById('127')!.reward, '2500 points');
    expect(service.getById('128')!.title, 'Endless Summit');
    expect(service.getById('128')!.reward, '5000 points');
    expect(service.getById('129')!.title, 'Beat the Clock');
    expect(service.getById('129')!.reward, '250 points');
  });

  test('best height advances cairn climber progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await StoneBalanceAchievements.recordRound(
      storage: storage,
      achievements: service,
      height: 35,
      endless: false,
      finishedByTimeout: false,
    );

    expect(await storage.read(key: StorageKeys.stoneBalanceBestHeight), '35');
    expect(service.getById('123')!.progress, 100);
    expect(service.getById('124')!.progress, 100);
    expect(service.getById('125')!.progress, lessThan(100));
  });

  test('endless height and timeout height track separately', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await StoneBalanceAchievements.recordRound(
      storage: storage,
      achievements: service,
      height: 250,
      endless: true,
      finishedByTimeout: false,
    );
    expect(service.getById('128')!.progress, 50);

    await StoneBalanceAchievements.recordRound(
      storage: storage,
      achievements: service,
      height: 30,
      endless: false,
      finishedByTimeout: true,
    );
    expect(
      await storage.read(key: StorageKeys.stoneBalanceBestTimeoutHeight),
      '30',
    );
    expect(service.getById('129')!.progress, 100);
  });
}
