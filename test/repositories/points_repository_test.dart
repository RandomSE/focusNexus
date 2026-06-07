import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('PointsRepository', () {
    late InMemoryKeyValueStorage storage;
    late PointsRepository repo;

    setUp(() {
      storage = InMemoryKeyValueStorage(initial: {'points': '50'});
      repo = PointsRepository(storage);
    });

    test('add updates in-memory cache without clearing it first', () async {
      await repo.ensureInitialized();

      await repo.add(15);

      expect(await repo.readBalance(), 65);
      expect(await storage.read(key: StorageKeys.points), '65');
    });

    test('add increments stored balance when cache is ahead from creditBalance',
        () async {
      await repo.ensureInitialized();

      repo.creditBalance(10);
      expect(await repo.readBalance(), 60);

      await repo.add(10);

      expect(await repo.readBalance(), 60);
      expect(await storage.read(key: StorageKeys.points), '60');
    });

    test('persistCachedBalance writes storage without notifying listeners', () async {
      await repo.ensureInitialized();

      var notifyCount = 0;
      repo.addBalanceListener(() => notifyCount++);

      repo.creditBalance(10);
      expect(notifyCount, 1);

      await repo.persistCachedBalance();
      expect(notifyCount, 1);

      repo.clearBalanceCacheForTesting();
      expect(await repo.readBalance(), 60);
      expect(await storage.read(key: StorageKeys.points), '60');
    });

    test('writeBalance notifies listeners and updates cache', () async {
      await repo.ensureInitialized();

      var notifyCount = 0;
      repo.addBalanceListener(() => notifyCount++);

      await repo.writeBalance(75);
      expect(notifyCount, 1);
      expect(await repo.readBalance(), 75);
    });
  });
}
