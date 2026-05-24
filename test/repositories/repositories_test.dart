import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('PointsRepository', () {
    late InMemoryKeyValueStorage storage;
    late PointsRepository repo;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      repo = PointsRepository(storage);
    });

    test('defaults to 50 when missing', () async {
      expect(await repo.readBalance(), 50);
    });

    test('ensureInitialized persists default', () async {
      expect(await repo.ensureInitialized(), 50);
      expect(await storage.read(key: StorageKeys.points), '50');
    });

    test('trySpend returns null when insufficient', () async {
      await repo.writeBalance(10);
      expect(await repo.trySpend(20), isNull);
      expect(await repo.readBalance(), 10);
    });

    test('trySpend deducts on success', () async {
      await repo.writeBalance(100);
      expect(await repo.trySpend(30), 70);
    });
  });

  group('GoalsRepository', () {
    late InMemoryKeyValueStorage storage;
    late GoalsRepository repo;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      repo = GoalsRepository(storage);
    });

    test('readActiveGoals returns empty list when missing', () async {
      expect(await repo.readActiveGoals(), isEmpty);
    });

    test('write and read active goals roundtrip', () async {
      final goals = [
        {'title': 'Walk', 'Id': '1'},
      ];
      await repo.writeActiveGoals(goals);
      expect(await repo.readActiveGoals(), goals);
    });

    test('areDeadlinesPaused accepts legacy True casing', () async {
      await storage.write(key: StorageKeys.pauseGoals, value: 'True');
      expect(await repo.areDeadlinesPaused(), isTrue);

      await storage.write(key: StorageKeys.pauseGoals, value: 'false');
      expect(await repo.areDeadlinesPaused(), isFalse);
    });

    test('completed today streak increments same day', () async {
      await repo.writeCompletedToday(today: '24 05 2026', count: 2);
      expect(await repo.nextCompletedTodayCount('24 05 2026'), 3);
      expect(await repo.nextCompletedTodayCount('25 05 2026'), 1);
    });
  });
}
