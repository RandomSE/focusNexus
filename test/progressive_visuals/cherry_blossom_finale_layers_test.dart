import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_multiply_blend.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_peace_petals.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_power_petal_spec.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_power_petals.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_viewport.dart';

void main() {
  Future<void> pumpViewport(
    WidgetTester tester, {
    required CherryBlossomTreeState tree,
    bool animate = false,
  }) async {
    const size = Size(400, 600);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: CherryBlossomTreeViewport(
              tree: tree,
              size: size,
              animateEffects: animate,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'stages 0-5 use true-alpha (no multiply wrapper)',
    (tester) async {
      for (final stage in [0, 2, 3, 4, 5]) {
        final tree = CherryBlossomTreeState.initial()
            .copyWith(stageIndex: stage, growthStepsInStage: 10)
            .normalized();
        await pumpViewport(tester, tree: tree);
        expect(
          find.byType(CherryBlossomMultiplyBlend),
          findsNothing,
          reason: 'stage $stage',
        );
      }
    },
  );

  testWidgets('peace petals stack above full-bleed tree layer', (tester) async {
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          stageIndex: 7,
          prestigePath: CherryBlossomPrestigePath.peace,
        )
        .normalized();
    await pumpViewport(tester, tree: tree);

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(CherryBlossomTreeViewport),
        matching: find.byType(Stack),
      ),
    );
    final keys = stack.children.map((c) => c.key).toList();
    final treeIdx = keys.indexOf(CherryBlossomTreeViewport.treeLayerKey);
    final petalsIdx = keys.indexOf(CherryBlossomTreeViewport.finalePetalsKey);
    expect(treeIdx, greaterThanOrEqualTo(0));
    expect(petalsIdx, greaterThan(treeIdx));
    expect(find.byType(CherryBlossomPeacePetals), findsOneWidget);
  });

  testWidgets('power petals stack above full-bleed tree layer', (tester) async {
    final tree = CherryBlossomTreeState.initial()
        .copyWith(
          stageIndex: 7,
          prestigePath: CherryBlossomPrestigePath.power,
        )
        .normalized();
    await pumpViewport(tester, tree: tree);

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(CherryBlossomTreeViewport),
        matching: find.byType(Stack),
      ),
    );
    final keys = stack.children.map((c) => c.key).toList();
    final treeIdx = keys.indexOf(CherryBlossomTreeViewport.treeLayerKey);
    final petalsIdx = keys.indexOf(CherryBlossomTreeViewport.finalePetalsKey);
    expect(petalsIdx, greaterThan(treeIdx));
    expect(find.byType(CherryBlossomPowerPetals), findsOneWidget);
  });

  group('power petal spec', () {
    test('population and type weights', () {
      expect(CherryBlossomPowerPetalSpec.minConcurrent, 12);
      expect(CherryBlossomPowerPetalSpec.maxConcurrent, 18);
      expect(
        CherryBlossomPowerPetalSpec.crimsonWeight +
            CherryBlossomPowerPetalSpec.burntGoldWeight +
            CherryBlossomPowerPetalSpec.deepVioletWeight +
            CherryBlossomPowerPetalSpec.ashWeight,
        closeTo(1.0, 0.001),
      );
      // Luminous -> intensify -> ash arc before ground dissolve.
      expect(CherryBlossomPowerPetalSpec.luminousEndProgress, lessThan(0.3));
      expect(
        CherryBlossomPowerPetalSpec.ashFadeStartProgress,
        greaterThan(CherryBlossomPowerPetalSpec.intensifyEndProgress - 0.01),
      );
      expect(CherryBlossomPowerPetalSpec.crimsonSizeMinPx, 15);
      expect(CherryBlossomPowerPetalSpec.crimsonSizeMaxPx, 24);
      expect(CherryBlossomPowerPetalSpec.burntGoldSizeMinPx, 12);
      expect(CherryBlossomPowerPetalSpec.burntGoldSizeMaxPx, 19.5);
      expect(CherryBlossomPowerPetalSpec.deepVioletSizeMinPx, 12);
      expect(CherryBlossomPowerPetalSpec.deepVioletSizeMaxPx, 20);
      expect(CherryBlossomPowerPetalSpec.ashSizeMinPx, 9);
      expect(CherryBlossomPowerPetalSpec.ashSizeMaxPx, 15);
      expect(
        CherryBlossomPowerPetalSpec.crimsonCore,
        const Color(0xFFC41E3A),
      );
      expect(
        CherryBlossomPowerPetalSpec.goldCore,
        const Color(0xFFC9A227),
      );
      expect(
        CherryBlossomPowerPetalSpec.violetCore,
        const Color(0xFF6C3483),
      );
      expect(
        CherryBlossomPowerPetalSpec.ashEnd,
        const Color(0xFF1A1819),
      );
    });

    test('typeForRoll boundaries', () {
      expect(
        CherryBlossomPowerPetalSpec.typeForRoll(0.0),
        PowerPetalType.crimson,
      );
      expect(
        CherryBlossomPowerPetalSpec.typeForRoll(0.34),
        PowerPetalType.crimson,
      );
      expect(
        CherryBlossomPowerPetalSpec.typeForRoll(0.35),
        PowerPetalType.burntGold,
      );
      expect(
        CherryBlossomPowerPetalSpec.typeForRoll(0.59),
        PowerPetalType.burntGold,
      );
      expect(
        CherryBlossomPowerPetalSpec.typeForRoll(0.60),
        PowerPetalType.deepViolet,
      );
      expect(
        CherryBlossomPowerPetalSpec.typeForRoll(0.84),
        PowerPetalType.deepViolet,
      );
      expect(
        CherryBlossomPowerPetalSpec.typeForRoll(0.85),
        PowerPetalType.ash,
      );
    });

    test('alive effects cover finale', () {
      expect(CherryBlossomStageCatalog.usesAliveEffects(7), isTrue);
    });

    test('authority spawn rhythm and drift caps', () {
      expect(CherryBlossomPowerPetalSpec.silenceMinSec, 2.5);
      expect(CherryBlossomPowerPetalSpec.silenceMaxSec, 5.5);
      expect(CherryBlossomPowerPetalSpec.burstSizeMin, 2);
      expect(CherryBlossomPowerPetalSpec.burstSizeMax, 4);
      expect(CherryBlossomPowerPetalSpec.driftAmplitudeFactor, 0.015);
      expect(CherryBlossomPowerPetalSpec.slowFallChance, 0.60);
      expect(CherryBlossomPowerPetalSpec.fixedAngleChance, 0.65);
    });

    test('rising deep-violet cadence', () {
      expect(CherryBlossomPowerPetalSpec.risingPetalMinSec, 50);
      expect(CherryBlossomPowerPetalSpec.risingPetalMaxSec, 80);
      expect(CherryBlossomPowerPetalSpec.risingSpeedFactor, 0.4);
    });

    test('sharp teardrop path is not an oval', () {
      final path = powerPetalPath(const Offset(100, 100), 12);
      final bounds = path.getBounds();
      // Taller than wide (pointed teardrop), not a soft oval blob.
      expect(bounds.height, greaterThan(bounds.width * 0.9));
    });
  });
}
