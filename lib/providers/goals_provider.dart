import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/goals/goals_time_window_service.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_repeat_series.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/providers/achievement_ready_toast_provider.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/repositories/points_repository.dart';

part 'goals_provider.g.dart';

/// In-memory goals lists for the goals screen.
class GoalsViewState {
  const GoalsViewState({
    this.activeGoals = const [],
    this.completedGoals = const [],
    this.goalsCompletedToday = 0,
  });

  final List<GoalSet> activeGoals;
  final List<GoalSet> completedGoals;
  final int goalsCompletedToday;

  GoalsViewState copyWith({
    List<GoalSet>? activeGoals,
    List<GoalSet>? completedGoals,
    int? goalsCompletedToday,
  }) {
    return GoalsViewState(
      activeGoals: activeGoals ?? this.activeGoals,
      completedGoals: completedGoals ?? this.completedGoals,
      goalsCompletedToday: goalsCompletedToday ?? this.goalsCompletedToday,
    );
  }
}

/// Goals UI state and optimistic mutations (persisted via [GoalsUseCase]).
@Riverpod(keepAlive: true)
class GoalsView extends _$GoalsView {
  late GoalsUseCase _useCase;
  late PointsRepository _points;

  @override
  GoalsViewState build() {
    final repos = ref.watch(appRepositoriesProvider);
    _useCase = repos.goalsUseCase;
    _points = repos.points;
    return const GoalsViewState();
  }

  GoalsUseCase get useCase => _useCase;

  Future<void> _persistAndRefreshAchievements(
    Future<Set<String>> trackingKeysFuture,
  ) async {
    var alive = true;
    ref.onDispose(() => alive = false);
    try {
      final keys = await trackingKeysFuture;
      if (!alive) return;
      if (keys.isEmpty) return;
      final newlyReady = await ref
          .read(achievementServiceProvider)
          .updateProgressForTrackingKeys(keys);
      if (!alive) return;
      if (newlyReady.isNotEmpty) {
        ref.read(achievementReadyToastQueueProvider.notifier).enqueueTitles(
              newlyReady.map((a) => a.title),
            );
      }
      ref.read(achievementsListRefreshProvider.notifier).bump();
    } catch (e, stack) {
      if (!alive) return;
      debugLog('Achievement progress refresh failed: $e\n$stack');
    }
  }
  Future<void> load({DateTime? now}) async {
    final snapshot = await _useCase.load(now: now);
    state = GoalsViewState(
      activeGoals: snapshot.active,
      completedGoals: snapshot.completed,
      goalsCompletedToday: snapshot.goalsCompletedToday,
    );
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
    final plan = _useCase.planCreateGoal(
      title: title,
      category: category,
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      deadlineHours: deadlineHours,
      anchor: anchor,
      activeSnapshot: state.activeGoals,
    );
    state = state.copyWith(activeGoals: plan.activeGoals);
    unawaited(_persistAndRefreshAchievements(_useCase.persistCreatePlan(plan)));
    return plan.goal;
  }

  Future<List<GoalSet>> createGoals({
    required List<CreateGoalInput> inputs,
    required DateTime anchor,
  }) async {
    final plan = _useCase.planCreateGoals(
      inputs: inputs,
      anchor: anchor,
      activeSnapshot: state.activeGoals,
    );
    if (plan.newGoals.isEmpty) return const [];
    state = state.copyWith(activeGoals: plan.activeGoals);
    unawaited(_persistAndRefreshAchievements(_useCase.persistBatchCreatePlan(plan)));
    return plan.newGoals;
  }

  /// Synchronous optimistic complete — UI should call this for tap handlers.
  CompleteGoalResult? completeGoalOptimistic(int goalId, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final plan = _useCase.planCompleteGoal(
      goalId,
      activeSnapshot: state.activeGoals,
      completedSnapshot: state.completedGoals,
      goalsCompletedTodayBefore: state.goalsCompletedToday,
      now: clock,
    );
    if (plan == null) return null;

    state = state.copyWith(
      activeGoals: plan.activeGoals,
      completedGoals: plan.completedGoals,
      goalsCompletedToday: plan.goalsCompletedTodayCount,
    );
    _points.creditBalance(plan.pointsDelta);
    unawaited(
      _persistAndRefreshAchievements(
        _useCase.persistCompletePlan(plan, optimisticCacheCredit: true),
      ),
    );
    return plan.result;
  }

  Future<CompleteGoalResult?> completeGoal(int goalId) async =>
      completeGoalOptimistic(goalId);

  Future<StepProgressResult?> incrementStepProgress(int goalId, {DateTime? now}) async {
    final index = state.activeGoals.indexWhere((g) => g.goalId == goalId);
    if (index < 0) return null;

    final goal = state.activeGoals[index];
    if (!isActionWindowActive(goal, now ?? DateTime.now())) return null;
    final maxSteps = goal.steps > 0 ? goal.steps : 1;
    if (goal.stepProgress >= maxSteps) return null;

    final updated = goal.copyWith(stepProgress: goal.stepProgress + 1);
    final nextActive = List<GoalSet>.from(state.activeGoals)..[index] = updated;

    if (updated.stepProgress >= maxSteps) {
      final plan = _useCase.planCompleteGoal(
        goalId,
        activeSnapshot: nextActive,
        completedSnapshot: state.completedGoals,
        goalsCompletedTodayBefore: state.goalsCompletedToday,
        now: now,
      );
      if (plan == null) return null;

      state = state.copyWith(
        activeGoals: plan.activeGoals,
        completedGoals: plan.completedGoals,
        goalsCompletedToday: plan.goalsCompletedTodayCount,
      );
      _points.creditBalance(plan.pointsDelta);
      unawaited(
        _persistAndRefreshAchievements(
          _useCase.persistCompletePlan(plan, optimisticCacheCredit: true),
        ),
      );
      return StepProgressResult(completed: plan.result);
    }

    state = state.copyWith(activeGoals: nextActive);
    unawaited(_useCase.persistActiveGoals(nextActive));
    unawaited(_useCase.cancelAiEncouragementForGoal(goalId));
    return const StepProgressResult();
  }

  Future<void> removeGoal(int goalId) async {
    await _useCase.removeGoal(goalId);
    state = state.copyWith(
      activeGoals: state.activeGoals.where((g) => g.goalId != goalId).toList(),
    );
  }

  Future<void> removeCompletedGoal(int goalId) async {
    await _useCase.removeCompletedGoal(goalId);
    state = state.copyWith(
      completedGoals:
          state.completedGoals.where((g) => g.goalId != goalId).toList(),
    );
  }

  Future<void> clearActiveGoals({bool cancelRepeatSeries = false}) async {
    await _useCase.clearActiveGoals(cancelRepeatSeries: cancelRepeatSeries);
    state = state.copyWith(activeGoals: const []);
  }

  bool get hasActiveGoalsWithRepeats =>
      _useCase.activeGoalsIncludeRepeats(state.activeGoals);

  Future<List<GoalRepeatSeries>> readActiveRepeatSeries() =>
      _useCase.readActiveRepeatSeries();

  Future<void> deactivateRepeatSeries(int seriesId) =>
      _useCase.deactivateRepeatSeries(seriesId);

  Future<void> deactivateAllRepeatingSchedules() =>
      _useCase.deactivateAllRepeatingSchedules();

  Future<GoalSet?> updateRepeatSeries({
    required int seriesId,
    required DateTime windowEndAt,
    required Duration windowDuration,
    required RepeatRule repeatRule,
    required DateTime now,
  }) async {
    final updated = await _useCase.updateRepeatSeries(
      seriesId: seriesId,
      windowEndAt: windowEndAt,
      windowDuration: windowDuration,
      repeatRule: repeatRule,
      now: now,
      activeSnapshot: state.activeGoals,
    );
    if (updated == null) return null;
    state = state.copyWith(
      activeGoals: state.activeGoals
          .map((g) => g.repeatSeriesId == seriesId ? updated : g)
          .toList(),
    );
    return updated;
  }

  Future<GoalSet> createTimeWindowGoal({
    required CreateTimeWindowGoalInput input,
    required DateTime now,
  }) async {
    final goal = await _useCase.createTimeWindowGoal(
      input: input,
      now: now,
      activeSnapshot: state.activeGoals,
    );
    state = state.copyWith(activeGoals: [...state.activeGoals, goal]);
    unawaited(
      _persistAndRefreshAchievements(
        _useCase.recordGoalsCreatedCounters(count: 1),
      ),
    );
    return goal;
  }

  Future<List<GoalSet>> createTimeWindowGoals({
    required List<CreateTimeWindowGoalInput> inputs,
    required DateTime now,
  }) async {
    final created = await _useCase.createTimeWindowGoals(
      inputs: inputs,
      now: now,
      activeSnapshot: state.activeGoals,
    );
    if (created.isEmpty) return const [];
    state = state.copyWith(activeGoals: [...state.activeGoals, ...created]);
    unawaited(
      _persistAndRefreshAchievements(
        _useCase.recordGoalsCreatedCounters(count: created.length),
      ),
    );
    return created;
  }

  Future<void> clearCompletedGoals() async {
    await _useCase.clearCompletedGoals();
    state = state.copyWith(completedGoals: const []);
  }
}

/// Stable alias used across the app (generated: [goalsViewProvider]).
final goalsProvider = goalsViewProvider;

/// Active repeat series keyed by id; refreshes when goals state changes.
final activeRepeatSeriesProvider =
    FutureProvider<Map<int, GoalRepeatSeries>>((ref) async {
      ref.watch(goalsProvider);
      final list =
          await ref.read(goalsProvider.notifier).readActiveRepeatSeries();
      return {for (final s in list) s.seriesId: s};
    });

/// Back-compat type name for the goals notifier.
typedef GoalsNotifier = GoalsView;
