import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/goals/goals_use_case.dart';

/// In-memory result of planning a goal create (no I/O).
class GoalsCreatePlan {
  const GoalsCreatePlan({
    required this.goal,
    required this.activeGoals,
    required this.deadlineHours,
  });

  final GoalSet goal;
  final List<GoalSet> activeGoals;
  final int deadlineHours;
}

/// In-memory result of planning a goal complete (no I/O).
class GoalsCompletePlan {
  const GoalsCompletePlan({
    required this.result,
    required this.activeGoals,
    required this.completedGoals,
    required this.goal,
    required this.pointsDelta,
    required this.goalsCompletedTodayCount,
  });

  final CompleteGoalResult result;
  final List<GoalSet> activeGoals;
  final List<GoalSet> completedGoals;
  final GoalSet goal;
  final int pointsDelta;
  final int goalsCompletedTodayCount;
}

/// Batch create plan.
class GoalsBatchCreatePlan {
  const GoalsBatchCreatePlan({
    required this.newGoals,
    required this.activeGoals,
    required this.deadlineHoursByGoal,
  });

  final List<GoalSet> newGoals;
  final List<GoalSet> activeGoals;
  final Map<GoalSet, int> deadlineHoursByGoal;
}
