import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/screens/zen_garden/cherry_blossom_tree_screen.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

Future<void> _openTreeMenu(WidgetTester tester) async {
  await pumpUntilFound(tester, find.text('Menu'));
  await tester.tap(find.text('Menu'));
  await tester.pump();
}

void main() {
  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
  });

  testWidgets('grow tree disables when balance insufficient', (tester) async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.registrationComplete: 'true',
        StorageKeys.onboardingCompleted: 'true',
        StorageKeys.points: '0',
        StorageKeys.zenGardenSave: GardenPersistence.encodeZenGarden(
          const GardenState(pointsBalance: 0),
        ),
      },
    );
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    await container.read(zenGardenSessionProvider.notifier).loadGarden();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: CherryBlossomTreeScreen(
            primaryColor: Colors.black,
            secondaryColor: Colors.white,
            textStyle: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
    await _openTreeMenu(tester);
    await pumpUntilFound(tester, find.textContaining('Grow tree'));

    final grow = find.ancestor(
      of: find.textContaining('Grow tree'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(grow).onPressed, isNull);
  });

  testWidgets('max tree enabled when balance can afford multiple grows', (
    tester,
  ) async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.registrationComplete: 'true',
        StorageKeys.onboardingCompleted: 'true',
        StorageKeys.points: '5000',
      },
    );
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    await container.read(zenGardenSessionProvider.notifier).loadGarden();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: CherryBlossomTreeScreen(
            primaryColor: Colors.black,
            secondaryColor: Colors.white,
            textStyle: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
    await _openTreeMenu(tester);
    await pumpUntilFound(tester, find.textContaining('Max tree'));

    final maxTree = find.ancestor(
      of: find.textContaining('Max tree'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(maxTree).onPressed, isNotNull);
  });

  testWidgets('grow controls appear in menu overlay when Menu is open', (
    tester,
  ) async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.registrationComplete: 'true',
        StorageKeys.onboardingCompleted: 'true',
        StorageKeys.points: '5000',
      },
    );
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    await container.read(zenGardenSessionProvider.notifier).loadGarden();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: CherryBlossomTreeScreen(
            primaryColor: Colors.black,
            secondaryColor: Colors.white,
            textStyle: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Menu'));
    expect(find.textContaining('Grow tree'), findsNothing);

    await _openTreeMenu(tester);
    await pumpUntilFound(tester, find.textContaining('Grow tree'));
    expect(find.textContaining('Grow tree'), findsOneWidget);
  });

  testWidgets('prestige button at max stage level', (tester) async {
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          growthStepsInStage: CherryBlossomStageCatalog.levelsPerStage - 1,
        )
        .normalized();
    final prestigeCost = CherryBlossomTreeEngine(tree).prestigeCost()!;
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.registrationComplete: 'true',
        StorageKeys.onboardingCompleted: 'true',
        StorageKeys.points: '$prestigeCost',
        StorageKeys.zenGardenSave: GardenPersistence.encodeZenGarden(
          GardenState(pointsBalance: prestigeCost, cherryBlossomTree: tree),
        ),
      },
    );
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    await container.read(zenGardenSessionProvider.notifier).loadGarden();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: CherryBlossomTreeScreen(
            primaryColor: Colors.black,
            secondaryColor: Colors.white,
            textStyle: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
    await _openTreeMenu(tester);
    await pumpUntilFound(tester, find.textContaining('Prestige tree'));
    expect(find.textContaining('Grow tree'), findsNothing);
  });

  testWidgets('stage 6 prestige shows Power Peace dialog', (tester) async {
    final tree = CherryBlossomTreeEngine.maxedStageSix();
    final prestigeCost = CherryBlossomTreeEngine(tree).prestigeCost()!;
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.registrationComplete: 'true',
        StorageKeys.onboardingCompleted: 'true',
        StorageKeys.points: '$prestigeCost',
        StorageKeys.zenGardenSave: GardenPersistence.encodeZenGarden(
          GardenState(pointsBalance: prestigeCost, cherryBlossomTree: tree),
        ),
      },
    );
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    await container.read(zenGardenSessionProvider.notifier).loadGarden();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: CherryBlossomTreeScreen(
            primaryColor: Colors.black,
            secondaryColor: Colors.white,
            textStyle: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
    await _openTreeMenu(tester);
    await pumpUntilFound(tester, find.textContaining('Prestige tree'));
    await tester.tap(find.textContaining('Prestige tree'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Peace'), findsWidgets);
    expect(find.text('Power'), findsOneWidget);
  });

  testWidgets(
    'Max tree re-enables as soon as next stage commits after prestige',
    (tester) async {
      final tree = CherryBlossomTreeState.initial()
          .copyWith(
            growthStepsInStage: CherryBlossomStageCatalog.levelsPerStage - 1,
          )
          .normalized();
      final prestigeCost = CherryBlossomTreeEngine(tree).prestigeCost()!;
      final storage = InMemoryKeyValueStorage(
        initial: {
          StorageKeys.registrationComplete: 'true',
          StorageKeys.onboardingCompleted: 'true',
          // Prestige + room to Max on the next stage.
          StorageKeys.points: '${prestigeCost + 5000}',
          StorageKeys.zenGardenSave: GardenPersistence.encodeZenGarden(
            GardenState(
              pointsBalance: prestigeCost + 5000,
              cherryBlossomTree: tree,
            ),
          ),
        },
      );
      final container = await createTestContainer(storage: storage);
      await lightTestBootstrap(container);
      await container.read(zenGardenSessionProvider.notifier).loadGarden();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        testUncontrolledScope(
          container: container,
          child: const MaterialApp(
            home: CherryBlossomTreeScreen(
              primaryColor: Colors.black,
              secondaryColor: Colors.white,
              textStyle: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );
      await _openTreeMenu(tester);
      await pumpUntilFound(tester, find.textContaining('Prestige tree'));
      await tester.tap(find.textContaining('Prestige tree'));
      // Advance only a slice of the prestige transition (not full settle).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Max tree'), findsOneWidget);
      final maxTree = find.ancestor(
        of: find.textContaining('Max tree'),
        matching: find.byType(ElevatedButton),
      );
      expect(tester.widget<ElevatedButton>(maxTree).onPressed, isNotNull);
    },
  );
}
