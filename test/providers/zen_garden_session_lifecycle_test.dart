import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  group('ZenGardenSession lifecycle', () {
    test('hasLoadedFromDisk flips after loadGarden', () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.points: '100'},
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);

      final session = container.read(zenGardenSessionProvider.notifier);
      expect(session.hasLoadedFromDisk, isFalse);
      await session.loadGarden();
      expect(session.hasLoadedFromDisk, isTrue);
    });

    test('loadGarden skips state write after container disposed', () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.points: '100'},
      );
      final container = await createTestContainer(storage: storage);

      final session = container.read(zenGardenSessionProvider.notifier);
      final loadFuture = session.loadGarden();
      final gardenBeforeDispose = session.state.garden;
      container.dispose();
      await loadFuture;

      expect(session.hasLoadedFromDisk, isFalse);
      expect(session.state.garden, gardenBeforeDispose);
    });
  });
}
