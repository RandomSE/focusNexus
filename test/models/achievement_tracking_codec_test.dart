import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/achievement_tracking_codec.dart';

void main() {
  test('roundtrip preserves all tracking fields', () {
    const original = AchievementTrackingSnapshot(
      totalGoalsCreated: 3,
      totalGoalsActive: 2,
      totalGoalsCompleted: 10,
      goalsCompletedToday: 1,
      goalsCompletedThisWeek: 4,
      goalsCompletedThisMonth: 7,
      goalsCompletedWithHighPoints: 2,
      goalsCompletedWithHighComplexity: 1,
      goalsCompletedWithHighEffort: 1,
      goalsCompletedWithHighMotivation: 1,
      goalsCompletedWithAllHigh: 1,
      goalsCompletedWithHighTimeRequirement: 2,
      goalsCompletedWithManySteps: 3,
      goalsCompletedEarly: 5,
      datesGoalsCompleted: '01-05-2026,02-05-2026',
      lastWeekGoalWasCompleted: '2026-04-28',
      lastMonthGoalWasCompleted: '2026-04',
      consecutiveDaysWithGoalsCompleted: 4,
      consecutiveWeeksWithGoalsCompleted: 2,
    );

    final restored = AchievementTrackingSnapshot.fromJson(original.toJson());
    expect(restored.totalGoalsCreated, original.totalGoalsCreated);
    expect(restored.lastWeekGoalWasCompleted, '2026-04-28');
    expect(restored.lastMonthGoalWasCompleted, '2026-04');
    expect(restored.datesGoalsCompleted, original.datesGoalsCompleted);
  });

  test('fromJson applies defaults for missing keys', () {
    final snapshot = AchievementTrackingSnapshot.fromJson({});
    expect(snapshot.totalGoalsCreated, 0);
    expect(snapshot.lastWeekGoalWasCompleted, '');
  });
}
