import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/goals/goal_time_window_label.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

void main() {
  group('goalTimeWindowLabel', () {
    test('uses hyphen between start and end', () {
      final goal = GoalSet(
        goalId: 1,
        title: 'Walk',
        goalKind: GoalKind.timeWindow,
        actionWindowStart: DateTime(2026, 6, 21, 16, 50).toIso8601String(),
        actionWindowEnd: DateTime(2026, 6, 21, 18, 50).toIso8601String(),
      );
      final label = goalTimeWindowLabel(goal);
      expect(label, contains(' - '));
      expect(label, isNot(contains('–')));
      expect(label, isNot(contains('—')));
      expect(label, contains('16:50'));
      expect(label, contains('18:50'));
    });
  });

  group('goalListSubtitleLines', () {
    final now = DateTime(2026, 6, 21, 17);

    test('includes slot, status, and repeat cadence for time-window goals', () {
      final goal = GoalSet(
        goalId: 1,
        title: 'Walk',
        goalKind: GoalKind.timeWindow,
        repeatSeriesId: 3,
        actionWindowStart: DateTime(2026, 6, 21, 16, 50).toIso8601String(),
        actionWindowEnd: DateTime(2026, 6, 21, 18, 50).toIso8601String(),
        points: 12,
      );
      final lines = goalListSubtitleLines(
        goal: goal,
        selectedStatusFilter: 'Active',
        now: now,
        repeatRule: const RepeatRule(
          enabled: true,
          unit: RepeatUnit.days,
          interval: 1,
        ),
      );
      expect(lines.any((l) => l.startsWith('Slot:')), isTrue);
      expect(lines, contains('In slot now'));
      expect(lines, contains('Every 1 day'));
    });
  });
}
