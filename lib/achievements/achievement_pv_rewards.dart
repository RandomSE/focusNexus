/// PV grants layered on top of wallet rewards for select achievements
/// (2026-08 PV-earn rebalance). Reward strings on [Achievement] stay
/// "N points" (wallet-only, keeps [AchievementProgress.parsePointsFromReward]
/// working); PV is credited separately via
/// [ProgressiveVisualsPointsRepository] on claim.
const Map<String, int> achievementPvRewards = {
  // All High Requirements VI-VII (76-78); 75 stays wallet-only (mono).
  '76': 40000,
  '77': 60000,
  '78': 80000,
  // High-attribute IX tier across Power Player, Strategist, Effort Engine,
  // Motivation Master, Time Titan, Step Master (VIII ids stay wallet-only).
  '26': 20000,
  '35': 20000,
  '44': 20000,
  '53': 20000,
  '62': 20000,
  '71': 20000,
  // Weekly Streak Master IV-V.
  '98': 10000,
  '99': 12000,
  // Ninety Sunrises (open-streak secret).
  '117': 15000,
  // Endless mini-game tiers.
  '122': 6000,
  '135': 6000,
  '140': 6000,
  '155': 6000,
  '161': 6000,
  '167': 6000,
  '179': 6000,
  '128': 12000,
  '187': 12000,
};

/// PV amount to grant for [id] on claim, or 0 when not in the rebalance map.
int achievementPvRewardFor(String id) => achievementPvRewards[id] ?? 0;
