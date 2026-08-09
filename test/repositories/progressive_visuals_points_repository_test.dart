import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/progressive_visuals_points_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('ProgressiveVisualsPointsRepository', () {
    late InMemoryKeyValueStorage storage;
    late ProgressiveVisualsPointsRepository repo;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      repo = ProgressiveVisualsPointsRepository(storage);
    });

    test('maxBalance raised to 1,000,000 for the PV-earn rebalance', () {
      expect(ProgressiveVisualsPointsRepository.maxBalance, 1000000);
    });

    test('credit clamps at 1,000,000 (no lifetime-earned cap, balance only)',
        () async {
      await repo.writeBalance(999900);

      final next = await repo.credit(500);

      expect(next, 1000000);
      expect(await repo.readBalance(), 1000000);
      expect(
        await storage.read(key: StorageKeys.progressiveVisualsPoints),
        '1000000',
      );
    });

    test('credit below the ceiling adds the full amount', () async {
      await repo.writeBalance(1000);

      final next = await repo.credit(2500);

      expect(next, 3500);
    });

    test('credit never drops below minBalance (0) for a zero-amount credit',
        () async {
      final next = await repo.credit(0);

      expect(next, 0);
      expect(next, greaterThanOrEqualTo(ProgressiveVisualsPointsRepository.minBalance));
    });

    test('credit rejects negative amounts', () async {
      expect(() => repo.credit(-1), throwsArgumentError);
    });

    test('writeBalance also clamps to the new ceiling', () async {
      await repo.writeBalance(5000000);

      expect(await repo.readBalance(), 1000000);
    });
  });
}
