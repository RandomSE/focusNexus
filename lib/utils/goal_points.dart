import 'common_utils.dart';

/// Pure goal scoring used by [GoalsScreen] and unit tests.
class GoalPoints {
  GoalPoints._();

  static const int basePoints = 5;

  static int calculatePointsFromTemplate({
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

    final double adjusted = rawScore * multiplier;
    return roundUpToNearestFive(adjusted);
  }

  /// Bonus reward when completing goals on the same calendar day.
  static int computeDailyCompletionReward(int amount, int completionCountToday) {
    double reward = amount.toDouble();

    if (completionCountToday == 1) {
      reward = amount * 2 + 100;
    } else if (completionCountToday <= 5) {
      reward = amount * 1.5 + 20;
    } else if (completionCountToday <= 10) {
      reward = amount * 1.25 + 5;
    }

    return roundUpToNearestFive(reward);
  }

  static int roundUpToNearestFive(double value) {
    return ((value + 4) ~/ 5) * 5;
  }
}
