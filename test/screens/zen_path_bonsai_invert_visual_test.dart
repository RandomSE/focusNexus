import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_decor_visual.dart';

void main() {
  testWidgets('path bonsai applies ColorFiltered invert when mutation enabled',
      (tester) async {
    const item = DecorItem(
      id: 'peace_vis',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
      mutation: MutationKind.invertedColors,
      mutationUnlocked: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ZenDecorVisual(
              item: item,
              selected: false,
              primary: Colors.teal,
              secondary: Colors.white,
              reduceMotion: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ColorFiltered), findsOneWidget);
  });

  testWidgets('path bonsai omits ColorFiltered when mutation disabled',
      (tester) async {
    const item = DecorItem(
      id: 'peace_off',
      themeId: VisualThemeId.zenGarden,
      kind: zenPeaceBonsaiKind,
      stageIndex: DecorItem.maxStageIndex,
      mutationUnlocked: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ZenDecorVisual(
              item: item,
              selected: false,
              primary: Colors.teal,
              secondary: Colors.white,
              reduceMotion: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ColorFiltered), findsNothing);
  });
}
