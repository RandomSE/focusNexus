import 'dart:async';

import 'package:focusNexus/goals/goal_kind.dart';
import 'package:focusNexus/goals/goal_notifications.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_repeat_series.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/goal_points.dart';
import 'package:focusNexus/utils/notifier.dart';

class CreateTimeWindowGoalInput {
  const CreateTimeWindowGoalInput({
    required this.title,
    required this.category,
    required this.complexity,
    required this.effort,
    required this.motivation,
    required this.time,
    required this.steps,
    required this.windowEndAt,
    required this.windowDuration,
    this.repeatRule = RepeatRule.none,
    this.templateName,
    this.goalId,
    this.seriesId,
  });

  final String title;
  final String category;
  final String complexity;
  final String effort;
  final String motivation;
  final String time;
  final String steps;
  final DateTime windowEndAt;
  final Duration windowDuration;
  final RepeatRule repeatRule;
  final String? templateName;
  final int? goalId;
  final int? seriesId;
}

/// Time-window goal creation, repeat series, and notification scheduling.
class GoalsTimeWindowService {
  GoalsTimeWindowService({
    required TimeWindowRepeatRepository repeats,
    required GoalNotifications notifications,
    required AppSettings settings,
  })  : _repeats = repeats,
        _notifications = notifications,
        _settings = settings;

  final TimeWindowRepeatRepository _repeats;
  final GoalNotifications _notifications;
  final AppSettings _settings;

  GoalSet buildGoal({
    required CreateTimeWindowGoalInput input,
    required DateTime now,
    required int goalId,
    required int repeatSeriesId,
    required ActionWindow window,
  }) {
    final stepsVal = int.tryParse(input.steps) ?? 1;
    return GoalSet(
      title: input.title,
      category: input.category,
      complexity: input.complexity,
      effort: input.effort,
      motivation: input.motivation,
      time: int.tryParse(input.time) ?? 0,
      deadline: '',
      steps: stepsVal,
      points: GoalPoints.calculateTimeWindowPoints(
        complexity: input.complexity,
        effort: input.effort,
        motivation: input.motivation,
        time: input.time,
        steps: input.steps,
        windowDuration: window.duration,
      ),
      stepProgress: 0,
      goalId: goalId,
      goalKind: GoalKind.timeWindow,
      actionWindowStart: formatGoalDateTime(window.start),
      actionWindowEnd: formatGoalDateTime(window.end),
      repeatSeriesId: repeatSeriesId,
    );
  }

  GoalRepeatSeries buildSeries({
    required CreateTimeWindowGoalInput input,
    required int seriesId,
    required DateTime anchorEndAt,
  }) {
    return GoalRepeatSeries(
      seriesId: seriesId,
      isActive: input.repeatRule.enabled,
      repeatRule: input.repeatRule,
      windowDuration: input.windowDuration,
      anchorEndAt: formatGoalDateTime(anchorEndAt),
      templateName: input.templateName,
      title: input.title,
      category: input.category,
      complexity: input.complexity,
      effort: input.effort,
      motivation: input.motivation,
      time: int.tryParse(input.time) ?? 0,
      steps: int.tryParse(input.steps) ?? 1,
    );
  }

  Future<({GoalSet goal, GoalRepeatSeries? series})> createGoal({
    required CreateTimeWindowGoalInput input,
    required DateTime now,
    required List<GoalSet> activeSnapshot,
  }) async {
    final goalId = input.goalId ?? GoalNotifier.generateGoalId(input.title);
    final window = computeActionWindow(
      endAt: input.windowEndAt,
      duration: input.windowDuration,
      now: now,
    );

    GoalRepeatSeries? series;
    var repeatSeriesId = 0;
    if (input.repeatRule.enabled) {
      final seriesId = input.seriesId ?? GoalNotifier.generateGoalId(input.title);
      series = buildSeries(
        input: input,
        seriesId: seriesId,
        anchorEndAt: input.windowEndAt,
      ).copyWith(
        lastSpawnedWindowEnd: formatGoalDateTime(input.windowEndAt),
      );
      await _repeats.upsert(series);
      repeatSeriesId = seriesId;
    }

    final goal = buildGoal(
      input: input,
      now: now,
      goalId: goalId,
      repeatSeriesId: repeatSeriesId,
      window: window,
    );

    await _scheduleActionWindowNotifications(goal, window, now);
    return (goal: goal, series: series);
  }

  Future<void> _scheduleActionWindowNotifications(
    GoalSet goal,
    ActionWindow window,
    DateTime now,
  ) async {
    if (!_settings.notificationsEnabled || _settings.pauseGoals) return;
    final style = _settings.notificationStyle;
    final alreadyInSlot =
        !now.isBefore(window.start) && now.isBefore(window.end);

    if (window.start.isAfter(now)) {
      await _notifications.scheduleActionWindow(
        goal: goal,
        reminderAt: window.start,
        notificationStyle: style,
        isStartReminder: true,
      );
    }

    if (!alreadyInSlot &&
        window.end.difference(window.start) > longWindowReminderThreshold) {
      final closeReminder =
          window.end.subtract(longWindowReminderThreshold);
      if (closeReminder.isAfter(now)) {
        await _notifications.scheduleActionWindow(
          goal: goal,
          reminderAt: closeReminder,
          notificationStyle: style,
          isStartReminder: false,
        );
      }
    }
  }

  Future<GoalSet?> spawnNextFromSeries({
    required GoalRepeatSeries series,
    required DateTime after,
    required DateTime now,
    bool allowRematerializeCurrent = false,
  }) async {
    if (!series.isActive || !series.repeatRule.enabled) return null;
    final anchor = parseGoalDateTime(series.anchorEndAt);
    if (anchor == null) return null;
    final lastEnd = parseGoalDateTime(series.lastSpawnedWindowEnd) ?? anchor;

    if (allowRematerializeCurrent) {
      final containing = computeContainingWindowEnd(
        rule: series.repeatRule,
        anchorEndAt: anchor,
        duration: series.windowDuration,
        now: now,
      );
      if (containing != null) {
        return _materializeSeriesGoal(
          series: series,
          windowEnd: containing,
          now: now,
          lastSpawnedFloor: lastEnd,
        );
      }
    }

    var cursor = after.isAfter(lastEnd) ? after : lastEnd;
    for (var i = 0; i < 400; i++) {
      final nextEnd = computeNextWindowEnd(
        rule: series.repeatRule,
        anchorEndAt: anchor,
        after: cursor,
      );
      if (nextEnd == null) return null;
      if (!now.isBefore(nextEnd)) {
        cursor = nextEnd;
        continue;
      }

      final window = computeActionWindow(
        endAt: nextEnd,
        duration: series.windowDuration,
        now: now,
      );
      if (!window.start.isBefore(now.add(repeatSpawnLookahead))) {
        if (cursor.isAfter(lastEnd)) {
          await _repeats.upsert(
            series.copyWith(
              lastSpawnedWindowEnd: formatGoalDateTime(cursor),
            ),
          );
        }
        return null;
      }

      return _materializeSeriesGoal(
        series: series,
        windowEnd: nextEnd,
        now: now,
        lastSpawnedFloor: lastEnd,
      );
    }
    return null;
  }

  Future<GoalSet> _materializeSeriesGoal({
    required GoalRepeatSeries series,
    required DateTime windowEnd,
    required DateTime now,
    required DateTime lastSpawnedFloor,
  }) async {
    final window = computeActionWindow(
      endAt: windowEnd,
      duration: series.windowDuration,
      now: now,
    );
    final input = CreateTimeWindowGoalInput(
      title: series.title,
      category: series.category,
      complexity: series.complexity,
      effort: series.effort,
      motivation: series.motivation,
      time: series.time.toString(),
      steps: series.steps.toString(),
      windowEndAt: windowEnd,
      windowDuration: series.windowDuration,
      repeatRule: series.repeatRule,
      templateName: series.templateName,
      seriesId: series.seriesId,
    );
    final goalId = GoalNotifier.generateGoalId('${series.title}-$windowEnd');
    final goal = buildGoal(
      input: input,
      now: now,
      goalId: goalId,
      repeatSeriesId: series.seriesId,
      window: window,
    );
    await _scheduleActionWindowNotifications(goal, window, now);
    final lastSpawned = windowEnd.isAfter(lastSpawnedFloor)
        ? windowEnd
        : lastSpawnedFloor;
    await _repeats.upsert(
      series.copyWith(lastSpawnedWindowEnd: formatGoalDateTime(lastSpawned)),
    );
    return goal;
  }

  Future<List<GoalRepeatSeries>> readActiveSeries() => _repeats.readActive();

  Future<void> deactivateSeries(int seriesId) async {
    final series = await _repeats.readById(seriesId);
    if (series == null) return;
    await _repeats.upsert(series.copyWith(isActive: false));
  }

  /// Updates repeat schedule and refreshes the active instance window, if any.
  Future<({GoalRepeatSeries series, GoalSet? updatedGoal})> updateRepeatSeries({
    required GoalRepeatSeries series,
    required DateTime windowEndAt,
    required Duration windowDuration,
    required RepeatRule repeatRule,
    required DateTime now,
    required List<GoalSet> activeGoals,
  }) async {
    final updatedSeries = series.copyWith(
      repeatRule: repeatRule.copyWith(enabled: true),
      windowDuration: windowDuration,
      anchorEndAt: formatGoalDateTime(windowEndAt),
    );
    await _repeats.upsert(updatedSeries);

    final index =
        activeGoals.indexWhere((g) => g.repeatSeriesId == series.seriesId);
    if (index < 0) {
      return (series: updatedSeries, updatedGoal: null);
    }

    final goal = activeGoals[index];
    final window = computeActionWindow(
      endAt: windowEndAt,
      duration: windowDuration,
      now: now,
    );
    final updatedGoal = goal.copyWith(
      actionWindowStart: formatGoalDateTime(window.start),
      actionWindowEnd: formatGoalDateTime(window.end),
      points: GoalPoints.calculateTimeWindowPoints(
        complexity: goal.complexity,
        effort: goal.effort,
        motivation: goal.motivation,
        time: goal.time.toString(),
        steps: goal.steps.toString(),
        windowDuration: window.duration,
      ),
    );
    await _notifications.cancelForGoal(goal);
    await _scheduleActionWindowNotifications(updatedGoal, window, now);
    return (series: updatedSeries, updatedGoal: updatedGoal);
  }

  /// Updates a one-off (non-repeating) time-window goal instance.
  Future<GoalSet?> updateTimeWindowGoal({
    required GoalSet goal,
    required DateTime windowEndAt,
    required Duration windowDuration,
    required DateTime now,
  }) async {
    if (goal.repeatSeriesId != 0 || !isTimeWindowGoal(goal)) return null;
    if (windowDuration <= Duration.zero) return null;

    final window = computeActionWindow(
      endAt: windowEndAt,
      duration: windowDuration,
      now: now,
    );
    final updated = goal.copyWith(
      actionWindowStart: formatGoalDateTime(window.start),
      actionWindowEnd: formatGoalDateTime(window.end),
      points: GoalPoints.calculateTimeWindowPoints(
        complexity: goal.complexity,
        effort: goal.effort,
        motivation: goal.motivation,
        time: goal.time.toString(),
        steps: goal.steps.toString(),
        windowDuration: window.duration,
      ),
    );
    await _notifications.cancelForGoal(goal);
    await _scheduleActionWindowNotifications(updated, window, now);
    return updated;
  }

  /// Deactivates all active repeat series (used when user confirms on clear-active).
  Future<void> deactivateAllActiveSeries() async {
    final active = await _repeats.readActive();
    for (final series in active) {
      await _repeats.upsert(series.copyWith(isActive: false));
    }
  }

  Future<List<GoalSet>> spawnDueSeriesGoals({
    required List<GoalSet> active,
    required DateTime now,
  }) async {
    final activeSeries = await _repeats.readActive();
    if (activeSeries.isEmpty) return const [];

    final spawned = <GoalSet>[];
    final activeSeriesIds = active
        .where((g) => g.repeatSeriesId != 0)
        .map((g) => g.repeatSeriesId)
        .toSet();

    for (final series in activeSeries) {
      if (activeSeriesIds.contains(series.seriesId)) continue;
      final goal = await spawnNextFromSeries(
        series: series,
        after: now.subtract(const Duration(seconds: 1)),
        now: now,
        allowRematerializeCurrent: true,
      );
      if (goal != null) spawned.add(goal);
    }
    return spawned;
  }

  Future<({List<GoalSet> kept, List<GoalSet> expired})> expireTimeWindowGoals({
    required List<GoalSet> active,
    required DateTime now,
    required Future<void> Function(GoalSet goal) onExpire,
    required Future<GoalSet?> Function(GoalRepeatSeries series, GoalSet expired)
        spawnNext,
  }) async {
    final kept = <GoalSet>[];
    final expired = <GoalSet>[];

    for (final goal in active) {
      if (!isTimeWindowGoal(goal)) {
        kept.add(goal);
        continue;
      }
      final end = parseGoalDateTime(goal.actionWindowEnd);
      if (end == null || now.isBefore(end)) {
        kept.add(goal);
        continue;
      }
      expired.add(goal);
      await _notifications.cancelForGoal(goal);
      await onExpire(goal);

      if (goal.repeatSeriesId != 0) {
        final series = await _repeats.readById(goal.repeatSeriesId);
        if (series != null && series.isActive) {
          await _repeats.upsert(
            series.copyWith(
              lastSpawnedWindowEnd: goal.actionWindowEnd,
            ),
          );
          final next = await spawnNext(series, goal);
          if (next != null) kept.add(next);
        }
      }
    }

    return (kept: kept, expired: expired);
  }
}
