import 'package:focusNexus/goals/goal_deadline_label.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/goals/time_window_points_label.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

/// User-facing label for a time-window goal row.
String goalTimeWindowLabel(GoalSet goal) {
  final start = parseGoalDateTime(goal.actionWindowStart);
  final end = parseGoalDateTime(goal.actionWindowEnd);
  if (start == null || end == null) return 'Window unknown';
  return 'Slot: ${_short(start)} - ${_short(end)}';
}

/// Subtitle lines for a goal list row (slot, status, repeat cadence).
List<String> goalListSubtitleLines({
  required GoalSet goal,
  required String selectedStatusFilter,
  required DateTime now,
  RepeatRule? repeatRule,
}) {
  final steps = goal.steps > 0 ? goal.steps : 1;
  final isTimeWindow = isTimeWindowGoal(goal);
  final lines = <String>[];

  if (isTimeWindow) {
    lines.add(timeWindowGoalPointsLabel(goal));
    lines.add(goalTimeWindowLabel(goal));
    if (selectedStatusFilter == 'Active') {
      lines.add(
        isActionWindowActive(goal, now) ? 'In slot now' : 'Outside slot',
      );
    }
    if (goal.repeatSeriesId != 0) {
      lines.add(
        repeatRule != null && repeatRule.enabled
            ? summarizeRepeatRule(repeatRule)
            : 'Repeats',
      );
    }
  } else {
    final dateLabel = selectedStatusFilter == 'Completed'
        ? 'Completed ${goalCompletedLabel(goal.completedAt)}'
        : goalDeadlineLabel(goal.deadline);
    lines.add('${goal.points} pts · $dateLabel');
  }

  if (selectedStatusFilter == 'Active' && steps > 1) {
    lines.add('Step ${goal.stepProgress.clamp(0, steps)}/$steps');
  }
  return lines;
}

/// Single announcement for a goal list row (title, status, and actions context).
String goalTileSemanticsLabel({
  required GoalSet goal,
  required String selectedStatusFilter,
  required DateTime now,
  RepeatRule? repeatRule,
}) {
  final parts = <String>[goal.title];
  parts.addAll(
    goalListSubtitleLines(
      goal: goal,
      selectedStatusFilter: selectedStatusFilter,
      now: now,
      repeatRule: repeatRule,
    ),
  );
  if (selectedStatusFilter == 'Active') {
    parts.add('Tap for goal details');
  }
  return parts.join('. ');
}

String _short(DateTime value) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '${value.day}/${value.month} $h:$m';
}
