import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/screens/zen_garden/bonsai_garden_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('bonsai hub shows 5x5 custom garden grid', (tester) async {
    final tree = CherryBlossomTreeState.initial().copyWith(
      stageIndex: 2,
      highestStageUnlocked: 2,
      bonsaiFilledSlots: {0: 5, 1: 10, 2: 3},
    ).normalized();
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.registrationComplete: 'true',
        StorageKeys.onboardingCompleted: 'true',
        StorageKeys.points: '0',
        StorageKeys.zenGardenSave: GardenPersistence.encodeZenGarden(
          GardenState(pointsBalance: 0, cherryBlossomTree: tree),
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
          home: BonsaiGardenScreen(
            primaryColor: Colors.black,
            secondaryColor: Colors.white,
            textStyle: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
  });

  test('grow increments bonsai and prestige grants 25th', () {
    var garden = const GardenState(pointsBalance: 1000000);
    var engine = CherryBlossomTreeEngine();
    for (var i = 0; i < CherryBlossomStageCatalog.levelsPerStage - 1; i++) {
      final r = engine.growOne(garden);
      expect(r.isSuccess, isTrue);
      garden = r.state!;
      engine = CherryBlossomTreeEngine(garden.cherryBlossomTree);
    }
    expect(garden.cherryBlossomTree.bonsaiCountForStage(0), 24);
    final prestiged = engine.prestige(garden).state!;
    expect(prestiged.cherryBlossomTree.bonsaiCountForStage(0), 25);
    expect(prestiged.cherryBlossomTree.stageIndex, 1);
  });
}
