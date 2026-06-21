import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

/// Test double that records notification operations.
class RecordingGoalNotifications implements GoalNotifications {
  final List<GoalSet> scheduled = [];
  final List<GoalSet> actionWindowScheduled = [];
  final List<GoalSet> cancelled = [];
  final List<int> cancelledAi = [];
  int cancelAllCount = 0;

  @override
  Future<void> schedule({
    required GoalSet goal,
    required String notificationStyle,
    required String notificationFrequency,
    required int deadlineHours,
  }) async {
    scheduled.add(goal);
  }

  @override
  Future<void> scheduleActionWindow({
    required GoalSet goal,
    required DateTime reminderAt,
    required String notificationStyle,
  }) async {
    actionWindowScheduled.add(goal);
  }

  @override
  Future<void> cancelForGoal(GoalSet goal) async {
    cancelled.add(goal);
  }

  @override
  Future<void> cancelAiEncouragement(int goalId) async {
    cancelledAi.add(goalId);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }
}
