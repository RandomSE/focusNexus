/// Pure achievement progress calculations (storage-agnostic).
class AchievementProgress {
  AchievementProgress._();

  static double percentComplete(int currentRepetitions, int repetitionsNeeded) {
    if (repetitionsNeeded <= 0) return 0;
    final raw = (currentRepetitions / repetitionsNeeded) * 100;
    final capped = raw > 100 ? 100.0 : raw;
    return double.parse(capped.toStringAsFixed(1));
  }

  /// Progress shown in UI — never above 100%; completed achievements read as 100%.
  static double displayPercent({
    required double progress,
    required bool isCompleted,
  }) {
    if (isCompleted) return 100.0;
    return progress.clamp(0.0, 100.0);
  }

  /// Streak-style achievements must not drop below 100% once reached.
  static bool shouldBlockProgressDecrease(double existingProgress, double newProgress) {
    return existingProgress >= 100 && newProgress <= existingProgress;
  }

  static int parsePointsFromReward(String reward) {
    return int.tryParse(reward.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}
