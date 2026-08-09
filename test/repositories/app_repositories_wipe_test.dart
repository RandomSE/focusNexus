import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
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

  test('wipeAllUserData clears ambient music prefs and PV points', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.ambientEnabled: 'true',
        StorageKeys.ambientGlobalTrackId: 'piano',
        StorageKeys.ownedAmbientSounds: '["piano","running_water","white_noise"]',
        StorageKeys.progressiveVisualsPoints: '12345',
      },
    );
    final repos = AppRepositories(storage);
    await repos.ambientSoundscapes.readEnabled();
    await repos.progressiveVisualsPoints.readBalance();
    expect(await repos.ambientSoundscapes.readEnabled(), isTrue);
    expect(await repos.progressiveVisualsPoints.readBalance(), 12345);
    expect(await repos.ambientSoundscapes.readOwnedIds(), contains('piano'));

    await repos.wipeAllUserData();

    expect(await repos.ambientSoundscapes.readEnabled(), isFalse);
    expect(
      await repos.ambientSoundscapes.readGlobalTrackId(),
      AmbientSoundscapeCatalog.noneTrackId,
    );
    expect(
      await repos.ambientSoundscapes.readOwnedIds(),
      AmbientSoundscapeCatalog.freeTrackIds,
    );
    expect(await repos.progressiveVisualsPoints.readBalance(), 0);
    expect(storage.snapshot[StorageKeys.progressiveVisualsPoints], '0');
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
