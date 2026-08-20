import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/providers/achievement_catalog_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  test('achievement catalog reads initialized cache without recompute', () async {
    final container = await createTestContainer(
      storage: InMemoryKeyValueStorage(),
      bootstrap: true,
    );
    addTearDown(container.dispose);

    final service = container.read(achievementServiceProvider);
    expect(service.isInitialized, isTrue);

    service.updateProgressInvocationCount = 0;
    final catalog = container.read(achievementCatalogProvider);

    expect(catalog.inProgress, isNotEmpty);
    expect(service.updateProgressInvocationCount, 0);
  });

  test('scheduleDeferredStartupWork refreshes category progress only', () async {
    final container = await createTestContainer(
      storage: InMemoryKeyValueStorage(),
      bootstrap: false,
    );
    addTearDown(container.dispose);

    await lightTestBootstrap(container);
    await container.read(achievementServiceProvider).initialize();

    final service = container.read(achievementServiceProvider);
    service.updateProgressInvocationCount = 0;

    await scheduleDeferredStartupWork(
      container: container,
      initializeNotifications: false,
      warmAmbient: false,
    );

    // Six category tracking keys (100-105), not a full-catalog recompute.
    expect(service.updateProgressInvocationCount, 6);
    expect(service.isInitialized, isTrue);
  });
}
