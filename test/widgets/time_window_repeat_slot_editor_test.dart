import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_window_editor.dart';

ThemeBundle _testBundle() => ThemeBundle(
  themeData: ThemeData(),
  primaryColor: Colors.blue,
  secondaryColor: Colors.white,
  accentColor: Colors.orange,
  textStyle: const TextStyle(),
  buttonStyle: ElevatedButton.styleFrom(),
);

void main() {
  testWidgets('repeating slots expose hour and minute controls', (tester) async {
    final endAt = DateTime.now().add(const Duration(hours: 2));
    const duration = Duration(hours: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeWindowWindowEditor(
            bundle: _testBundle(),
            endAt: endAt,
            startAt: endAt.subtract(duration),
            duration: duration,
            onEndChanged: (_) {},
            onStartChanged: (_) {},
            onDurationChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Adjust start (nudge)'), findsOneWidget);
    expect(find.text('-5m'), findsOneWidget);
    expect(find.text('+1h'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Unit'), findsOneWidget);
    expect(find.text('End of day'), findsNothing);
  });

  testWidgets(
    'repeat-enabled editor still allows hour nudges and minute units',
    (tester) async {
      final endAt = DateTime(2026, 8, 9, 13, 0);
      const duration = Duration(hours: 1);
      var startAt = endAt.subtract(duration);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TimeWindowWindowEditor(
                  bundle: _testBundle(),
                  endAt: endAt,
                  startAt: startAt,
                  duration: duration,
                  onEndChanged: (_) {},
                  onStartChanged: (start) => setState(() => startAt = start),
                  onDurationChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('+1h'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.text('End of day'), findsNothing);
    },
  );
}
