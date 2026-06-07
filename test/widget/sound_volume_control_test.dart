import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/widgets/sound_volume_control.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('SoundVolumeControl lays out inside ListView when sound enabled',
      (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final bundle = ThemeBundle(
                      themeData: theme,
                      textStyle: const TextStyle(fontSize: 14),
                      primaryColor: Colors.black,
                      secondaryColor: Colors.white,
                      accentColor: Colors.blue,
                      buttonStyle: TextButton.styleFrom(),
                    );
                    return SoundVolumeControl(bundle: bundle);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Volume:'), findsOneWidget);
    expect(find.text('−5%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
