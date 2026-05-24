/// Pure achievement progress calculations (storage-agnostic).
class AchievementProgress {
  AchievementProgress._();

  static double percentComplete(int currentRepetitions, int repetitionsNeeded) {
    if (repetitionsNeeded <= 0) return 0;
    return double.parse(
      ((currentRepetitions / repetitionsNeeded) * 100).toStringAsFixed(1),
    );
  }

  /// Streak-style achievements must not drop below 100% once reached.
  static bool shouldBlockProgressDecrease(double existingProgress, double newProgress) {
    return existingProgress >= 100 && newProgress <= existingProgress;
  }

  static int parsePointsFromReward(String reward) {
    return int.tryParse(reward.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}
