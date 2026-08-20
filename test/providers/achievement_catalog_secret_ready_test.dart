import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/achievement_catalog_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

/// Expected product behavior: hidden achievements become visible when ready
/// to claim. Documents Bug Investigation dossier Bug B (Patient One).
void main() {
  test(
    'claim-ready secret achievements appear in catalog inProgress',
    () async {
      final container = await createTestContainer(
        storage: InMemoryKeyValueStorage(),
        bootstrap: true,
      );
      addTearDown(container.dispose);

      final service = container.read(achievementServiceProvider);
      final ready = await service.recordBreathBackgroundFullListen();
      expect(ready.map((a) => a.id), contains('130'));
      expect(service.getById('130')!.progress, 100);
      expect(service.getById('130')!.isCompleted, isFalse);

      container.read(achievementsListRefreshProvider.notifier).bump();
      final catalog = container.read(achievementCatalogProvider);

      expect(
        catalog.inProgress.any((a) => a.id == '130'),
        isTrue,
        reason:
            'Patient One (secret) at 100% progress must show in In-progress '
            'so it can be claimed; see .kodaelus/bugs/'
            'mini-game-achievements-and-patient-one-dossier.md',
      );
    },
  );
}
