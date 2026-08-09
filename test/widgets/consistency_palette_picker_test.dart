import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:focusNexus/widgets/consistency_palette_picker.dart';
import 'package:focusNexus/widgets/section_title_actions.dart';

void main() {
  testWidgets('Colour palette title does not share a Row with Preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const style = TextStyle(fontSize: 24, color: Colors.teal);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsistencyPalettePicker(
            selected: ConsistencyPaletteId.coolTealDepth,
            textStyle: style,
            primaryColor: Colors.teal,
            secondaryColor: Colors.white,
            onSelected: (_) {},
            previewEnabled: false,
            onPreviewToggled: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SectionTitleActions), findsOneWidget);
    expect(
      find.ancestor(of: find.text('Colour palette'), matching: find.byType(Row)),
      findsNothing,
    );
    final size = tester.getSize(find.text('Colour palette'));
    expect(size.height, lessThan(72));
    expect(size.width, greaterThan(80));
    expect(tester.takeException(), isNull);
  });
}
