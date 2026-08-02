import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wipeAllUserData clears storage and resets points to default', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '9999'},
    );
    final repos = AppRepositories(storage);
    await repos.points.readBalance();
    expect(await repos.points.readBalance(), 9999);

    await repos.wipeAllUserData();

    expect(storage.snapshot[StorageKeys.points], '50');
    expect(await repos.points.readBalance(), PointsRepository.defaultBalance);
  });

  test(
    'clearAll after wipe drops achievement cache so initialize reseeds empty progress',
    () async {
      final storage = InMemoryKeyValueStorage();
      final service = AchievementService(storage: storage);
      await service.initialize();
      expect(service.getById('136'), isNotNull);
      expect(service.all, isNotEmpty);

      await storage.write(key: StorageKeys.achievements, value: 'stale');
      await storage.write(key: StorageKeys.meteorCatchBestDuration, value: '99');

      final repos = AppRepositories(storage);
      await repos.wipeAllUserData();
      await service.clearAll();
      expect(service.all, isEmpty);
      expect(service.isInitialized, isFalse);
      expect(storage.snapshot[StorageKeys.achievements], isNull);

      await service.initialize();
      expect(service.getById('136')!.progress, 0);
      expect(service.getById('150')!.progress, 0);
      expect(
        await storage.read(key: StorageKeys.meteorCatchBestDuration),
        anyOf(isNull, '0'),
      );
    },
  );
}
