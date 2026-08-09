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
  testWidgets(
    'changing the duration field preserves the requested duration even when '
    'the computed start would clamp to now',
    (tester) async {
      // Minute-floored so clampActionWindowStart's minute-precision rounding
      // (it drops seconds) does not introduce spurious drift in assertions.
      final rawNow = DateTime.now();
      final now = DateTime(
        rawNow.year,
        rawNow.month,
        rawNow.day,
        rawNow.hour,
        rawNow.minute,
      );
      // Chosen so the *current* 1h duration keeps start in the future (no
      // clamp yet), but bumping to 2h pushes the computed start before now.
      final endAt = now.add(const Duration(minutes: 50));
      const initialDuration = Duration(hours: 1);
      var startAt = endAt.subtract(initialDuration);

      Duration? capturedDuration;
      DateTime? capturedStart;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TimeWindowWindowEditor(
                  bundle: _testBundle(),
                  endAt: endAt,
                  startAt: startAt,
                  duration: initialDuration,
                  onEndChanged: (_) {},
                  onStartChanged: (start) {
                    capturedStart = start;
                    setState(() => startAt = start);
                  },
                  onDurationChanged: (duration) {
                    capturedDuration = duration;
                  },
                );
              },
            ),
          ),
        ),
      );

      final amountField = find.widgetWithText(TextFormField, '1');
      expect(amountField, findsOneWidget);

      // Bump the requested duration from 1h to 2h. end - 2h is before "now",
      // so the displayed start must clamp, but the emitted duration must not
      // shrink to match the clamped start (that was the regression).
      await tester.enterText(amountField, '2');
      await tester.pump();

      expect(
        capturedDuration,
        const Duration(hours: 2),
        reason:
            'onDurationChanged must receive the full requested duration, not '
            'the shrunk end.difference(clampedStart)',
      );
      expect(
        capturedStart!.isBefore(now) || capturedStart!.isAtSameMomentAs(now),
        isTrue,
        reason: 'the displayed start clamps to now for display purposes only',
      );
    },
  );

  testWidgets(
    'nudging the start time (not the duration) still recomputes duration '
    'from the explicit start, unaffected by the duration-preservation fix',
    (tester) async {
      final rawNow = DateTime.now();
      final now = DateTime(
        rawNow.year,
        rawNow.month,
        rawNow.day,
        rawNow.hour,
        rawNow.minute,
      );
      final endAt = now.add(const Duration(hours: 3));
      const initialDuration = Duration(hours: 2);
      var startAt = endAt.subtract(initialDuration);
      var lastDuration = initialDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TimeWindowWindowEditor(
                  bundle: _testBundle(),
                  endAt: endAt,
                  startAt: startAt,
                  duration: lastDuration,
                  onEndChanged: (_) {},
                  onStartChanged: (start) => setState(() => startAt = start),
                  onDurationChanged: (duration) =>
                      setState(() => lastDuration = duration),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('+1h'));
      await tester.pump();

      // Explicit start nudges intentionally recompute duration from the new
      // start (this is the "adjust start" affordance, distinct from the
      // duration-field / end-date bug this feature fixes).
      expect(lastDuration, const Duration(hours: 1));
    },
  );
}
