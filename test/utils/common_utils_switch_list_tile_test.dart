import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/common_utils.dart';

Text _switchTitleText(WidgetTester tester) {
  final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
  final title = switchTile.title;
  expect(title, isA<Text>());
  return title! as Text;
}

void main() {
  group('buildSwitchListTile label layout', () {
    testWidgets('large non-dyslexia font wraps title instead of ellipsizing', (
      tester,
    ) async {
      const title = 'Confirm before restart growth';
      const textStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: CommonUtils.buildSwitchListTile(
                title,
                textStyle,
                false,
                (_) {},
                Colors.blue,
              ),
            ),
          ),
        ),
      );

      final titleText = _switchTitleText(tester);
      expect(titleText.maxLines, greaterThan(1));
      expect(titleText.overflow, TextOverflow.visible);
      expect(find.text(title), findsOneWidget);
    });

    testWidgets('default font size keeps single-line ellipsis', (tester) async {
      const title = 'Hide motivational phrases';
      const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: CommonUtils.buildSwitchListTile(
                title,
                textStyle,
                false,
                (_) {},
                Colors.blue,
              ),
            ),
          ),
        ),
      );

      final titleText = _switchTitleText(tester);
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('dyslexia font wraps title at smaller sizes', (tester) async {
      const title = 'Dyslexia-friendly Font';
      const textStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'OpenDyslexic',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: CommonUtils.buildSwitchListTile(
                title,
                textStyle,
                false,
                (_) {},
                Colors.blue,
              ),
            ),
          ),
        ),
      );

      final titleText = _switchTitleText(tester);
      expect(titleText.maxLines, greaterThan(1));
      expect(titleText.overflow, TextOverflow.visible);
    });
  });
}
