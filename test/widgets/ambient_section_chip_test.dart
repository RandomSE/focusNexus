import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/widgets/ambient_section_chip.dart';

void main() {
  testWidgets('selected chip uses contrasting label color', (tester) async {
    const primary = Color(0xFF111111);
    const secondary = Color(0xFFF5F5F5);
    const style = TextStyle(color: primary, fontSize: 18);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmbientSectionChip(
            label: AmbientAppSection.progressiveVisuals.label,
            selected: true,
            textStyle: style,
            primary: primary,
            secondary: secondary,
            onTap: () {},
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.text(AmbientAppSection.progressiveVisuals.label),
    );
    expect(text.style?.color, secondary);
    expect(text.softWrap, isTrue);

    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.selectedColor, primary);
    expect(chip.backgroundColor, secondary);
  });

  testWidgets('Progressive visuals label soft-wraps at large font', (tester) async {
    const primary = Color(0xFF004F52);
    const secondary = Color(0xFFF2EFE6);
    final style = const TextStyle(color: primary, fontSize: 28);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: AmbientSectionChip(
              label: AmbientAppSection.progressiveVisuals.label,
              selected: false,
              textStyle: style,
              primary: primary,
              secondary: secondary,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(AmbientAppSection.progressiveVisuals.label),
      findsOneWidget,
    );
    final text = tester.widget<Text>(
      find.text(AmbientAppSection.progressiveVisuals.label),
    );
    expect(text.softWrap, isTrue);
    expect(text.data, 'Progressive visuals');
  });
}
