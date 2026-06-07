import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/app_services_provider.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(AchievementTrackingVariables.resetTestInstance);

  test('scheduleDeferredStartupWork completes without throwing', () async {
    AchievementTrackingVariables.useTestInstance(
      AchievementTrackingVariables.test(InMemoryKeyValueStorage()),
    );
    final container = await createTestContainer(bootstrap: false);
    await lightTestBootstrap(container);
    await container.read(achievementServiceProvider).initialize();

    await expectLater(
      scheduleDeferredStartupWork(
        container: container,
        initializeNotifications: false,
      ),
      completes,
    );
  });
}
