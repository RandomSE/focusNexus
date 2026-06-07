import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/sound_service.dart';

import '../helpers/in_memory_key_value_storage.dart';

Achievement _achievement({
  String id = '1',
  double progress = 0,
  String reward = '100 points',
}) {
  return Achievement(
    id: id,
    title: 'Goal Setter I',
    reward: reward,
    task: 'Create goals 10 times',
    isSecret: false,
    progress: progress,
  );
}

Future<AchievementService> _service(
  InMemoryKeyValueStorage memory, {
  List<Achievement>? cached,
  PointsRepository? points,
}) async {
  final service = AchievementService(
    storage: memory,
    pointsRepository: points ?? PointsRepository(memory),
    soundService: SoundService(memory),
    cachedAchievements: cached,
  );
  await service.setInitializationPrerequisites();
  return service;
}

void main() {
  late InMemoryKeyValueStorage memory;

  setUp(() {
    memory = InMemoryKeyValueStorage();
  });

  group('updateProgress', () {
    test('updates cached progress from tracking variable in storage', () async {
      memory = InMemoryKeyValueStorage(initial: {'totalGoalsCreated': '5'});
      final service = await _service(memory, cached: [_achievement()]);

      await service.updateProgress('1');

      expect(service.getById('1')!.progress, 50.0);
    });

    test('does not decrease progress once achievement reached 100%', () async {
      memory = InMemoryKeyValueStorage(initial: {'totalGoalsCreated': '0'});
      final service = await _service(
        memory,
        cached: [_achievement(progress: 100)],
      );

      await service.updateProgress('1');

      expect(service.getById('1')!.progress, 100);
    });

    test('ignores unknown achievement ids', () async {
      final service = await _service(memory, cached: [_achievement()]);

      await service.updateProgress('999');

      expect(service.getById('1')!.progress, 0);
    });
  });

  group('completeAchievement', () {
    test('marks complete and adds point rewards to storage', () async {
      memory = InMemoryKeyValueStorage(initial: {
        'points': '100',
        'soundEnabled': 'false',
      });
      final service = await _service(
        memory,
        cached: [_achievement(reward: '250 points')],
      );

      await service.completeAchievement('1');

      final updated = service.getById('1')!;
      expect(updated.isCompleted, isTrue);
      expect(memory.snapshot['points'], '350');
    });

    test('skips duplicate completion', () async {
      memory = InMemoryKeyValueStorage(initial: {
        'points': '50',
        'soundEnabled': 'false',
      });
      final service = await _service(
        memory,
        cached: [
          _achievement(reward: '100 points').copyWith(isCompleted: true),
        ],
      );

      await service.completeAchievement('1');

      expect(memory.snapshot['points'], '50');
    });
  });

  group('addAchievement', () {
    test('persists new achievements without duplicates', () async {
      final service = await _service(memory, cached: []);
      final achievement = _achievement(id: '42');
      await service.addAchievement(achievement);
      await service.addAchievement(achievement);

      expect(service.all.length, 1);
      expect(service.getById('42'), isNotNull);
    });
  });
}
