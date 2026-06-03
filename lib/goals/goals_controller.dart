import 'package:flutter/foundation.dart';

import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

/// In-memory goals state for the goals screen; delegates domain work to [GoalsUseCase].
class GoalsController extends ChangeNotifier {
  GoalsController(this._useCase);

  final GoalsUseCase _useCase;

  List<GoalSet> activeGoals = [];
  List<GoalSet> completedGoals = [];
  int goalsCompletedToday = 0;

  Future<void> load({DateTime? now}) async {
    final snapshot = await _useCase.load(now: now);
    activeGoals = snapshot.active;
    completedGoals = snapshot.completed;
    goalsCompletedToday = snapshot.goalsCompletedToday;
    notifyListeners();
  }

  Future<GoalSet> createGoal({
    required String title,
    required String category,
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required int deadlineHours,
    required DateTime anchor,
  }) async {
    final goal = await _useCase.createGoal(
      title: title,
      category: category,
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      deadlineHours: deadlineHours,
      anchor: anchor,
    );
    activeGoals = [...activeGoals, goal];
    notifyListeners();
    return goal;
  }

  Future<CompleteGoalResult?> completeGoal(int goalId) async {
    final result = await _useCase.completeGoal(goalId);
    if (result == null) return null;
    activeGoals = activeGoals.where((g) => g.goalId != goalId).toList();
    completedGoals = [...completedGoals, result.goal];
    goalsCompletedToday = result.goalsCompletedToday;
    notifyListeners();
    return result;
  }

  Future<StepProgressResult?> incrementStepProgress(int goalId) async {
    final result = await _useCase.incrementStepProgress(goalId);
    if (result == null) return null;

    if (result.completed != null) {
      final completed = result.completed!;
      activeGoals = activeGoals.where((g) => g.goalId != goalId).toList();
      completedGoals = [...completedGoals, completed.goal];
      goalsCompletedToday = completed.goalsCompletedToday;
    } else {
      final index = activeGoals.indexWhere((g) => g.goalId == goalId);
      if (index >= 0) {
        final updated = activeGoals[index].copyWith(
          stepProgress: activeGoals[index].stepProgress + 1,
        );
        activeGoals = List<GoalSet>.from(activeGoals)..[index] = updated;
      }
    }
    notifyListeners();
    return result;
  }

  Future<void> removeGoal(int goalId) async {
    await _useCase.removeGoal(goalId);
    activeGoals = activeGoals.where((g) => g.goalId != goalId).toList();
    notifyListeners();
  }

  Future<void> removeCompletedGoal(int goalId) async {
    await _useCase.removeCompletedGoal(goalId);
    completedGoals =
        completedGoals.where((g) => g.goalId != goalId).toList();
    notifyListeners();
  }

  Future<void> clearActiveGoals() async {
    await _useCase.clearActiveGoals();
    activeGoals = [];
    notifyListeners();
  }

  Future<void> clearCompletedGoals() async {
    await _useCase.clearCompletedGoals();
    completedGoals = [];
    notifyListeners();
  }
}
