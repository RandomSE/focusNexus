// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_tracking_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AchievementTrackingSnapshotImpl _$$AchievementTrackingSnapshotImplFromJson(
  Map<String, dynamic> json,
) => _$AchievementTrackingSnapshotImpl(
  totalGoalsCreated: (json['totalGoalsCreated'] as num?)?.toInt() ?? 0,
  totalGoalsActive: (json['totalGoalsActive'] as num?)?.toInt() ?? 0,
  totalGoalsCompleted: (json['totalGoalsCompleted'] as num?)?.toInt() ?? 0,
  goalsCompletedToday: (json['goalsCompletedToday'] as num?)?.toInt() ?? 0,
  goalsCompletedThisWeek:
      (json['goalsCompletedThisWeek'] as num?)?.toInt() ?? 0,
  goalsCompletedThisMonth:
      (json['goalsCompletedThisMonth'] as num?)?.toInt() ?? 0,
  goalsCompletedWithHighPoints:
      (json['goalsCompletedWithHighPoints'] as num?)?.toInt() ?? 0,
  goalsCompletedWithHighComplexity:
      (json['goalsCompletedWithHighComplexity'] as num?)?.toInt() ?? 0,
  goalsCompletedWithHighEffort:
      (json['goalsCompletedWithHighEffort'] as num?)?.toInt() ?? 0,
  goalsCompletedWithHighMotivation:
      (json['goalsCompletedWithHighMotivation'] as num?)?.toInt() ?? 0,
  goalsCompletedWithAllHigh:
      (json['goalsCompletedWithAllHigh'] as num?)?.toInt() ?? 0,
  goalsCompletedWithHighTimeRequirement:
      (json['goalsCompletedWithHighTimeRequirement'] as num?)?.toInt() ?? 0,
  goalsCompletedWithManySteps:
      (json['goalsCompletedWithManySteps'] as num?)?.toInt() ?? 0,
  goalsCompletedEarly: (json['goalsCompletedEarly'] as num?)?.toInt() ?? 0,
  datesGoalsCompleted: json['datesGoalsCompleted'] as String? ?? '',
  lastWeekGoalWasCompleted: json['lastWeekGoalWasCompleted'] as String? ?? '',
  lastMonthGoalWasCompleted: json['lastMonthGoalWasCompleted'] as String? ?? '',
  consecutiveDaysWithGoalsCompleted:
      (json['consecutiveDaysWithGoalsCompleted'] as num?)?.toInt() ?? 0,
  consecutiveWeeksWithGoalsCompleted:
      (json['consecutiveWeeksWithGoalsCompleted'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$AchievementTrackingSnapshotImplToJson(
  _$AchievementTrackingSnapshotImpl instance,
) => <String, dynamic>{
  'totalGoalsCreated': instance.totalGoalsCreated,
  'totalGoalsActive': instance.totalGoalsActive,
  'totalGoalsCompleted': instance.totalGoalsCompleted,
  'goalsCompletedToday': instance.goalsCompletedToday,
  'goalsCompletedThisWeek': instance.goalsCompletedThisWeek,
  'goalsCompletedThisMonth': instance.goalsCompletedThisMonth,
  'goalsCompletedWithHighPoints': instance.goalsCompletedWithHighPoints,
  'goalsCompletedWithHighComplexity': instance.goalsCompletedWithHighComplexity,
  'goalsCompletedWithHighEffort': instance.goalsCompletedWithHighEffort,
  'goalsCompletedWithHighMotivation': instance.goalsCompletedWithHighMotivation,
  'goalsCompletedWithAllHigh': instance.goalsCompletedWithAllHigh,
  'goalsCompletedWithHighTimeRequirement':
      instance.goalsCompletedWithHighTimeRequirement,
  'goalsCompletedWithManySteps': instance.goalsCompletedWithManySteps,
  'goalsCompletedEarly': instance.goalsCompletedEarly,
  'datesGoalsCompleted': instance.datesGoalsCompleted,
  'lastWeekGoalWasCompleted': instance.lastWeekGoalWasCompleted,
  'lastMonthGoalWasCompleted': instance.lastMonthGoalWasCompleted,
  'consecutiveDaysWithGoalsCompleted':
      instance.consecutiveDaysWithGoalsCompleted,
  'consecutiveWeeksWithGoalsCompleted':
      instance.consecutiveWeeksWithGoalsCompleted,
};
