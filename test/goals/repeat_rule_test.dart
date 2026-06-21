import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';

void main() {
  group('RepeatRule serialization', () {
    test('round-trips through map', () {
      const rule = RepeatRule(
        enabled: true,
        unit: RepeatUnit.weeks,
        interval: 2,
        weekdays: {1, 3, 5},
        startOffset: Duration(hours: 1),
      );
      final restored = RepeatRule.fromMap(rule.toMap());
      expect(restored.enabled, isTrue);
      expect(restored.unit, RepeatUnit.weeks);
      expect(restored.interval, 2);
      expect(restored.weekdays, {1, 3, 5});
      expect(restored.startOffset, const Duration(hours: 1));
    });
  });

  group('summarizeRepeatRule', () {
    test('describes enabled weekly rule', () {
      final text = summarizeRepeatRule(
        RepeatRule(
          enabled: true,
          unit: RepeatUnit.weeks,
          interval: 1,
          weekdays: {1, 5},
        ),
      );
      expect(text, contains('Every 1 week'));
      expect(text, contains('Mon'));
      expect(text, contains('Fri'));
    });
  });
}
