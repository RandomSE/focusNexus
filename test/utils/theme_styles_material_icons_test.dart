import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/theme_styles.dart';

void main() {
  testWidgets('icons render with MaterialIcons font family', (tester) async {
    final theme = ThemeStyles.buildThemeData(
      isDark: false,
      primaryColor: Colors.black,
      secondaryColor: Colors.white,
      accentColor: Colors.blue,
      fontSize: 14,
      useDyslexiaFont: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Icons')),
          body: const Icon(Icons.arrow_back),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(Icon),
        matching: find.byType(RichText),
      ),
    );
    final span = richText.text as TextSpan;
    expect(span.style?.fontFamily, 'MaterialIcons');
  });
}
