import 'common_utils.dart';

/// Split daily completion award: effort term + small momentum flat.
class DailyCompletionBreakdown {
  const DailyCompletionBreakdown({
    required this.effortAward,
    required this.momentumBonus,
    required this.total,
  });

  /// `amount * dailyMultiplier` before final rounding.
  final double effortAward;

  /// Tier flat momentum bonus (0..15), independent of amount.
  final int momentumBonus;

  /// [GoalPoints.roundUpToNearestFive] of effort + momentum.
  final int total;
}

/// Pure goal scoring used by [GoalsScreen] and unit tests.
class GoalPoints {
  GoalPoints._();

  static const int basePoints = 5;

  /// Unrounded template score (before [roundUpToNearestFive]).
  ///
  /// Used by time-window scoring so the window multiplier does not ceil an
  /// already-rounded base (single round at the end of the TW chain).
  static double rawPointsFromTemplate({
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required String deadline,
  }) {
    final int timeVal = int.tryParse(time) ?? 0;
    final int stepsVal = int.tryParse(steps) ?? 0;

    final int complexityScore = CommonUtils.scoreFromLevel(complexity);
    final int effortScore = CommonUtils.scoreFromLevel(effort);
    final int motivationScore = CommonUtils.scoreFromLevel(motivation);
    final int timeScore = CommonUtils.scoreFromTime(timeVal);
    final int stepScore = CommonUtils.scoreFromSteps(stepsVal);
    final int deadlineBonus =
        (deadline.isNotEmpty && deadline != 'no deadline') ? 2 : 0;

    final int additive = 1 +
        complexityScore +
        effortScore +
        motivationScore +
        timeScore +
        stepScore +
        deadlineBonus;
    final int rawScore = basePoints * additive;

    final List<String> levels = [complexity, effort, motivation];
    final int highCount =
        levels.where((l) => l.toLowerCase() == 'high').length;

    final double multiplier = switch (highCount) {
      3 => 2.0,
      2 => 1.5,
      1 => 1.25,
      _ => 1.0,
    };

    return rawScore * multiplier;
  }

  static int calculatePointsFromTemplate({
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required String deadline,
  }) {
    return roundUpToNearestFive(
      rawPointsFromTemplate(
        complexity: complexity,
        effort: effort,
        motivation: motivation,
        time: time,
        steps: steps,
        deadline: deadline,
      ),
    );
  }

  /// Daily tier: effort multiplier and flat momentum (Option 1 rebalance).
  static ({double multiplier, int momentum}) dailyCompletionTier(
    int completionCountToday,
  ) {
    if (completionCountToday == 1) {
      return (multiplier: 1.35, momentum: 10);
    }
    if (completionCountToday <= 5) {
      return (multiplier: 1.20, momentum: 8);
    }
    if (completionCountToday <= 10) {
      return (multiplier: 1.10, momentum: 5);
    }
    return (multiplier: 1.0, momentum: 0);
  }

  /// Effort x multiplier + small momentum flat; one final round on the sum.
  static DailyCompletionBreakdown computeDailyCompletionBreakdown(
    int amount,
    int completionCountToday,
  ) {
    final tier = dailyCompletionTier(completionCountToday);
    final effortAward = amount * tier.multiplier;
    final momentumBonus = tier.momentum;
    final total = roundUpToNearestFive(effortAward + momentumBonus);
    return DailyCompletionBreakdown(
      effortAward: effortAward,
      momentumBonus: momentumBonus,
      total: total,
    );
  }

  /// Wallet award when completing a goal (post-daily Option 1 total).
  static int computeDailyCompletionReward(
    int amount,
    int completionCountToday,
  ) =>
      computeDailyCompletionBreakdown(amount, completionCountToday).total;

  /// First-of-day complete award preview for create/detail UI.
  static int previewFirstOfDayAward(int storedPoints) =>
      computeDailyCompletionReward(storedPoints, 1);

  /// First-of-day split preview (effort + momentum).
  static DailyCompletionBreakdown previewFirstOfDayBreakdown(
    int storedPoints,
  ) =>
      computeDailyCompletionBreakdown(storedPoints, 1);

  static int roundUpToNearestFive(double value) {
    return ((value + 4) ~/ 5) * 5;
  }

  /// Time-slot goals: deadline scoring bonus + 1.5x (or 2x for <=3h windows).
  ///
  /// Multiplies the *unrounded* template base, then rounds once.
  static int calculateTimeWindowPoints({
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required Duration windowDuration,
  }) {
    final base = rawPointsFromTemplate(
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      // Time-slot goals are inherently deadline-bound; award deadline bonus.
      deadline: 'slot',
    );
    final multiplier = windowDuration <= const Duration(hours: 3) ? 2.0 : 1.5;
    return roundUpToNearestFive(base * multiplier);
  }
}
