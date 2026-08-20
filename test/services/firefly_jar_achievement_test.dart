import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_achievements.dart';
import 'package:focusNexus/repositories/achievement_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('firefly achievements 118-122 and 188-190 are non-secret with expected rewards', () async {
    final storage = InMemoryKeyValueStorage();
    final service = AchievementService(storage: storage);
    await service.initialize();

    expect(service.getById('118')!.isSecret, isFalse);
    expect(service.getById('118')!.reward, '40 points');
    expect(service.getById('119')!.reward, '40 points');
    expect(service.getById('120')!.reward, '40 points');
    expect(service.getById('121')!.reward, '100 points');
    expect(service.getById('188')!.reward, '100 points');
    expect(service.getById('189')!.reward, '200 points');
    expect(service.getById('190')!.reward, '200 points');
    expect(service.getById('190')!.task, contains('200 fireflies'));
    expect(service.getById('122')!.title, 'Endless Lantern');
    expect(service.getById('122')!.reward, '500 points');
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
    expect(service.getById('120')!.progress, 100);
    expect(service.getById('121')!.progress, 100);
    expect(service.getById('188')!.progress, 100);
    expect(service.getById('189')!.progress, lessThan(100));
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

  test(
    'upgrade adds missing swarm tiers and recalculates duration progress',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.setInitializationPrerequisites();
      await service.initialize();
      await storage.write(
        key: StorageKeys.fireflyJarBestDuration,
        value: '150',
      );

      final repo = AchievementRepository(storage);
      final legacyCatalog = service.all
          .where((a) => !{'188', '189', '190'}.contains(a.id))
          .map(
            (a) => (int.parse(a.id) >= 118 && int.parse(a.id) <= 121)
                ? a.copyWith(progress: 0)
                : a,
          )
          .toList();
      await repo.saveAll(legacyCatalog);

      final upgraded = AchievementService(storage: storage);
      await upgraded.setInitializationPrerequisites();
      await upgraded.initialize();

      expect(upgraded.getById('188'), isNotNull);
      expect(upgraded.getById('189'), isNotNull);
      expect(upgraded.getById('190'), isNotNull);
      expect(upgraded.getById('118')!.progress, 100);
      expect(upgraded.getById('121')!.progress, 100);
      expect(upgraded.getById('188')!.progress, 100);
      expect(upgraded.getById('189')!.progress, lessThan(100));
    },
  );
}
