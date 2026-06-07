import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/main.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart'; // goalNotifierWiringProvider
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/key_value_storage_provider.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import 'in_memory_key_value_storage.dart';

/// In-memory overrides for widget tests (no bootstrap).
Widget testProviderScope({
  required Widget child,
  KeyValueStorage? storage,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      keyValueStorageProvider.overrideWithValue(
        storage ?? InMemoryKeyValueStorage(),
      ),
      ...overrides,
    ],
    child: child,
  );
}

/// Container for unit tests and smoke tests that need [ref.read].
Future<ProviderContainer> createTestContainer({
  KeyValueStorage? storage,
  List<Override> overrides = const [],
  bool bootstrap = false,
  bool initializeNotifications = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      keyValueStorageProvider.overrideWithValue(
        storage ?? InMemoryKeyValueStorage(),
      ),
      ...overrides,
    ],
  );
  if (bootstrap) {
    await ensureAppReady(container);
    if (initializeNotifications) {
      scheduleDeferredStartupWork(
        container: container,
        initializeNotifications: true,
      );
    }
  }
  return container;
}

/// Settings + points only (no notification plugin init).
Future<void> lightTestBootstrap(ProviderContainer container) async {
  container.read(goalNotifierWiringProvider);
  await container.read(appSettingsProvider.notifier).load();
  await container.read(appRepositoriesProvider).points.ensureInitialized();
}

Widget testUncontrolledScope({
  required ProviderContainer container,
  required Widget child,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: child,
  );
}

/// Bounded [pumpAndSettle] so notification timers cannot hang tests.
Future<void> pumpSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  await tester.pumpAndSettle(
    timeout,
    EnginePhase.sendSemanticsUpdate,
    const Duration(milliseconds: 100),
  );
}

/// Prefer over [pumpSettleWithTimeout] when [DeferredScreen] or skeletons are active.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 80,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

/// Storage with onboarding complete so [AppRoutes.initialFor] resolves to dashboard.
InMemoryKeyValueStorage onboardedTestStorage() {
  return InMemoryKeyValueStorage(
    initial: {
      StorageKeys.registrationComplete: 'true',
      StorageKeys.onboardingCompleted: 'true',
      StorageKeys.theme: 'light',
      StorageKeys.rewardType: 'Mini-games',
    },
  );
}

/// Storage for registration flow (registered, not onboarded).
InMemoryKeyValueStorage registrationTestStorage() {
  return InMemoryKeyValueStorage(
    initial: {
      StorageKeys.registrationComplete: 'true',
      StorageKeys.onboardingCompleted: 'false',
    },
  );
}

/// Pumps [FocusNexusApp] with test storage and optional light bootstrap.
Future<ProviderContainer> pumpFocusNexusApp(
  WidgetTester tester, {
  required String initialRoute,
  KeyValueStorage? storage,
  bool bootstrap = false,
  bool lightBootstrap = true,
  bool initializeNotifications = false,
  List<Override> overrides = const [],
}) async {
  final container = await createTestContainer(
    storage: storage ?? InMemoryKeyValueStorage(),
    overrides: overrides,
    bootstrap: bootstrap,
    initializeNotifications: initializeNotifications,
  );
  if (lightBootstrap && !bootstrap) {
    await lightTestBootstrap(container);
  }
  addTearDown(container.dispose);

  await tester.pumpWidget(
    testUncontrolledScope(
      container: container,
      child: FocusNexusApp(initialRoute: initialRoute),
    ),
  );
  return container;
}
