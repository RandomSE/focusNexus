import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/completed_today_record.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/utils/goal_points.dart';
import 'package:focusNexus/utils/notifier.dart';

/// Domain orchestration for goals: persistence, points, streaks, notifications.
class GoalsUseCase {
  GoalsUseCase({
    required GoalsRepository goals,
    required PointsRepository points,
    required AchievementStreakService streaks,
    required AppSettings settings,
    GoalNotifications? notifications,
    DateFormat? deadlineFormat,
  })  : _goals = goals,
        _points = points,
        _streaks = streaks,
        _settings = settings,
        _notifications = notifications ?? const GoalNotifierNotifications(),
        deadlineFormat = deadlineFormat ?? DateFormat('dd MMMM yyyy HH:mm');

  final GoalsRepository _goals;
  final PointsRepository _points;
  final AchievementStreakService _streaks;
  final AppSettings _settings;
  final GoalNotifications _notifications;
  final DateFormat deadlineFormat;

  static const String noDeadlineLabel = 'no deadline';

  Future<GoalsSnapshot> load({DateTime? now}) async {
    var active = await _goals.readActiveGoals();
    final completed = await _goals.readCompletedGoals();
    final goalsCompletedToday = await _readGoalsCompletedTodayCount();

    if (!await _goals.areDeadlinesPaused()) {
      active = await _removeExpiredGoals(active, now: now ?? DateTime.now());
    }

    return GoalsSnapshot(
      active: active,
      completed: completed,
      goalsCompletedToday: goalsCompletedToday,
    );
  }

  Future<int> _readGoalsCompletedTodayCount() async {
    final today = DateFormat('dd MM yyyy').format(DateTime.now());
    final stored = await _goals.readCompletedTodayRaw();
    final record = CompletedTodayRecord.fromStorage(stored);
    return record.dateKey == today ? record.count : 0;
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
    int? goalId,
  }) async {
    final id = goalId ?? GoalNotifier.generateGoalId(title);
    final deadline = _formatDeadline(hours: deadlineHours, anchor: anchor);
    final goal = _buildGoal(
      title: title,
      category: category,
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      deadline: deadline,
      goalId: id,
    );

    final active = [...await _goals.readActiveGoals(), goal];
    await _goals.writeActiveGoals(active);
    await _scheduleNotificationsIfNeeded(goal, deadlineHours);
    await _streaks.increment('totalGoalsCreated');
    await _streaks.increment('totalGoalsActive');
    return goal;
  }

  Future<StepProgressResult?> incrementStepProgress(int goalId) async {
    final active = await _goals.readActiveGoals();
    final index = active.indexWhere((g) => g.goalId == goalId);
    if (index < 0) return null;

    await _notifications.cancelAiEncouragement(goalId);
    final goal = active[index];
    final maxSteps = goal.steps > 0 ? goal.steps : 1;
    if (goal.stepProgress >= maxSteps) return null;

    final updated = goal.copyWith(stepProgress: goal.stepProgress + 1);
    active[index] = updated;
    await _goals.writeActiveGoals(active);

    if (updated.stepProgress >= maxSteps) {
      return StepProgressResult(completed: await completeGoal(goalId));
    }
    return const StepProgressResult();
  }

  Future<CompleteGoalResult?> completeGoal(int goalId) async {
    var active = await _goals.readActiveGoals();
    final index = active.indexWhere((g) => g.goalId == goalId);
    if (index < 0) return null;

    final goal = active.removeAt(index);
    await _notifications.cancelForGoal(goal);

    final completed = [...await _goals.readCompletedGoals(), goal];
    await _goals.writeCompletedGoals(completed);
    await _goals.writeActiveGoals(active);

    final pointsAwarded = await _awardCompletionPoints(goal.points);
    await _streaks.decrement('totalGoalsActive');
    await _streaks.increment('totalGoalsCompleted');
    await _streaks.checkOrAddDate();
    await _streaks.updateGoalAchievementStats(goal);

    final goalsCompletedToday = await _readGoalsCompletedTodayCount();

    return CompleteGoalResult(
      goal: goal,
      pointsAwarded: pointsAwarded,
      goalsCompletedToday: goalsCompletedToday,
    );
  }

  Future<void> removeGoal(int goalId) async {
    var active = await _goals.readActiveGoals();
    final index = active.indexWhere((g) => g.goalId == goalId);
    if (index < 0) return;

    await _notifications.cancelForGoal(active[index]);
    active.removeAt(index);
    await _goals.writeActiveGoals(active);
    await _streaks.decrement('totalGoalsActive');
  }

  Future<void> removeCompletedGoal(int goalId) async {
    var completed = await _goals.readCompletedGoals();
    completed.removeWhere((g) => g.goalId == goalId);
    await _goals.writeCompletedGoals(completed);
  }

  /// Clears active goals without per-goal notification cancel (then cancels all).
  Future<void> clearActiveGoals() async {
    final count = (await _goals.readActiveGoals()).length;
    if (count == 0) {
      await _notifications.cancelAll();
      await _streaks.setInt('totalGoalsActive', 0);
      return;
    }

    for (var i = 0; i < count; i++) {
      await _removeActiveWithoutNotificationCancel();
    }
    await _notifications.cancelAll();
    await _streaks.setInt('totalGoalsActive', 0);
  }

  Future<void> clearCompletedGoals() async {
    while ((await _goals.readCompletedGoals()).isNotEmpty) {
      final completed = await _goals.readCompletedGoals();
      completed.removeAt(0);
      await _goals.writeCompletedGoals(completed);
    }
  }

  Future<void> _removeActiveWithoutNotificationCancel() async {
    var active = await _goals.readActiveGoals();
    if (active.isEmpty) return;
    active.removeAt(0);
    await _goals.writeActiveGoals(active);
    await _streaks.decrement('totalGoalsActive');
  }

  Future<List<GoalSet>> _removeExpiredGoals(
    List<GoalSet> active, {
    required DateTime now,
  }) async {
    var changed = false;
    final kept = <GoalSet>[];

    for (final goal in active) {
      final deadlineStr = goal.deadline.trim();
      if (deadlineStr.isEmpty) {
        kept.add(goal);
        continue;
      }
      try {
        final parsed = deadlineFormat.parseStrict(deadlineStr);
        if (parsed.isAfter(now)) {
          kept.add(goal);
        } else {
          changed = true;
          await _notifications.cancelForGoal(goal);
          await _streaks.decrement('totalGoalsActive');
        }
      } catch (_) {
        kept.add(goal);
      }
    }

    if (changed) {
      await _goals.writeActiveGoals(kept);
      return kept;
    }
    return active;
  }

  String _formatDeadline({required int hours, required DateTime anchor}) {
    if (hours <= 0) return noDeadlineLabel;
    return deadlineFormat.format(anchor.add(Duration(hours: hours)));
  }

  GoalSet _buildGoal({
    required String title,
    required String category,
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required String deadline,
    required int goalId,
  }) {
    final timeVal = int.tryParse(time) ?? 0;
    final stepsVal = int.tryParse(steps) ?? 0;
    return GoalSet(
      title: title,
      category: category,
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: timeVal,
      deadline: deadline,
      steps: stepsVal,
      points: GoalPoints.calculatePointsFromTemplate(
        complexity: complexity,
        effort: effort,
        motivation: motivation,
        time: time,
        steps: steps,
        deadline: deadline,
      ),
      stepProgress: 0,
      goalId: goalId,
    );
  }

  Future<void> _scheduleNotificationsIfNeeded(
    GoalSet goal,
    int deadlineHours,
  ) async {
    if (!_settings.notificationsEnabled ||
        deadlineHours <= 0 ||
        _settings.pauseGoals) {
      debugPrint(
        'Notifications not enabled — skipping goal check scheduling',
      );
      return;
    }
    await _notifications.schedule(
      goal: goal,
      notificationStyle: _settings.notificationStyle,
      notificationFrequency: _settings.notificationFrequency,
      deadlineHours: deadlineHours,
    );
  }

  Future<int> _awardCompletionPoints(int basePoints) async {
    final today = DateFormat('dd MM yyyy').format(DateTime.now());
    final count = await _goals.nextCompletedTodayCount(today);
    await _goals.writeCompletedToday(today: today, count: count);
    final totalAmount = GoalPoints.computeDailyCompletionReward(
      basePoints,
      count,
    );
    final balance = await _points.readBalance();
    await _points.writeBalance(balance + totalAmount);
    return totalAmount;
  }
}

class GoalsSnapshot {
  const GoalsSnapshot({
    required this.active,
    required this.completed,
    required this.goalsCompletedToday,
  });

  final List<GoalSet> active;
  final List<GoalSet> completed;
  final int goalsCompletedToday;
}

class CompleteGoalResult {
  const CompleteGoalResult({
    required this.goal,
    required this.pointsAwarded,
    required this.goalsCompletedToday,
  });

  final GoalSet goal;
  final int pointsAwarded;
  final int goalsCompletedToday;
}

class StepProgressResult {
  const StepProgressResult({this.completed});

  final CompleteGoalResult? completed;
}
