import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_points_labels.dart';
import 'package:focusNexus/utils/goal_points.dart';

void main() {
  group('firstOfDaySplitPreview', () {
    test('shows pre-round sum and rounded total when they differ', () {
      // 420 * 1.35 = 567; +10 = 577; rounds to 580.
      final label = firstOfDaySplitPreview(420);
      expect(label, contains('~580 if first today'));
      expect(label, contains('effort 567'));
      expect(label, contains('momentum 10'));
      expect(label, contains('= 577'));
      expect(label, contains('rounded to 580'));
      expect(label, isNot(contains('rounded up')));
      expect(
        GoalPoints.previewFirstOfDayAward(420),
        580,
      );
    });

    test('uses rounded (not rounded up) when sum rounds down to nearest five', () {
      // 30 * 1.35 = 40.5; +10 = 50.5; nearest-five helper yields 50.
      final label = firstOfDaySplitPreview(30);
      expect(label, contains('effort 40.5'));
      expect(label, contains('= 50.5'));
      expect(label, contains('rounded to 50'));
      expect(label, isNot(contains('rounded up')));
    });

    test('omits rounding clause when sum already matches total', () {
      // 100 * 1.35 = 135; +10 = 145 -> already multiple of 5.
      final label = firstOfDaySplitPreview(100);
      expect(label, '~145 if first today (effort 135 + momentum 10)');
      expect(label, isNot(contains('rounded')));
    });
  });
}
