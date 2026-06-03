import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/notifier.dart';

void main() {
  test('summaryNotificationIdFor is stable per minute bucket', () {
    final time = DateTime(2026, 6, 2, 14, 30);
    final idA = GoalNotifier.summaryNotificationIdFor(1, time);
    final idB = GoalNotifier.summaryNotificationIdFor(1, time);
    final idC = GoalNotifier.summaryNotificationIdFor(
      1,
      time.add(const Duration(seconds: 20)),
    );

    expect(idA, idB);
    expect(idA, isNot(equals(GoalNotifier.summaryNotificationIdFor(2, time))));
    expect(idC, idA);
  });

  test('summaryNotificationIdFor differs across distant times', () {
    final early = DateTime(2026, 6, 2, 8);
    final late = DateTime(2026, 6, 2, 18);
    expect(
      GoalNotifier.summaryNotificationIdFor(1, early),
      isNot(equals(GoalNotifier.summaryNotificationIdFor(1, late))),
    );
  });
}
