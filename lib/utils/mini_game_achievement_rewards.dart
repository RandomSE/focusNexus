/// Mini-game achievement wallet claim scaling (rebalance 2026-08-08).
///
/// Multiplies catalog base amounts by 0.4 and rounds **up** to int.
int scaleMiniGameAchievementReward(int basePoints) {
  if (basePoints <= 0) return 0;
  return (basePoints * 0.4).ceil();
}

/// Formats `"N points"` using [scaleMiniGameAchievementReward].
String scaledMiniGameRewardLabel(int basePoints) =>
    '${scaleMiniGameAchievementReward(basePoints)} points';
