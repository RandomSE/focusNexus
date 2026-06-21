import 'package:focusNexus/goals/goals_use_case.dart';

/// User-facing deadline text for goal list rows and details.
String goalDeadlineLabel(String deadline) {
  final trimmed = deadline.trim();
  if (trimmed.isEmpty) return GoalsUseCase.noDeadlineLabel;
  return trimmed;
}

/// User-facing completion timestamp for completed goal rows and details.
String goalCompletedLabel(String completedAt) {
  final trimmed = completedAt.trim();
  if (trimmed.isEmpty) return 'completion date unknown';
  return trimmed;
}
