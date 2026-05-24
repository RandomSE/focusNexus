/// JSON codec for achievement tracking variables (storage roundtrip).
class AchievementTrackingSnapshot {
  const AchievementTrackingSnapshot({
    this.totalGoalsCreated = 0,
    this.totalGoalsActive = 0,
    this.totalGoalsCompleted = 0,
    this.goalsCompletedToday = 0,
    this.goalsCompletedThisWeek = 0,
    this.goalsCompletedThisMonth = 0,
    this.goalsCompletedWithHighPoints = 0,
    this.goalsCompletedWithHighComplexity = 0,
    this.goalsCompletedWithHighEffort = 0,
    this.goalsCompletedWithHighMotivation = 0,
    this.goalsCompletedWithAllHigh = 0,
    this.goalsCompletedWithHighTimeRequirement = 0,
    this.goalsCompletedWithManySteps = 0,
    this.goalsCompletedEarly = 0,
    this.datesGoalsCompleted = '',
    this.lastWeekGoalWasCompleted = '',
    this.lastMonthGoalWasCompleted = '',
    this.consecutiveDaysWithGoalsCompleted = 0,
    this.consecutiveWeeksWithGoalsCompleted = 0,
  });

  final int totalGoalsCreated;
  final int totalGoalsActive;
  final int totalGoalsCompleted;
  final int goalsCompletedToday;
  final int goalsCompletedThisWeek;
  final int goalsCompletedThisMonth;
  final int goalsCompletedWithHighPoints;
  final int goalsCompletedWithHighComplexity;
  final int goalsCompletedWithHighEffort;
  final int goalsCompletedWithHighMotivation;
  final int goalsCompletedWithAllHigh;
  final int goalsCompletedWithHighTimeRequirement;
  final int goalsCompletedWithManySteps;
  final int goalsCompletedEarly;
  final String datesGoalsCompleted;
  final String lastWeekGoalWasCompleted;
  final String lastMonthGoalWasCompleted;
  final int consecutiveDaysWithGoalsCompleted;
  final int consecutiveWeeksWithGoalsCompleted;

  Map<String, dynamic> toJson() => {
        'totalGoalsCreated': totalGoalsCreated,
        'totalGoalsActive': totalGoalsActive,
        'totalGoalsCompleted': totalGoalsCompleted,
        'goalsCompletedToday': goalsCompletedToday,
        'goalsCompletedThisWeek': goalsCompletedThisWeek,
        'goalsCompletedThisMonth': goalsCompletedThisMonth,
        'goalsCompletedWithHighPoints': goalsCompletedWithHighPoints,
        'goalsCompletedWithHighComplexity': goalsCompletedWithHighComplexity,
        'goalsCompletedWithHighEffort': goalsCompletedWithHighEffort,
        'goalsCompletedWithHighMotivation': goalsCompletedWithHighMotivation,
        'goalsCompletedWithAllHigh': goalsCompletedWithAllHigh,
        'goalsCompletedWithHighTimeRequirement':
            goalsCompletedWithHighTimeRequirement,
        'goalsCompletedWithManySteps': goalsCompletedWithManySteps,
        'goalsCompletedEarly': goalsCompletedEarly,
        'datesGoalsCompleted': datesGoalsCompleted,
        'lastWeekGoalWasCompleted': lastWeekGoalWasCompleted,
        'lastMonthGoalWasCompleted': lastMonthGoalWasCompleted,
        'consecutiveDaysWithGoalsCompleted': consecutiveDaysWithGoalsCompleted,
        'consecutiveWeeksWithGoalsCompleted':
            consecutiveWeeksWithGoalsCompleted,
      };

  factory AchievementTrackingSnapshot.fromJson(Map<String, dynamic> json) {
    return AchievementTrackingSnapshot(
      totalGoalsCreated: json['totalGoalsCreated'] ?? 0,
      totalGoalsActive: json['totalGoalsActive'] ?? 0,
      totalGoalsCompleted: json['totalGoalsCompleted'] ?? 0,
      goalsCompletedToday: json['goalsCompletedToday'] ?? 0,
      goalsCompletedThisWeek: json['goalsCompletedThisWeek'] ?? 0,
      goalsCompletedThisMonth: json['goalsCompletedThisMonth'] ?? 0,
      goalsCompletedWithHighPoints: json['goalsCompletedWithHighPoints'] ?? 0,
      goalsCompletedWithHighComplexity:
          json['goalsCompletedWithHighComplexity'] ?? 0,
      goalsCompletedWithHighEffort: json['goalsCompletedWithHighEffort'] ?? 0,
      goalsCompletedWithHighMotivation:
          json['goalsCompletedWithHighMotivation'] ?? 0,
      goalsCompletedWithAllHigh: json['goalsCompletedWithAllHigh'] ?? 0,
      goalsCompletedWithHighTimeRequirement:
          json['goalsCompletedWithHighTimeRequirement'] ?? 0,
      goalsCompletedWithManySteps: json['goalsCompletedWithManySteps'] ?? 0,
      goalsCompletedEarly: json['goalsCompletedEarly'] ?? 0,
      datesGoalsCompleted: json['datesGoalsCompleted'] ?? '',
      lastWeekGoalWasCompleted: json['lastWeekGoalWasCompleted'] ?? '',
      lastMonthGoalWasCompleted: json['lastMonthGoalWasCompleted'] ?? '',
      consecutiveDaysWithGoalsCompleted:
          json['consecutiveDaysWithGoalsCompleted'] ?? 0,
      consecutiveWeeksWithGoalsCompleted:
          json['consecutiveWeeksWithGoalsCompleted'] ?? 0,
    );
  }
}
