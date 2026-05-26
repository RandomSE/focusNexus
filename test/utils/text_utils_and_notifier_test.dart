import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/notifier.dart';
import 'package:focusNexus/utils/text_utils.dart';

void main() {
  final deadline = DateTime.utc(2026, 6, 15, 18, 30);

  group('TextUtils.buildInitialReminderMessage', () {
    test('Minimal style is deterministic', () {
      final message = TextUtils.buildInitialReminderMessage(
        'Write essay',
        'Minimal',
        deadline,
      );
      expect(message, contains('Write essay'));
      expect(message, contains('15 June 2026 18:30'));
    });

    test('Vibrant and Animated styles return non-empty messages', () {
      for (final style in ['Vibrant', 'Animated']) {
        final message = TextUtils.buildInitialReminderMessage(
          'Task',
          style,
          deadline,
        );
        expect(message.isNotEmpty, isTrue);
        expect(message, contains('Task'));
      }
    });
  });

  group('TextUtils.buildFollowUpReminderMessage', () {
    test('Minimal style is deterministic', () {
      final message = TextUtils.buildFollowUpReminderMessage(
        'Write essay',
        42,
        'Minimal',
        deadline,
      );
      expect(message, contains('Write essay / Id: 42'));
      expect(message, contains('15 June 2026 18:30'));
    });

    test('Vibrant and Animated styles return non-empty messages', () {
      for (final style in ['Vibrant', 'Animated']) {
        final message = TextUtils.buildFollowUpReminderMessage(
          'Task',
          7,
          style,
          deadline,
        );
        expect(message.isNotEmpty, isTrue);
      }
    });

    test('unknown style falls back to generic reminder', () {
      final message = TextUtils.buildFollowUpReminderMessage(
        'Task',
        1,
        'Unknown',
        deadline,
      );
      expect(message, startsWith('Reminder:'));
    });
  });

  group('TextUtils.buildEncouragementMessage', () {
    test('deterministic variant selection from goalId', () {
      final a = TextUtils.buildEncouragementMessage(
        'Goal',
        10,
        '01 Jan 2027',
        const ['Custom reason'],
        8,
        5,
        4,
        2,
        3,
        1,
        0,
        'Minimal',
      );
      final b = TextUtils.buildEncouragementMessage(
        'Goal',
        10,
        '01 Jan 2027',
        const ['Custom reason'],
        8,
        5,
        4,
        2,
        3,
        1,
        0,
        'Minimal',
      );
      expect(a, b);
      expect(a, contains('Why this matters'));
    });

    test('dominant complexity produces factor-specific core message', () {
      final message = TextUtils.buildEncouragementMessage(
        'Hard goal',
        3,
        '',
        const [],
        4,
        4,
        1,
        1,
        4,
        1,
        1,
        'Vibrant',
      );
      expect(message.toLowerCase(), contains('complexity'));
    });
  });

  group('TextUtils.dailyAffirmationForDate', () {
    test('same calendar day returns the same message', () {
      final morning = TextUtils.dailyAffirmationForDate(
        DateTime(2026, 5, 26, 6),
      );
      final evening = TextUtils.dailyAffirmationForDate(
        DateTime(2026, 5, 26, 20),
      );
      expect(morning, evening);
    });

    test('consecutive days return different messages', () {
      final today = TextUtils.dailyAffirmationForDate(DateTime(2026, 5, 26));
      final tomorrow = TextUtils.dailyAffirmationForDate(DateTime(2026, 5, 27));
      expect(today, isNot(equals(tomorrow)));
    });

    test('generateDailyAffirmationBody matches today', () {
      final fromDate = TextUtils.dailyAffirmationForDate(DateTime.now());
      final generated = TextUtils.generateDailyAffirmationBody();
      expect(generated, fromDate);
    });
  });

  group('GoalNotifier scoring helpers', () {
    test('getScoreByTypeAndString routes by type', () {
      expect(GoalNotifier.getScoreByTypeAndString('Steps', '50'), 5);
      expect(GoalNotifier.getScoreByTypeAndString('Time', '600'), 5);
      expect(GoalNotifier.getScoreByTypeAndString('Levels', 'High'), 3);
    });

    test('getEncouragementValue aggregates scores and reasons', () {
      final goal = GoalSet(
        title: 'Big',
        category: 'Work',
        complexity: 'High',
        effort: 'High',
        motivation: 'Medium',
        time: 600,
        deadline: 'no deadline',
        steps: 50,
        points: 100,
        stepProgress: 0,
        goalId: 1,
      );
      final (score, reasons, biggest) = GoalNotifier.getEncouragementValue(goal);
      expect(score, greaterThan(0));
      expect(biggest, greaterThanOrEqualTo(3));
      expect(reasons, isNotEmpty);
    });

    test('generateGoalId stays within positive 31-bit range', () {
      for (var i = 0; i < 20; i++) {
        final id = GoalNotifier.generateGoalId('Sample goal $i');
        expect(id, greaterThan(0));
        expect(id <= 0x7FFFFFFF, isTrue);
      }
    });
  });
}
