import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/screens/goals/widgets/clear_active_goals_repeat_dialog.dart';

ThemeBundle _testBundle() => ThemeBundle(
  themeData: ThemeData(),
  primaryColor: Colors.blue,
  secondaryColor: Colors.white,
  accentColor: Colors.orange,
  textStyle: const TextStyle(),
  buttonStyle: ElevatedButton.styleFrom(),
);

void main() {
  testWidgets('clear active repeat dialog offers yes and no', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showClearActiveGoalsRepeatDialog(
                    context: context,
                    bundle: _testBundle(),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Also cancel repeating schedules?'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
