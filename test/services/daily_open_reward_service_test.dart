import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/daily_open_reward_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('DailyOpenRewardService.rewardForStreak', () {
    test('day 1 is base 50', () {
      expect(DailyOpenRewardService.rewardForStreak(1), 50);
    });

    test('escalates by 10 per streak day', () {
      expect(DailyOpenRewardService.rewardForStreak(2), 60);
      expect(DailyOpenRewardService.rewardForStreak(3), 70);
      expect(DailyOpenRewardService.rewardForStreak(16), 200);
    });

    test('caps at 350', () {
      expect(DailyOpenRewardService.rewardForStreak(31), 350);
      expect(DailyOpenRewardService.rewardForStreak(100), 350);
    });

    test('parameterized maxCap 200', () {
      expect(
        DailyOpenRewardService.rewardForStreak(16, maxCap: 200),
        200,
      );
      expect(
        DailyOpenRewardService.rewardForStreak(31, maxCap: 200),
        200,
      );
      expect(
        DailyOpenRewardService.rewardForStreak(10, maxCap: 200),
        140,
      );
    });

    test('treats non-positive streak as day 1', () {
      expect(DailyOpenRewardService.rewardForStreak(0), 50);
      expect(DailyOpenRewardService.rewardForStreak(-3), 50);
    });
  });

  group('DailyOpenRewardService.tryGrant', () {
    late InMemoryKeyValueStorage storage;
    late PointsRepository points;
    late DailyOpenRewardService service;

    setUp(() {
      storage = InMemoryKeyValueStorage(initial: {StorageKeys.points: '100'});
      points = PointsRepository(storage);
      service = DailyOpenRewardService(storage: storage, points: points);
    });

    test('first open of day grants and persists streak 1', () async {
      final now = DateTime(2026, 7, 19, 9, 0);
      final result = await service.tryGrant(now: now);

      expect(result.granted, isTrue);
      expect(result.amount, 50);
      expect(result.newStreak, 1);
      expect(await points.readBalance(), 150);
      expect(
        await storage.read(key: StorageKeys.lastAppOpenGrantDate),
        '2026-07-19',
      );
      expect(
        await storage.read(key: StorageKeys.consecutiveDaysAppOpened),
        '1',
      );
    });

    test('second open same calendar day does not grant', () async {
      final morning = DateTime(2026, 7, 19, 9, 0);
      final evening = DateTime(2026, 7, 19, 21, 0);
      await service.tryGrant(now: morning);
      final balanceAfterFirst = await points.readBalance();

      final second = await service.tryGrant(now: evening);

      expect(second.granted, isFalse);
      expect(second.amount, 0);
      expect(second.newStreak, 1);
      expect(await points.readBalance(), balanceAfterFirst);
    });

    test('streak increments across consecutive calendar days', () async {
      await service.tryGrant(now: DateTime(2026, 7, 19, 10));
      final day2 = await service.tryGrant(now: DateTime(2026, 7, 20, 10));

      expect(day2.granted, isTrue);
      expect(day2.newStreak, 2);
      expect(day2.amount, 60);
      expect(
        await storage.read(key: StorageKeys.consecutiveDaysAppOpened),
        '2',
      );
    });

    test('missed calendar day resets streak to 1', () async {
      await service.tryGrant(now: DateTime(2026, 7, 19, 10));
      final afterMiss = await service.tryGrant(now: DateTime(2026, 7, 21, 10));

      expect(afterMiss.granted, isTrue);
      expect(afterMiss.newStreak, 1);
      expect(afterMiss.amount, 50);
      expect(
        await storage.read(key: StorageKeys.consecutiveDaysAppOpened),
        '1',
      );
    });

    test('storage failure fails soft without throwing', () async {
      final failing = _ThrowingStorage();
      final soft = DailyOpenRewardService(
        storage: failing,
        points: PointsRepository(InMemoryKeyValueStorage()),
      );

      final result = await soft.tryGrant(now: DateTime(2026, 7, 19));

      expect(result.granted, isFalse);
      expect(result.amount, 0);
    });
  });
}

class _ThrowingStorage extends InMemoryKeyValueStorage {
  @override
  Future<String?> read({required String key}) async {
    throw StateError('forced read failure');
  }
}
