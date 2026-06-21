import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/goal_achievement_eval.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

/// Tracking-variable keys touched by goal lifecycle events (for incremental achievement updates).
abstract final class GoalAchievementTrackingKeys {
  static const onCreate = {
    StorageKeys.totalGoalsCreated,
    StorageKeys.totalGoalsActive,
  };

  static const onCompleteCore = {
    StorageKeys.totalGoalsActive,
    StorageKeys.totalGoalsCompleted,
    StorageKeys.goalsCompletedToday,
    StorageKeys.goalsCompletedThisWeek,
    StorageKeys.goalsCompletedThisMonth,
    StorageKeys.consecutiveDaysWithGoalsCompleted,
    StorageKeys.consecutiveWeeksWithGoalsCompleted,
    StorageKeys.categoriesWithAtLeast1Goal,
    StorageKeys.categoriesWithAtLeast3Goals,
    StorageKeys.categoriesWithAtLeast5Goals,
    StorageKeys.categoriesWithAtLeast10Goals,
    StorageKeys.categoriesWithAtLeast25Goals,
    StorageKeys.categoriesWithAllTypesCompleted,
  };

  static Set<String> forGoalCompletion(GoalSet goal, DateTime now) {
    final keys = Set<String>.from(onCompleteCore);
    final eval = GoalAchievementEval.evaluate(goal, now);
    if (eval.highPoints) {
      keys.add(StorageKeys.goalsCompletedWithHighPoints);
    }
    if (eval.highComplexity) {
      keys.add(StorageKeys.goalsCompletedWithHighComplexity);
    }
    if (eval.highEffort) {
      keys.add(StorageKeys.goalsCompletedWithHighEffort);
    }
    if (eval.highMotivation) {
      keys.add(StorageKeys.goalsCompletedWithHighMotivation);
    }
    if (eval.allHigh) {
      keys.add(StorageKeys.goalsCompletedWithAllHigh);
    }
    if (eval.highTimeRequirement) {
      keys.add(StorageKeys.goalsCompletedWithHighTimeRequirement);
    }
    if (eval.manySteps) {
      keys.add(StorageKeys.goalsCompletedWithManySteps);
    }
    if (eval.completedEarly) {
      keys.add(StorageKeys.goalsCompletedEarly);
    }
    return keys;
  }
}
