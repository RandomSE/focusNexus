import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_multiply_blend.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_peace_petals.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_viewport.dart';

void main() {
  testWidgets('viewport renders stage 0 with background', (tester) async {
    const size = Size(400, 600);
    const tree = CherryBlossomTreeState();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: CherryBlossomTreeViewport(
              tree: tree,
              size: size,
              animateEffects: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CherryBlossomTreeViewport), findsOneWidget);
  });

  testWidgets('viewport renders stage 6 with alive effects', (tester) async {
    const size = Size(400, 600);
    final tree = CherryBlossomTreeState.initial().copyWith(
      stageIndex: 6,
      growthStepsInStage: 10,
    ).normalized();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: CherryBlossomTreeViewport(
              tree: tree,
              size: size,
              animateEffects: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(CherryBlossomStageCatalog.usesAliveEffects(6), isTrue);
  });

  testWidgets('non-full-bleed growth uses Transform.scale from baseline',
      (tester) async {
    const size = Size(400, 600);
    final tree = CherryBlossomTreeState.initial().copyWith(
      stageIndex: 2,
      growthStepsInStage: 5,
    ).normalized();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: CherryBlossomTreeViewport(
              tree: tree,
              size: size,
              animateEffects: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Transform), findsWidgets);
  });

  testWidgets('peace finale mounts luminous petals', (tester) async {
    const size = Size(400, 600);
    final tree = CherryBlossomTreeState.initial().copyWith(
      stageIndex: 7,
      growthStepsInStage: 0,
      prestigePath: CherryBlossomPrestigePath.peace,
    ).normalized();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: CherryBlossomTreeViewport(
              tree: tree,
              size: size,
              animateEffects: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CherryBlossomPeacePetals), findsOneWidget);
  });

  testWidgets('stage 0 true-alpha has no multiply wrapper', (tester) async {
    const size = Size(400, 600);
    const tree = CherryBlossomTreeState();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: CherryBlossomTreeViewport(
              tree: tree,
              size: size,
              animateEffects: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CherryBlossomMultiplyBlend), findsNothing);
  });
}
