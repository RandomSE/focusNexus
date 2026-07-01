import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/widgets/assistant_quick_replies.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/theme_styles.dart';

ThemeBundle _bundle({double fontSize = 24, bool dyslexia = true}) {
  const primary = Colors.black87;
  const secondary = Colors.white;
  const accent = Colors.teal;
  final textStyle = ThemeStyles.buildTextStyle(
    primaryColor: primary,
    fontSize: fontSize,
    useDyslexiaFont: dyslexia,
  );
  return ThemeBundle(
    themeData: ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: secondary,
    ),
    primaryColor: primary,
    secondaryColor: secondary,
    accentColor: accent,
    textStyle: textStyle,
    buttonStyle: ElevatedButton.styleFrom(),
  );
}

void main() {
  testWidgets('quick reply labels are not truncated at dyslexia font 24', (
    tester,
  ) async {
    final bundle = _bundle();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: AssistantQuickReplies(
                bundle: bundle,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suggested questions'), findsOneWidget);
    expect(find.text('How do I add a goal?'), findsOneWidget);
    expect(find.text('What is a time-slot goal?'), findsOneWidget);
    expect(find.text('How do I earn points?'), findsOneWidget);
    expect(find.text('What is AI Encouragement?'), findsOneWidget);
    expect(find.textContaining('What is a time\n'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick reply tap reports full label', (tester) async {
    final bundle = _bundle();
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssistantQuickReplies(
            bundle: bundle,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('How does the Zen garden work?'));
    await tester.pumpAndSettle();

    expect(selected, 'How does the Zen garden work?');
  });
}
