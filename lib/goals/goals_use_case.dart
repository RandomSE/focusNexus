import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/completed_today_record.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/goals/goals_mutation_plan.dart';
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

  GoalsCreatePlan planCreateGoal({
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
    required List<GoalSet> activeSnapshot,
  }) {
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
    return GoalsCreatePlan(
      goal: goal,
      activeGoals: [...activeSnapshot, goal],
      deadlineHours: deadlineHours,
    );
  }

  Future<void> persistCreatePlan(GoalsCreatePlan plan) async {
    await _goals.writeActiveGoals(plan.activeGoals);
    unawaited(_scheduleNotificationsIfNeeded(plan.goal, plan.deadlineHours));
    unawaited(_recordGoalsCreated(count: 1));
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
    List<GoalSet>? activeSnapshot,
  }) async {
    final plan = planCreateGoal(
      title: title,
      category: category,
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      deadlineHours: deadlineHours,
      anchor: anchor,
      goalId: goalId,
      activeSnapshot: activeSnapshot ?? await _goals.readActiveGoals(),
    );
    await persistCreatePlan(plan);
    return plan.goal;
  }

  GoalsBatchCreatePlan planCreateGoals({
    required List<CreateGoalInput> inputs,
    required DateTime anchor,
    required List<GoalSet> activeSnapshot,
  }) {
    if (inputs.isEmpty) {
      return GoalsBatchCreatePlan(
        newGoals: const [],
        activeGoals: activeSnapshot,
        deadlineHoursByGoal: const {},
      );
    }

    final newGoals = <GoalSet>[];
    final deadlineHoursByGoal = <GoalSet, int>{};

    for (final input in inputs) {
      final id = input.goalId ?? GoalNotifier.generateGoalId(input.title);
      final deadline = _formatDeadline(
        hours: input.deadlineHours,
        anchor: anchor,
      );
      final goal = _buildGoal(
        title: input.title,
        category: input.category,
        complexity: input.complexity,
        effort: input.effort,
        motivation: input.motivation,
        time: input.time,
        steps: input.steps,
        deadline: deadline,
        goalId: id,
      );
      newGoals.add(goal);
      deadlineHoursByGoal[goal] = input.deadlineHours;
    }

    return GoalsBatchCreatePlan(
      newGoals: newGoals,
      activeGoals: [...activeSnapshot, ...newGoals],
      deadlineHoursByGoal: deadlineHoursByGoal,
    );
  }

  Future<void> persistBatchCreatePlan(GoalsBatchCreatePlan plan) async {
    if (plan.newGoals.isEmpty) return;
    await _goals.writeActiveGoals(plan.activeGoals);
    unawaited(_recordGoalsCreated(count: plan.newGoals.length));

    if (_settings.notificationsEnabled && !_settings.pauseGoals) {
      unawaited(
        Future.wait(
          plan.newGoals.map(
            (goal) => _scheduleNotificationsIfNeeded(
              goal,
              plan.deadlineHoursByGoal[goal] ?? 0,
            ),
          ),
        ),
      );
    }
  }

  /// Creates many goals with one storage write; schedules reminders in the background.
  Future<List<GoalSet>> createGoals({
    required List<CreateGoalInput> inputs,
    required DateTime anchor,
    List<GoalSet>? activeSnapshot,
  }) async {
    if (inputs.isEmpty) return const [];

    final plan = planCreateGoals(
      inputs: inputs,
      anchor: anchor,
      activeSnapshot: activeSnapshot ?? await _goals.readActiveGoals(),
    );
    await persistBatchCreatePlan(plan);
    return plan.newGoals;
  }

  Future<StepProgressResult?> incrementStepProgress(
    int goalId, {
    List<GoalSet>? activeSnapshot,
    List<GoalSet>? completedSnapshot,
    int? goalsCompletedTodayBefore,
  }) async {
    final active = activeSnapshot != null
        ? List<GoalSet>.from(activeSnapshot)
        : await _goals.readActiveGoals();
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
      final before = goalsCompletedTodayBefore ??
          await _readGoalsCompletedTodayCount();
      final plan = planCompleteGoal(
        goalId,
        activeSnapshot: active,
        completedSnapshot:
            completedSnapshot ?? await _goals.readCompletedGoals(),
        goalsCompletedTodayBefore: before,
      );
      if (plan == null) return null;
      await persistCompletePlan(plan);
      return StepProgressResult(completed: plan.result);
    }
    return const StepProgressResult();
  }

  GoalsCompletePlan? planCompleteGoal(
    int goalId, {
    required List<GoalSet> activeSnapshot,
    required List<GoalSet> completedSnapshot,
    required int goalsCompletedTodayBefore,
  }) {
    final active = List<GoalSet>.from(activeSnapshot);
    final index = active.indexWhere((g) => g.goalId == goalId);
    if (index < 0) return null;

    final goal = active.removeAt(index);
    final completed = [...completedSnapshot, goal];
    final todayCount = goalsCompletedTodayBefore + 1;
    final pointsAwarded = GoalPoints.computeDailyCompletionReward(
      goal.points,
      todayCount,
    );

    return GoalsCompletePlan(
      result: CompleteGoalResult(
        goal: goal,
        pointsAwarded: pointsAwarded,
        goalsCompletedToday: todayCount,
      ),
      activeGoals: active,
      completedGoals: completed,
      goal: goal,
      pointsDelta: pointsAwarded,
      goalsCompletedTodayCount: todayCount,
    );
  }

  Future<void> persistCompletePlan(
    GoalsCompletePlan plan, {
    bool optimisticCacheCredit = false,
  }) {
    return _persistCompletePlanInBackground(
      plan,
      optimisticCacheCredit: optimisticCacheCredit,
    );
  }

  Future<void> _persistCompletePlanInBackground(
    GoalsCompletePlan plan, {
    required bool optimisticCacheCredit,
  }) async {
    unawaited(_notifications.cancelForGoal(plan.goal));
    await Future.wait([
      _goals.writeCompletedGoals(plan.completedGoals),
      _goals.writeActiveGoals(plan.activeGoals),
      _persistCompletionPoints(
        goalsCompletedTodayCount: plan.goalsCompletedTodayCount,
        pointsDeltaToAdd: plan.pointsDelta,
        optimisticCacheCredit: optimisticCacheCredit,
      ),
    ]);
    unawaited(_recordGoalCompleted(plan.goal));
  }

  Future<CompleteGoalResult?> completeGoal(
    int goalId, {
    List<GoalSet>? activeSnapshot,
    List<GoalSet>? completedSnapshot,
    int? goalsCompletedTodayBefore,
  }) async {
    final plan = planCompleteGoal(
      goalId,
      activeSnapshot: activeSnapshot ?? await _goals.readActiveGoals(),
      completedSnapshot: completedSnapshot ?? await _goals.readCompletedGoals(),
      goalsCompletedTodayBefore:
          goalsCompletedTodayBefore ??
          await _readGoalsCompletedTodayCount(),
    );
    if (plan == null) return null;
    await persistCompletePlan(plan);
    return plan.result;
  }

  Future<void> persistActiveGoals(List<GoalSet> active) =>
      _goals.writeActiveGoals(active);

  Future<void> cancelAiEncouragementForGoal(int goalId) =>
      _notifications.cancelAiEncouragement(goalId);

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

  Future<void> _persistCompletionPoints({
    required int goalsCompletedTodayCount,
    required int pointsDeltaToAdd,
    required bool optimisticCacheCredit,
  }) async {
    final today = DateFormat('dd MM yyyy').format(DateTime.now());
    await _goals.writeCompletedToday(
      today: today,
      count: goalsCompletedTodayCount,
    );
    if (pointsDeltaToAdd <= 0) return;
    if (optimisticCacheCredit) {
      await _points.persistCachedBalance();
      return;
    }
    await _points.add(pointsDeltaToAdd);
  }

  Future<void> _recordGoalsCreated({required int count}) async {
    if (count <= 0) return;
    await Future.wait([
      _streaks.incrementBy('totalGoalsCreated', count),
      _streaks.incrementBy('totalGoalsActive', count),
    ]);
  }

  Future<void> _recordGoalCompleted(GoalSet goal) async {
    await Future.wait([
      _streaks.decrement('totalGoalsActive'),
      _streaks.increment('totalGoalsCompleted'),
    ]);
    await _streaks.checkOrAddDate();
    await _streaks.updateCategoryCompletionStats(goal.category);
    await _streaks.updateGoalAchievementStats(goal);
  }

  /// One-time backfill of per-category counters from stored completed goals.
  Future<void> backfillCategoryAchievementStats() async {
    final completed = await _goals.readCompletedGoals();
    await _streaks.backfillCategoryStatsFromGoals(completed);
  }
}

class CreateGoalInput {
  const CreateGoalInput({
    required this.title,
    required this.category,
    required this.complexity,
    required this.effort,
    required this.motivation,
    required this.time,
    required this.steps,
    required this.deadlineHours,
    this.goalId,
  });

  final String title;
  final String category;
  final String complexity;
  final String effort;
  final String motivation;
  final String time;
  final String steps;
  final int deadlineHours;
  final int? goalId;
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
