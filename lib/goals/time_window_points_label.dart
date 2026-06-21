import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/goal_points.dart';

/// Window length used for time-window point multipliers.
Duration? goalActionWindowDuration(GoalSet goal) {
  final start = parseGoalDateTime(goal.actionWindowStart);
  final end = parseGoalDateTime(goal.actionWindowEnd);
  if (start == null || end == null) return null;
  return end.difference(start);
}

double timeWindowPointsMultiplier(Duration windowDuration) =>
    windowDuration <= strictWindowMaxDuration ? 2.0 : 1.5;

String timeWindowMultiplierLabel(Duration windowDuration) {
  final mult = timeWindowPointsMultiplier(windowDuration);
  return mult == 2.0 ? '2× strict slot' : '1.5× time slot';
}

int previewTimeWindowPoints({
  required String complexity,
  required String effort,
  required String motivation,
  required String time,
  required String steps,
  required Duration windowDuration,
}) {
  return GoalPoints.calculateTimeWindowPoints(
    complexity: complexity,
    effort: effort,
    motivation: motivation,
    time: time,
    steps: steps,
    windowDuration: windowDuration,
  );
}

/// Points line for list tiles and detail views, including multiplier context.
String timeWindowGoalPointsLabel(GoalSet goal) {
  final duration = goalActionWindowDuration(goal);
  if (duration == null) {
    return '${goal.points} pts';
  }
  return '${goal.points} pts (${timeWindowMultiplierLabel(duration)})';
}
