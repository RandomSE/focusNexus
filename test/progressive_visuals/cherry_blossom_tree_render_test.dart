import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
