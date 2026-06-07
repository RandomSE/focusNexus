import 'package:focusNexus/goals/goals_use_case.dart';

/// User-facing deadline text for goal list rows and details.
String goalDeadlineLabel(String deadline) {
  final trimmed = deadline.trim();
  if (trimmed.isEmpty) return GoalsUseCase.noDeadlineLabel;
  return trimmed;
}
