import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  group('clampUserFontSize', () {
    test('clamps to 10 minimum', () {
      expect(clampUserFontSize(5), kMinFontSize);
      expect(clampUserFontSize(9), kMinFontSize);
    });

    test('clamps to 24 maximum', () {
      expect(clampUserFontSize(25), kMaxFontSize);
      expect(clampUserFontSize(30), kMaxFontSize);
    });

    test('preserves values inside range', () {
      expect(clampUserFontSize(14), 14);
      expect(clampUserFontSize(22), 22);
    });

    test('step deltas from 22 respect caps', () {
      expect(clampUserFontSize(22 + 5), kMaxFontSize);
      expect(clampUserFontSize(kMinFontSize - 1), kMinFontSize);
    });
  });

  testWidgets('font size label is visible without dyslexia font', (tester) async {
    final container = await createTestContainer();
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return VisualSettingsPanel(
                  bundle: ThemeBundle(
                    themeData: theme,
                    textStyle: const TextStyle(fontSize: 14),
                    primaryColor: Colors.black,
                    secondaryColor: Colors.white,
                    accentColor: Colors.blue,
                    buttonStyle: TextButton.styleFrom(),
                  ),
                  onAppearanceChange: (apply) async => apply(),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Font size'), findsOneWidget);
  });
}
