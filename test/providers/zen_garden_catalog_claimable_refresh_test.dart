import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/providers/achievement_catalog_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'zen garden unlock bumps catalog so Sakura Gate is ready to claim',
    () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.points: '100'},
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);
      container.read(achievementTrackingWiringProvider);

      final achievements = container.read(achievementServiceProvider);
      await achievements.initialize();

      final before = container.read(achievementCatalogProvider);
      expect(
        before.inProgress.where((a) => a.id == '112').single.progress,
        0,
      );

      final session = container.read(zenGardenSessionProvider.notifier);
      await session.loadGarden();
      session.setGarden(
        const GardenState(
          pointsBalance: 20000,
          cherryBlossomTreeUnlocked: true,
        ),
      );

      var claimable = false;
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        final catalog = container.read(achievementCatalogProvider);
        final sakura = catalog.inProgress.where((a) => a.id == '112');
        if (sakura.isNotEmpty && sakura.single.progress >= 100) {
          claimable = true;
          break;
        }
      }

      expect(claimable, isTrue);
      final sakura = container
          .read(achievementCatalogProvider)
          .inProgress
          .where((a) => a.id == '112');
      expect(sakura, isNotEmpty);
      expect(sakura.single.progress, 100);
    },
  );
}
