import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
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

DateTime _minuteFloor(DateTime value) => DateTime(
  value.year,
  value.month,
  value.day,
  value.hour,
  value.minute,
);

void main() {
  test(
    'clampActionWindowStart at the next minute is after a stale setup now',
    () {
      // Deterministic stand-in for the nightly flake: setup floors `now` at
      // 10:30, apply-time now is 10:31, and the old `capturedStart <= setupNow`
      // check fails even though clamp did the right thing.
      final setupNow = DateTime(2026, 9, 4, 10, 30);
      final applyNow = setupNow.add(const Duration(minutes: 1));
      final endAt = setupNow.add(const Duration(minutes: 50));
      final capturedStart = clampActionWindowStart(
        start: endAt.subtract(const Duration(hours: 2)),
        end: endAt,
        now: applyNow,
      );
      expect(capturedStart, applyNow);
      expect(
        !capturedStart.isBefore(setupNow) &&
            !capturedStart.isAfter(applyNow),
        isTrue,
      );
    },
  );

  testWidgets(
    'changing the duration field preserves the requested duration even when '
    'the computed start would clamp to now',
    (tester) async {
      // Minute-floored so clampActionWindowStart's minute-precision rounding
      // (it drops seconds) does not introduce spurious drift in assertions.
      final now = _minuteFloor(DateTime.now());
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
      // Clamp uses DateTime.now() at apply time. The setup snapshot of `now`
      // is stale if the clock rolls to the next minute before enterText
      // (nightly flake: capturedStart is the new minute, which is after
      // setup `now`). Bound the clamp to [setup now, current minute].
      final clampFloorAfter = _minuteFloor(DateTime.now());
      expect(capturedStart, isNotNull);
      expect(
        !capturedStart!.isBefore(now) &&
            !capturedStart!.isAfter(clampFloorAfter),
        isTrue,
        reason:
            'the displayed start clamps to the current minute for display '
            'purposes only, including when that minute is the next one after '
            'test setup',
      );
    },
  );

  testWidgets(
    'nudging the start time (not the duration) still recomputes duration '
    'from the explicit start, unaffected by the duration-preservation fix',
    (tester) async {
      final now = _minuteFloor(DateTime.now());
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

      // Nudging start moves the ideal start but keeps the configured slot length.
      expect(lastDuration, const Duration(hours: 2));
      expect(startAt, endAt.subtract(const Duration(hours: 1)));
    },
  );
}
