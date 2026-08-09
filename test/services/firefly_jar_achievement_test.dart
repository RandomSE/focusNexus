import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_achievements.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('firefly achievements 118-122 are non-secret with expected rewards', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    expect(service.getById('118')!.isSecret, isFalse);
    expect(service.getById('118')!.reward, '40 points');
    expect(service.getById('119')!.reward, '100 points');
    expect(service.getById('120')!.reward, '200 points');
    expect(service.getById('121')!.reward, '400 points');
    expect(service.getById('122')!.title, 'Endless Lantern');
    expect(service.getById('122')!.reward, '400 points');
    expect(service.getById('122')!.isSecret, isFalse);
  });

  test('duration best catch count unlocks swarm progress', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await FireflyJarAchievements.recordRound(
      storage: storage,
      achievements: service,
      catchCount: 150,
      endless: false,
    );

    expect(await storage.read(key: StorageKeys.fireflyJarBestDuration), '150');
    expect(service.getById('118')!.progress, 100);
    expect(service.getById('119')!.progress, 100);
    expect(service.getById('120')!.progress, lessThan(100));
  });

  test('endless best catch count advances Endless Lantern', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    await FireflyJarAchievements.recordRound(
      storage: storage,
      achievements: service,
      catchCount: 250,
      endless: true,
    );
    expect(service.getById('122')!.progress, 50);

    await FireflyJarAchievements.recordRound(
      storage: storage,
      achievements: service,
      catchCount: 500,
      endless: true,
    );
    expect(service.getById('122')!.progress, 100);
  });
}
