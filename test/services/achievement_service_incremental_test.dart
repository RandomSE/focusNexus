import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/repositories/achievement_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

Achievement _achievement({
  String id = '1',
  double progress = 0,
  String reward = '100 points',
  bool isCompleted = false,
}) {
  return Achievement(
    id: id,
    title: 'Goal Setter I',
    reward: reward,
    task: 'Create goals 10 times',
    isSecret: false,
    progress: progress,
    isCompleted: isCompleted,
  );
}

Future<AchievementService> _initializedService(
  InMemoryKeyValueStorage memory, {
  required List<Achievement> achievements,
  AchievementRepository? repository,
}) async {
  await (repository ?? AchievementRepository(memory)).saveAll(achievements);
  final service = AchievementService(
    storage: memory,
    repository: repository ?? AchievementRepository(memory),
    pointsRepository: PointsRepository(memory),
    soundService: SoundService(memory),
  );
  await service.setInitializationPrerequisites();
  await service.initialize();
  return service;
}

void main() {
  late InMemoryKeyValueStorage memory;

  setUp(() {
    memory = InMemoryKeyValueStorage();
  });

  group('initialize idempotency', () {
    test('second initialize is a no-op', () async {
      memory = InMemoryKeyValueStorage();
      await AchievementRepository(memory).saveAll([_achievement()]);
      var loadCount = 0;
      final service = AchievementService(
        storage: memory,
        repository: _CountingAchievementRepository(
          memory,
          onLoad: () => loadCount++,
        ),
        pointsRepository: PointsRepository(memory),
        soundService: SoundService(memory),
      );
      await service.setInitializationPrerequisites();

      await service.initialize();
      expect(service.isInitialized, isTrue);
      expect(loadCount, 1);

      await service.initialize();
      expect(loadCount, 1);
    });
  });

  group('updateProgressForTrackingKeys', () {
    test('updates only achievements mapped to the key', () async {
      memory = InMemoryKeyValueStorage(initial: {
        StorageKeys.totalGoalsCreated: '1',
        StorageKeys.totalGoalsCompleted: '50',
      });
      final service = await _initializedService(
        memory,
        achievements: [
          _achievement(id: '1'),
          _achievement(id: '6', progress: 0),
        ],
      );
      service.updateProgressInvocationCount = 0;

      await service.updateProgressForTrackingKeys({
        StorageKeys.totalGoalsCreated,
      });

      expect(service.updateProgressInvocationCount, 3);
      expect(service.getById('1')!.progress, 10.0);
      expect(service.getById('6')!.progress, 0);
    });

    test('returns newly completable achievements', () async {
      memory = InMemoryKeyValueStorage(initial: {
        StorageKeys.totalGoalsCreated: '10',
      });
      final service = await _initializedService(
        memory,
        achievements: [_achievement()],
      );

      final ready = await service.updateProgressForTrackingKeys({
        StorageKeys.totalGoalsCreated,
      });

      expect(ready, hasLength(1));
      expect(ready.first.id, '1');
      expect(ready.first.progress, 100);
    });
  });

  group('progress cap', () {
    test('stores at most 100% when counter exceeds target', () async {
      memory = InMemoryKeyValueStorage(initial: {
        StorageKeys.totalGoalsCreated: '50',
      });
      final service = await _initializedService(
        memory,
        achievements: [_achievement()],
      );

      await service.updateProgressForTrackingKeys({
        StorageKeys.totalGoalsCreated,
      });

      expect(service.getById('1')!.progress, 100);
    });

    test('sanitize clamps legacy stored progress above 100', () async {
      memory = InMemoryKeyValueStorage();
      final service = await _initializedService(
        memory,
        achievements: [_achievement(progress: 3285)],
      );

      expect(service.getById('1')!.progress, 100);
    });
  });
}

class _CountingAchievementRepository extends AchievementRepository {
  _CountingAchievementRepository(super.storage, {required this.onLoad});

  final void Function() onLoad;

  @override
  Future<List<Achievement>?> loadAll() async {
    onLoad();
    return super.loadAll();
  }
}
