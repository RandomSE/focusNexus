import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  group('ZenGardenSession persistence', () {
    test('persist does not write before loadGarden completes', () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.points: '100'},
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);

      final session = container.read(zenGardenSessionProvider.notifier);
      await session.persist(
        snapshot: GardenState(
          pointsBalance: 100,
          items: [
            GardenItem(
              id: 'early',
              themeId: VisualThemeId.zenGarden,
            ),
          ],
        ),
      );

      expect(storage.snapshot[StorageKeys.zenGardenSave], isNull);
    });

    test('persist after loadGarden round-trips placed items', () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.points: '100'},
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);

      final session = container.read(zenGardenSessionProvider.notifier);
      await session.loadGarden();

      final withPlant = GardenState(
        pointsBalance: 100,
        items: [
          GardenItem(
            id: 'plant-1',
            themeId: VisualThemeId.zenGarden,
            stageIndex: 2,
            positionX: 0.3,
            positionY: 0.7,
          ),
        ],
        decorInventory: const [],
        plantInventory: const [],
      );
      session.setGarden(withPlant);
      await session.persist(snapshot: withPlant);

      final reloaded = await container.read(appRepositoriesProvider).garden.load();
      expect(reloaded.items.length, 1);
      expect(reloaded.items.single.id, 'plant-1');
      expect(reloaded.items.single.stageIndex, 2);
    });

    test('ordered persist snapshots keep the latest layout', () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.points: '100'},
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);

      final session = container.read(zenGardenSessionProvider.notifier);
      await session.loadGarden();

      final first = GardenState(
        pointsBalance: 100,
        items: [
          GardenItem(id: 'old', themeId: VisualThemeId.zenGarden),
        ],
      );
      final second = GardenState(
        pointsBalance: 100,
        items: [
          GardenItem(id: 'old', themeId: VisualThemeId.zenGarden),
          GardenItem(id: 'new', themeId: VisualThemeId.zenGarden),
        ],
      );

      final slowFirst = session.persist(snapshot: first).then((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      final fastSecond = session.persist(snapshot: second);

      await Future.wait([slowFirst, fastSecond]);

      final reloaded = await container.read(appRepositoriesProvider).garden.load();
      expect(reloaded.items.map((e) => e.id), ['old', 'new']);
    });
  });
}
