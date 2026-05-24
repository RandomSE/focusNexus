import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('GardenRepository', () {
    late InMemoryKeyValueStorage storage;
    late PointsRepository points;
    late GardenRepository repo;

    setUp(() {
      storage = InMemoryKeyValueStorage(initial: {StorageKeys.points: '120'});
      points = PointsRepository(storage);
      repo = GardenRepository(storage, points: points);
    });

    test('load uses wallet balance for empty save', () async {
      final state = await repo.load();
      expect(state.pointsBalance, 120);
      expect(state.items, isEmpty);
    });

    test('save persists garden blob and wallet', () async {
      final state = GardenPersistence.decodeZenGarden(null, 120);
      await repo.save(state);
      expect(await storage.read(key: StorageKeys.points), '120');
      expect(await storage.read(key: StorageKeys.zenGardenSave), isNotNull);
    });
  });
}
