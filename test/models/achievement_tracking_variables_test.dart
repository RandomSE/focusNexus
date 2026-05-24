import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';

void main() {
  test('toSnapshot and applySnapshot preserve distinct week/month fields', () {
    final tracking = AchievementTrackingVariables();
    tracking.totalGoalsCreated = 5;
    tracking.lastWeekGoalWasCompleted = '2026-05-04';
    tracking.lastMonthGoalWasCompleted = '2026-05';
    tracking.consecutiveWeeksWithGoalsCompleted = 3;

    final snapshot = tracking.toSnapshot();
    expect(snapshot.lastWeekGoalWasCompleted, '2026-05-04');
    expect(snapshot.lastMonthGoalWasCompleted, '2026-05');

    final other = AchievementTrackingVariables();
    other.applySnapshot(snapshot);
    expect(other.totalGoalsCreated, 5);
    expect(other.lastWeekGoalWasCompleted, '2026-05-04');
    expect(other.lastMonthGoalWasCompleted, '2026-05');
    expect(other.consecutiveWeeksWithGoalsCompleted, 3);
  });
}
