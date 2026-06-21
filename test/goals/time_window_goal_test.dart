import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/goals/goal_kind.dart';

void main() {
  group('computeActionWindow', () {
    test('clamps start to now when ideal start is in the past', () {
      final now = DateTime(2026, 6, 21, 10);
      final end = now.add(const Duration(days: 1));
      final window = computeActionWindow(
        endAt: end,
        duration: const Duration(days: 3),
        now: now,
      );

      expect(window.start, now);
      expect(window.end, end);
      expect(window.wasStartClamped, isTrue);
    });

    test('keeps ideal start when it is in the future', () {
      final now = DateTime(2026, 6, 21, 10);
      final end = now.add(const Duration(hours: 5));
      final window = computeActionWindow(
        endAt: end,
        duration: const Duration(hours: 2),
        now: now,
      );

      expect(window.start, end.subtract(const Duration(hours: 2)));
      expect(window.wasStartClamped, isFalse);
    });
  });

  group('resolveActionWindowReminderTime', () {
    final now = DateTime(2026, 6, 21, 10);

    test('reminds at start when window has not begun', () {
      final start = now.add(const Duration(hours: 2));
      final end = start.add(const Duration(hours: 1));
      expect(
        resolveActionWindowReminderTime(
          start: start,
          end: end,
          now: now,
          wasStartClamped: false,
        ),
        start,
      );
    });

    test('reminds one hour before end when start was clamped and window is long', () {
      final end = now.add(const Duration(hours: 5));
      expect(
        resolveActionWindowReminderTime(
          start: now,
          end: end,
          now: now,
          wasStartClamped: true,
        ),
        end.subtract(const Duration(hours: 1)),
      );
    });

    test('returns null for short clamped window', () {
      final end = now.add(const Duration(minutes: 30));
      expect(
        resolveActionWindowReminderTime(
          start: now,
          end: end,
          now: now,
          wasStartClamped: true,
        ),
        isNull,
      );
    });
  });

  group('isActionWindowActive', () {
    test('is false outside window for time-window goals', () {
      final goal = GoalSet(
        goalKind: GoalKind.timeWindow,
        actionWindowStart: DateTime(2026, 6, 21, 12).toIso8601String(),
        actionWindowEnd: DateTime(2026, 6, 21, 14).toIso8601String(),
        goalId: 1,
        title: 'Walk',
      );
      expect(
        isActionWindowActive(goal, DateTime(2026, 6, 21, 11)),
        isFalse,
      );
      expect(
        isActionWindowActive(goal, DateTime(2026, 6, 21, 13)),
        isTrue,
      );
      expect(
        isActionWindowActive(goal, DateTime(2026, 6, 21, 14)),
        isFalse,
      );
    });
  });

  group('computeNextWindowEnd', () {
    final anchor = DateTime(2026, 6, 21, 18);

    test('hourly repeats from anchor', () {
      final rule = RepeatRule(
        enabled: true,
        unit: RepeatUnit.hours,
        interval: 2,
      );
      expect(
        computeNextWindowEnd(
          rule: rule,
          anchorEndAt: anchor,
          after: anchor,
        ),
        anchor.add(const Duration(hours: 2)),
      );
    });

    test('daily repeats respect interval', () {
      final rule = RepeatRule(
        enabled: true,
        unit: RepeatUnit.days,
        interval: 1,
      );
      expect(
        computeNextWindowEnd(
          rule: rule,
          anchorEndAt: anchor,
          after: anchor,
        ),
        anchor.add(const Duration(days: 1)),
      );
    });

    test('weekly repeats on selected weekdays', () {
      final rule = RepeatRule(
        enabled: true,
        unit: RepeatUnit.weeks,
        interval: 1,
        weekdays: {DateTime.monday, DateTime.wednesday},
      );
      final next = computeNextWindowEnd(
        rule: rule,
        anchorEndAt: anchor,
        after: anchor,
      );
      expect(next, isNotNull);
      expect({DateTime.monday, DateTime.wednesday}, contains(next!.weekday));
      expect(next.isAfter(anchor), isTrue);
    });

    test('returns null when repeat disabled', () {
      expect(
        computeNextWindowEnd(
          rule: RepeatRule.none,
          anchorEndAt: anchor,
          after: anchor,
        ),
        isNull,
      );
    });
  });

  group('isStrictWindow', () {
    test('three hours or less is strict', () {
      expect(isStrictWindow(const Duration(hours: 3)), isTrue);
      expect(isStrictWindow(const Duration(hours: 4)), isFalse);
    });
  });
}
