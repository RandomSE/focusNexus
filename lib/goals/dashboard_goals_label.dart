/// Dashboard Goals button label including active count when non-zero.
String dashboardGoalsButtonLabel(int activeGoals) {
  if (activeGoals <= 0) return 'Goals';
  return 'Goals ($activeGoals)';
}

/// Shown under points / on onboarding only when at least one goal is in slot.
String? dashboardInSlotLine(int goalsInSlotNow) {
  if (goalsInSlotNow <= 0) return null;
  if (goalsInSlotNow == 1) return '1 in slot now';
  return '$goalsInSlotNow in slot now';
}
