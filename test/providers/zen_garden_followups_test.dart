import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  test('legacy unlock backfills toast-shown without re-toasting', () {
    const json = '{"cherryBlossomTreeUnlocked":true}';
    final state = GardenPersistence.decodeZenGarden(json, 0);
    expect(state.cherryBlossomUnlockToastShown, isTrue);
  });

  test('suppressRestartGrowthPrompt roundtrips', () {
    const original = GardenState(
      pointsBalance: 1,
      suppressRestartGrowthPrompt: true,
    );
    final json = GardenPersistence.encodeZenGarden(original);
    final restored = GardenPersistence.decodeZenGarden(json, 1);
    expect(restored.suppressRestartGrowthPrompt, isTrue);
  });

  test('setSuppressRestartGrowthPrompt persists through session', () async {
    final storage = InMemoryKeyValueStorage();
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final session = container.read(zenGardenSessionProvider.notifier);
    await session.loadGarden();
    session.setSuppressRestartGrowthPrompt(true);
    await session.persist();

    final reloaded = await createTestContainer(storage: storage);
    await lightTestBootstrap(reloaded);
    await reloaded.read(zenGardenSessionProvider.notifier).loadGarden();
    expect(
      reloaded.read(zenGardenSessionProvider).garden.suppressRestartGrowthPrompt,
      isTrue,
    );
    reloaded.dispose();
  });

  test('first unlock sets pending toast flag once', () async {
    final container = await createTestContainer();
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    final session = container.read(zenGardenSessionProvider.notifier);
    await session.loadGarden();
    session.setGarden(
      const GardenState(pointsBalance: 15000, cherryBlossomTreeUnlocked: true),
    );

    expect(
      container.read(zenGardenSessionProvider).pendingCherryBlossomUnlockToast,
      isTrue,
    );
    expect(
      container.read(zenGardenSessionProvider).garden.cherryBlossomUnlockToastShown,
      isTrue,
    );
  });
}
