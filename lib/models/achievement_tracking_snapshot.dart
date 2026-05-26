import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement_tracking_snapshot.freezed.dart';
part 'achievement_tracking_snapshot.g.dart';

/// JSON snapshot of goal-related achievement counters (single storage blob).
@freezed
class AchievementTrackingSnapshot with _$AchievementTrackingSnapshot {
  const factory AchievementTrackingSnapshot({
    @Default(0) int totalGoalsCreated,
    @Default(0) int totalGoalsActive,
    @Default(0) int totalGoalsCompleted,
    @Default(0) int goalsCompletedToday,
    @Default(0) int goalsCompletedThisWeek,
    @Default(0) int goalsCompletedThisMonth,
    @Default(0) int goalsCompletedWithHighPoints,
    @Default(0) int goalsCompletedWithHighComplexity,
    @Default(0) int goalsCompletedWithHighEffort,
    @Default(0) int goalsCompletedWithHighMotivation,
    @Default(0) int goalsCompletedWithAllHigh,
    @Default(0) int goalsCompletedWithHighTimeRequirement,
    @Default(0) int goalsCompletedWithManySteps,
    @Default(0) int goalsCompletedEarly,
    @Default('') String datesGoalsCompleted,
    @Default('') String lastWeekGoalWasCompleted,
    @Default('') String lastMonthGoalWasCompleted,
    @Default(0) int consecutiveDaysWithGoalsCompleted,
    @Default(0) int consecutiveWeeksWithGoalsCompleted,
  }) = _AchievementTrackingSnapshot;

  factory AchievementTrackingSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AchievementTrackingSnapshotFromJson(json);
}
