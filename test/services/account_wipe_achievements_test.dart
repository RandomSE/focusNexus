import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/achievement_catalog_provider.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'account wipe resets cherry achievements and refreshes catalog',
    () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.points: '20000'},
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);
      container.read(achievementTrackingWiringProvider);

      final achievements = container.read(achievementServiceProvider);
      await achievements.initialize();

      await achievements.completeAchievement('112');
      await storage.write(
        key: StorageKeys.cherryBlossomTreeUnlockedFlag,
        value: '1',
      );
      await storage.write(
        key: StorageKeys.cherryBlossomStage0CompleteFlag,
        value: '1',
      );
      await achievements.updateProgress('141');
      container.read(achievementsListRefreshProvider.notifier).bump();
      expect(achievements.getById('112')!.isCompleted, isTrue);
      expect(achievements.getById('141')!.progress, 100);

      final beforeCatalog = container.read(achievementCatalogProvider);
      expect(beforeCatalog.completed.any((a) => a.id == '112'), isTrue);

      final session = container.read(zenGardenSessionProvider.notifier);
      await session.loadGarden();
      expect(session.hasLoadedFromDisk, isTrue);

      session.resetForAccountWipe();
      expect(session.hasLoadedFromDisk, isFalse);
      expect(session.state.garden.cherryBlossomTreeUnlocked, isFalse);

      await container.read(appRepositoriesProvider).wipeAllUserData();
      await achievements.clearAll();
      await achievements.initialize();
      container.read(achievementsListRefreshProvider.notifier).bump();

      expect(achievements.getById('112')!.isCompleted, isFalse);
      expect(achievements.getById('112')!.progress, 0);
      expect(achievements.getById('141')!.progress, 0);
      expect(
        await storage.read(key: StorageKeys.cherryBlossomTreeUnlockedFlag),
        anyOf(isNull, '0'),
      );

      final afterCatalog = container.read(achievementCatalogProvider);
      expect(afterCatalog.completed, isEmpty);
      expect(afterCatalog.inProgress.any((a) => a.id == '112'), isTrue);
      expect(
        afterCatalog.inProgress.where((a) => a.id == '112').single.progress,
        0,
      );
      expect(
        afterCatalog.inProgress.any((a) => !a.isCompleted && a.progress >= 100),
        isFalse,
      );
    },
  );

  test('resetForAccountWipe clears loaded flag so dispose cannot re-save', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '20000'},
    );
    final container = await createTestContainer(storage: storage);
    final session = container.read(zenGardenSessionProvider.notifier);
    await session.loadGarden();
    expect(session.hasLoadedFromDisk, isTrue);

    session.resetForAccountWipe();
    expect(session.hasLoadedFromDisk, isFalse);
    await container.read(appRepositoriesProvider).wipeAllUserData();
    container.dispose();

    expect(storage.snapshot.containsKey(StorageKeys.zenGardenSave), isFalse);
  });
}
