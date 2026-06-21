import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

/// User-facing label for a time-window goal row.
String goalTimeWindowLabel(GoalSet goal) {
  final start = parseGoalDateTime(goal.actionWindowStart);
  final end = parseGoalDateTime(goal.actionWindowEnd);
  if (start == null || end == null) return 'Window unknown';
  return 'Slot: ${_short(start)} – ${_short(end)}';
}

String _short(DateTime value) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '${value.day}/${value.month} $h:$m';
}
