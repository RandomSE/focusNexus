import 'package:focusNexus/utils/goal_points.dart';

String _formatEffort(double effortAward) {
  if (effortAward == effortAward.roundToDouble()) {
    return effortAward.round().toString();
  }
  final trimmed = effortAward.toStringAsFixed(2);
  if (trimmed.endsWith('0')) {
    return effortAward.toStringAsFixed(1);
  }
  return trimmed;
}

String firstOfDaySplitPreview(int storedPoints) {
  final b = GoalPoints.previewFirstOfDayBreakdown(storedPoints);
  final effortText = _formatEffort(b.effortAward);
  final preRound = b.effortAward + b.momentumBonus;
  final preRoundText = _formatEffort(preRound);
  final base =
      '~${b.total} if first today (effort $effortText + momentum ${b.momentumBonus}';
  // Wallet award rounds the sum to the nearest 5; show that when it matters.
  if (preRound == b.total) {
    return '$base)';
  }
  return '$base = $preRoundText, rounded to ${b.total})';
}

/// Active-goal points line: stored (pre-daily) plus first-of-day award preview.
String activeGoalPointsWithDailyPreview(int storedPoints) {
  return '$storedPoints pts (${firstOfDaySplitPreview(storedPoints)})';
}

/// Create-form reward line for time-window goals.
String timeWindowCreateRewardLabel({
  required int storedPoints,
  required String multiplierLabel,
}) {
  return 'Reward: $storedPoints pts ($multiplierLabel); '
      '${firstOfDaySplitPreview(storedPoints)}';
}

/// Detail-dialog points block for active goals.
String activeGoalDetailPointsLabel(int storedPoints) {
  return 'Points: $storedPoints (${firstOfDaySplitPreview(storedPoints)})';
}

/// Detail-dialog points block for completed goals (already awarded).
String completedGoalDetailPointsLabel(int awardedPoints) =>
    'Points: $awardedPoints (awarded on complete)';
