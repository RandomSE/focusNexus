import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_bottom_actions.dart';

void main() {
  testWidgets('Skip wait stays above pause label so it stays on screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZenGardenCountdownRow(
            remaining: const Duration(minutes: 4, seconds: 30),
            waitTotal: const Duration(minutes: 5),
            skipCost: 10,
            balance: 100,
            textStyle: const TextStyle(fontSize: 28),
            primary: Colors.teal,
            onSkip: () {},
          ),
        ),
      ),
    );

    final skip = tester.getTopLeft(find.textContaining('Skip wait'));
    final pause = tester.getTopLeft(find.textContaining('Pause before next growth'));
    expect(skip.dy, lessThan(pause.dy));
  });
}
