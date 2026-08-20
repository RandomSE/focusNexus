import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AchievementTrackingVariables.resetForTesting();
    GoalNotifier.resetForTesting();
    clearBootstrapTimingsForTesting();
  });

  test('ensureAppReady loads gate prefs without initializing achievements',
      () async {
    final container = await createTestContainer(
      storage: InMemoryKeyValueStorage(),
      bootstrap: false,
    );

    await ensureAppReady(container);

    expect(container.read(appSettingsProvider).isLoaded, isTrue);
    expect(
      container.read(achievementServiceProvider).isInitialized,
      isFalse,
    );
    expect(lastBootstrapTimings, isNotNull);
    expect(lastBootstrapTimings!.phases.containsKey('gate'), isTrue);
  });

  test('scheduleDeferredStartupWork initializes achievements after gate',
      () async {
    final container = await createTestContainer(
      storage: InMemoryKeyValueStorage(),
      bootstrap: false,
    );
    await ensureAppReady(container);

    await scheduleDeferredStartupWork(
      container: container,
      initializeNotifications: false,
    );

    expect(
      container.read(achievementServiceProvider).isInitialized,
      isTrue,
    );
    expect(lastBootstrapTimings!.phases.containsKey('deferred'), isTrue);
  });

  test('scheduleDeferredStartupWork completes without throwing', () async {
    final container = await createTestContainer(
      storage: InMemoryKeyValueStorage(),
      bootstrap: false,
    );
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
