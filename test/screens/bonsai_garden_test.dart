import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_falling_petals.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_multiply_blend.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_peace_petals.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_power_petals.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_six_leaves.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_background.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/screens/zen_garden/bonsai_garden_screen.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
  });

  Future<ProviderContainer> pumpGarden(
    WidgetTester tester, {
    required CherryBlossomTreeState tree,
  }) async {
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  testWidgets('bonsai hub shows 5x5 custom garden grid', (tester) async {
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          stageIndex: 2,
          highestStageUnlocked: 2,
          bonsaiFilledSlots: {0: 5, 1: 10, 2: 3},
        )
        .normalized();
    await pumpGarden(tester, tree: tree);

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Bonsai garden'), findsOneWidget);
  });

  testWidgets('bonsai garden fills body and has back control', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final tree = CherryBlossomTreeState.initial().normalized();
    await pumpGarden(tester, tree: tree);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 5);
    expect(delegate.crossAxisSpacing, greaterThanOrEqualTo(6));
    // Full-bleed cells are not forced to 1:1 when the body is tall.
    expect(delegate.childAspectRatio, isNot(1.0));

    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('planted pots omit quantity badges and mount stage scenery', (
    tester,
  ) async {
    final slots = List<String?>.filled(25, null);
    slots[0] = 'stage_2';
    slots[1] = 'stage_4';
    slots[2] = 'stage_6';
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          stageIndex: 6,
          highestStageUnlocked: 6,
          bonsaiFilledSlots: {2: 25, 4: 5, 6: 10},
          customBonsaiGardenSlots: slots,
        )
        .normalized();
    await pumpGarden(tester, tree: tree);

    expect(find.textContaining('×'), findsNothing);
    expect(find.byType(CherryBlossomTreeBackground), findsWidgets);
    // Stages 0-5 are true-alpha; no multiply wash in pots.
    expect(find.byType(CherryBlossomMultiplyBlend), findsNothing);
    expect(find.byType(CherryBlossomFallingPetals), findsWidgets);
    expect(find.byType(CherryBlossomStageSixLeaves), findsOneWidget);
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

  test('falling petal colors differ by stage', () {
    expect(
      CherryBlossomFallingPetals.colorForStage(1),
      isNot(CherryBlossomFallingPetals.colorForStage(4)),
    );
    expect(
      CherryBlossomFallingPetals.colorForStage(3),
      isNot(CherryBlossomFallingPetals.colorForStage(5)),
    );
  });

  test('stage six bonsai pot concurrent is capped', () {
    expect(CherryBlossomStageSixLeaves.bonsaiPotConcurrent, inInclusiveRange(2, 4));
    expect(
      CherryBlossomStageSixLeaves.targetConcurrentCount(
        25,
        maxConcurrent: CherryBlossomStageSixLeaves.bonsaiPotConcurrent,
      ),
      CherryBlossomStageSixLeaves.bonsaiPotConcurrent,
    );
  });

  test('bonsai tree bottom offset seats stages 0-5 on ground', () {
    const cellH = 100.0;
    for (var stage = 0; stage <= 5; stage++) {
      final drawH =
          cellH * CherryBlossomStageCatalog.bonsaiTreeHeightFraction(stage);
      final pad = CherryBlossomStageCatalog.contentBottomPaddingFraction(stage);
      final bias = CherryBlossomStageCatalog.seatingBiasFraction(stage);
      final offset = CherryBlossomStageCatalog.bonsaiTreeBottomOffset(
        stageIndex: stage,
        cellHeight: cellH,
        drawHeight: drawH,
      );
      final baseline = offset + pad * drawH;
      final groundTop = cellH * CherryBlossomStageCatalog.groundInsetFraction;
      expect(
        baseline,
        closeTo(groundTop - cellH * bias, 0.5),
        reason: 'stage $stage baseline should sit on pot ground',
      );
    }
    expect(
      CherryBlossomStageCatalog.bonsaiTreeBottomOffset(
        stageIndex: 6,
        cellHeight: cellH,
        drawHeight: cellH,
      ),
      0.0,
    );
  });

  testWidgets('finale pots mount prominent peace and power petals', (
    tester,
  ) async {
    final slots = List<String?>.filled(25, null);
    slots[0] = 'stage_7_peace';
    slots[1] = 'stage_7_power';
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          stageIndex: 7,
          highestStageUnlocked: 7,
          peaceBonsaiCount: 1,
          powerBonsaiCount: 1,
          customBonsaiGardenSlots: slots,
        )
        .normalized();
    await pumpGarden(tester, tree: tree);

    expect(find.byType(CherryBlossomPeacePetals), findsOneWidget);
    expect(find.byType(CherryBlossomPowerPetals), findsOneWidget);

    final peace = tester.widget<CherryBlossomPeacePetals>(
      find.byType(CherryBlossomPeacePetals),
    );
    final power = tester.widget<CherryBlossomPowerPetals>(
      find.byType(CherryBlossomPowerPetals),
    );
    expect(peace.sizeMul, CherryBlossomPeacePetals.bonsaiSizeMul);
    expect(power.sizeMul, CherryBlossomPowerPetals.bonsaiSizeMul);
    expect(peace.litePaint, isTrue);
    expect(power.litePaint, isTrue);
    expect(
      CherryBlossomPeacePetals.bonsaiMaxSizeScale /
          CherryBlossomPeacePetals.bonsaiMinSizeScale,
      closeTo(CherryBlossomPeacePetals.bonsaiMaxOverMin, 0.001),
    );
    expect(CherryBlossomPeacePetals.bonsaiMaxOverMin, 2.0);
    expect(
      CherryBlossomPeacePetals.bonsaiMinSizeScale /
          CherryBlossomPowerPetals.bonsaiMinSizeScale,
      closeTo(2.0, 0.001),
    );
    expect(
      CherryBlossomPeacePetals.bonsaiSizeScaleForRoll(0),
      CherryBlossomPeacePetals.bonsaiMinSizeScale,
    );
    expect(
      CherryBlossomPeacePetals.bonsaiSizeScaleForRoll(1),
      CherryBlossomPeacePetals.bonsaiMaxSizeScale,
    );
    expect(
      CherryBlossomPowerPetals.bonsaiMaxSizeScale /
          CherryBlossomPowerPetals.bonsaiMinSizeScale,
      closeTo(CherryBlossomPowerPetals.bonsaiMaxOverMin, 0.001),
    );
    expect(CherryBlossomPowerPetals.bonsaiMaxOverMin, 2.0);
    expect(CherryBlossomPeacePetals.bonsaiMaxConcurrent, lessThanOrEqualTo(12));
    expect(CherryBlossomPowerPetals.bonsaiMaxConcurrent, lessThanOrEqualTo(10));
    expect(CherryBlossomStageSixLeaves.bonsaiSizeScale, 0.5);
  });

  testWidgets('stage six leaves keep animating beside finale pots', (
    tester,
  ) async {
    final slots = List<String?>.filled(25, null);
    slots[0] = 'stage_6';
    slots[1] = 'stage_7_peace';
    slots[2] = 'stage_7_power';
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          stageIndex: 7,
          highestStageUnlocked: 7,
          bonsaiFilledSlots: {6: 5},
          peaceBonsaiCount: 1,
          powerBonsaiCount: 1,
          customBonsaiGardenSlots: slots,
        )
        .normalized();
    await pumpGarden(tester, tree: tree);

    expect(find.byType(CherryBlossomStageSixLeaves), findsOneWidget);
    expect(find.byType(CherryBlossomPeacePetals), findsOneWidget);
    expect(find.byType(CherryBlossomPowerPetals), findsOneWidget);

    // After time passes, stage-six spawn path must still run (not frozen by jank skip).
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(CherryBlossomStageSixLeaves), findsOneWidget);
  });
}
