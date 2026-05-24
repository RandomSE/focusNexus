import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
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

void main() {
  late InMemoryKeyValueStorage memory;

  setUp(() async {
    memory = InMemoryKeyValueStorage();
    AchievementService.resetForTesting();
    SoundService.resetForTesting();
    SoundService.storage = memory;
    await AchievementService().setInitializationPrerequisites();
  });

  tearDown(() {
    AchievementService.resetForTesting();
    SoundService.resetForTesting();
  });

  group('updateProgress', () {
    test('updates cached progress from tracking variable in storage', () async {
      memory = InMemoryKeyValueStorage(initial: {'totalGoalsCreated': '5'});
      AchievementService.configureForTesting(
        keyValueStorage: memory,
        cachedAchievements: [_achievement()],
      );

      await AchievementService.updateProgress('1');

      expect(AchievementService.getById('1')!.progress, 50.0);
    });

    test('does not decrease progress once achievement reached 100%', () async {
      memory = InMemoryKeyValueStorage(initial: {'totalGoalsCreated': '0'});
      AchievementService.configureForTesting(
        keyValueStorage: memory,
        cachedAchievements: [_achievement(progress: 100)],
      );

      await AchievementService.updateProgress('1');

      expect(AchievementService.getById('1')!.progress, 100);
    });

    test('ignores unknown achievement ids', () async {
      AchievementService.configureForTesting(
        keyValueStorage: memory,
        cachedAchievements: [_achievement()],
      );

      await AchievementService.updateProgress('999');

      expect(AchievementService.getById('1')!.progress, 0);
    });
  });

  group('completeAchievement', () {
    test('marks complete and adds point rewards to storage', () async {
      memory = InMemoryKeyValueStorage(initial: {
        'points': '100',
        'soundEnabled': 'false',
      });
      AchievementService.configureForTesting(
        keyValueStorage: memory,
        cachedAchievements: [_achievement(reward: '250 points')],
      );

      await AchievementService().completeAchievement('1');

      final updated = AchievementService.getById('1')!;
      expect(updated.isCompleted, isTrue);
      expect(memory.snapshot['points'], '350');
    });

    test('skips duplicate completion', () async {
      memory = InMemoryKeyValueStorage(initial: {'points': '50', 'soundEnabled': 'false'});
      AchievementService.configureForTesting(
        keyValueStorage: memory,
        cachedAchievements: [
          _achievement(reward: '100 points').copyWith(isCompleted: true),
        ],
      );

      await AchievementService().completeAchievement('1');

      expect(memory.snapshot['points'], '50');
    });
  });

  group('addAchievement', () {
    test('persists new achievements without duplicates', () async {
      AchievementService.configureForTesting(
        keyValueStorage: memory,
        cachedAchievements: [],
      );

      final service = AchievementService();
      final achievement = _achievement(id: '42');
      await service.addAchievement(achievement);
      await service.addAchievement(achievement);

      expect(service.all.length, 1);
      expect(memory.snapshot.containsKey('achievements'), isTrue);
    });
  });
}

extension on Achievement {
  Achievement copyWith({bool? isCompleted, double? progress, String? reward}) {
    return Achievement(
      id: id,
      title: title,
      reward: reward ?? this.reward,
      task: task,
      dateCompleted: dateCompleted,
      isCompleted: isCompleted ?? this.isCompleted,
      isSecret: isSecret,
      progress: progress ?? this.progress,
    );
  }
}
