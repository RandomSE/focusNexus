import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/progressive_visuals_points_repository.dart';
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

  group('2026-08 PV-earn rebalance: claim credits wallet + PV', () {
    test('completeAchievement grants both wallet points and mapped PV',
        () async {
      memory = InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'});
      final pv = ProgressiveVisualsPointsRepository(memory);
      final service = AchievementService(
        storage: memory,
        pointsRepository: PointsRepository(memory),
        progressiveVisualsPointsRepository: pv,
        soundService: SoundService(memory),
      );
      await service.initialize();

      // id 76: All High Requirements VI -> 3600 wallet + 40000 PV.
      await service.completeAchievement('76');

      expect(service.getById('76')!.reward, '3600 points');
      expect(service.getById('76')!.isCompleted, isTrue);
      // PointsRepository.defaultBalance is 50 (not 0); wallet = 50 + 3600.
      expect(await memory.read(key: 'points'), '3650');
      expect(await pv.readBalance(), 40000);
    });

    test('a mono (wallet-only) achievement grants no PV', () async {
      memory = InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'});
      final pv = ProgressiveVisualsPointsRepository(memory);
      final service = AchievementService(
        storage: memory,
        pointsRepository: PointsRepository(memory),
        progressiveVisualsPointsRepository: pv,
        soundService: SoundService(memory),
      );
      await service.initialize();

      // id 75: All High Requirements V -> 3200 wallet, 0 PV (mono).
      await service.completeAchievement('75');

      expect(service.getById('75')!.reward, '3200 points');
      expect(await memory.read(key: 'points'), '3250');
      expect(await pv.readBalance(), 0);
    });

    test('completeAllClaimable batches wallet points and grants PV per claim',
        () async {
      memory = InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'});
      final pv = ProgressiveVisualsPointsRepository(memory);
      final service = AchievementService(
        storage: memory,
        pointsRepository: PointsRepository(memory),
        progressiveVisualsPointsRepository: pv,
        soundService: SoundService(memory),
        cachedAchievements: [
          _achievement(id: '98', progress: 100, reward: '1700 points'),
          _achievement(id: '99', progress: 100, reward: '2000 points'),
        ],
      );
      await service.setInitializationPrerequisites();

      final result = await service.completeAllClaimable();

      expect(result.claimedCount, 2);
      expect(result.pointsGained, 3700);
      expect(await memory.read(key: 'points'), '3750');
      // 98 -> 10000 PV, 99 -> 12000 PV (see achievement_pv_rewards.dart).
      expect(await pv.readBalance(), 22000);
    });

    test('without a wired PV repository, claim still grants wallet points',
        () async {
      memory = InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'});
      final service = AchievementService(
        storage: memory,
        pointsRepository: PointsRepository(memory),
        soundService: SoundService(memory),
      );
      await service.initialize();

      await service.completeAchievement('117');

      expect(service.getById('117')!.reward, '3500 points');
      expect(await memory.read(key: 'points'), '3550');
    });

    test('PV clamps at 1,000,000 across achievement claims and PV repo credits',
        () async {
      memory = InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'});
      final pv = ProgressiveVisualsPointsRepository(memory);
      await pv.writeBalance(970000);
      final service = AchievementService(
        storage: memory,
        pointsRepository: PointsRepository(memory),
        progressiveVisualsPointsRepository: pv,
        soundService: SoundService(memory),
      );
      await service.initialize();

      // id 78: 4500 wallet + 80000 PV; would overflow the 1,000,000 ceiling.
      await service.completeAchievement('78');

      expect(await pv.readBalance(), 1000000);
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
