import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/screens/onboarding/onboarding_live_stats.dart';
import 'package:focusNexus/screens/onboarding/onboarding_slides.dart';
import 'package:focusNexus/utils/theme_styles.dart';

ThemeBundle _bundle({double fontSize = 24, bool dyslexia = true}) {
  final primary = Colors.black87;
  final secondary = Colors.white;
  final accent = Colors.teal;
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
  const tightSize = Size(371, 286);
  const stats = OnboardingLiveStats();

  Future<void> pumpSlide(
    WidgetTester tester,
    OnboardingSlideId id,
  ) async {
    final bundle = _bundle();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.fromSize(
            size: tightSize,
            child: buildOnboardingSlide(
              id: id,
              bundle: bundle,
              stats: stats,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final id in OnboardingSlideId.values) {
    testWidgets('${id.name} slide avoids overflow at large dyslexia font', (
      tester,
    ) async {
      await pumpSlide(tester, id);
      expect(tester.takeException(), isNull);
    });
  }
}
