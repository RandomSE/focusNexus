import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/widgets/assistant_faq_panel.dart';
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
  testWidgets('FAQ entries stack vertically with question and answer labels', (
    tester,
  ) async {
    final bundle = _bundle();
    var tappedQuestion = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: AssistantFaqPanel(
                bundle: bundle,
                onQuestionSelected: (q) => tappedQuestion = q,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();

    expect(find.text('QUESTION'), findsWidgets);
    expect(find.text('ANSWER'), findsWidgets);
    expect(find.text('What is FocusNexus?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final questionBox = tester.getRect(find.text('What is FocusNexus?'));
    final answerFinder = find.textContaining('FocusNexus is a calm productivity');
    final answerBox = tester.getRect(answerFinder.first);

    expect(answerBox.top, greaterThan(questionBox.bottom));

    await tester.tap(find.text('What is FocusNexus?'));
    await tester.pumpAndSettle();
    expect(tappedQuestion, 'What is FocusNexus?');
  });

}
