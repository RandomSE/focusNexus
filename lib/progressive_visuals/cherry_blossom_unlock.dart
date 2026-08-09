import 'garden_state.dart';

/// Wallet or lifetime spend threshold for cherry blossom tree access.
///
/// Lifetime includes zen garden spends and other wallet spends tracked via
/// [StorageKeys.lifetimePointsSpent] (merged into garden on load).
const int cherryBlossomUnlockThreshold = 10000;

/// Wallet + progressive-visuals balance combined, same formula as
/// `zenSpendableBalance` in garden_zen_spend.dart. Duplicated here (rather
/// than imported) because garden_zen_spend.dart already imports this file.
int _combinedZenBalance(GardenState state) =>
    state.pointsBalance + state.progressiveVisualsPointsBalance;

/// Evaluates unlock - once true, stays true even if balance drops.
GardenState evaluateCherryBlossomUnlock(GardenState state) {
  if (state.cherryBlossomTreeUnlocked) return state;
  if (_combinedZenBalance(state) >= cherryBlossomUnlockThreshold ||
      state.lifetimeZenPointsSpent >= cherryBlossomUnlockThreshold) {
    return state.copyWith(cherryBlossomTreeUnlocked: true);
  }
  return state;
}

bool isCherryBlossomTreeUnlocked(GardenState state) {
  return state.cherryBlossomTreeUnlocked ||
      _combinedZenBalance(state) >= cherryBlossomUnlockThreshold ||
      state.lifetimeZenPointsSpent >= cherryBlossomUnlockThreshold;
}
