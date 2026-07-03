import 'garden_state.dart';

/// Wallet or lifetime zen spend threshold for cherry blossom tree access.
const int cherryBlossomUnlockThreshold = 10000;

/// Evaluates unlock — once true, stays true even if balance drops.
GardenState evaluateCherryBlossomUnlock(GardenState state) {
  if (state.cherryBlossomTreeUnlocked) return state;
  if (state.pointsBalance >= cherryBlossomUnlockThreshold ||
      state.lifetimeZenPointsSpent >= cherryBlossomUnlockThreshold) {
    return state.copyWith(cherryBlossomTreeUnlocked: true);
  }
  return state;
}

bool isCherryBlossomTreeUnlocked(GardenState state) {
  return state.cherryBlossomTreeUnlocked ||
      state.pointsBalance >= cherryBlossomUnlockThreshold ||
      state.lifetimeZenPointsSpent >= cherryBlossomUnlockThreshold;
}
