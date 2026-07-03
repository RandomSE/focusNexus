/// Dashboard Goals button label including active count and in-slot summary.
String dashboardGoalsButtonLabel(
  int activeGoals, {
  int goalsInSlotNow = 0,
}) {
  if (activeGoals <= 0) return 'Goals';
  final base = 'Goals ($activeGoals)';
  if (goalsInSlotNow <= 0) return base;
  if (goalsInSlotNow == 1) return '$base · 1 in slot now';
  return '$base · $goalsInSlotNow in slot now';
}

/// Shown on the Goals button when at least one goal is in slot (see [dashboardGoalsButtonLabel]).
String? dashboardInSlotLine(int goalsInSlotNow) {
  if (goalsInSlotNow <= 0) return null;
  if (goalsInSlotNow == 1) return '1 in slot now';
  return '$goalsInSlotNow in slot now';
}
