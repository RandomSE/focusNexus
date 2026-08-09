import 'dart:math' as math;

import 'cherry_blossom_unlock.dart';
import 'garden_state.dart';

/// Combined wallets available for a progressive-visuals purchase.
int zenSpendableBalance(GardenState state) =>
    state.pointsBalance + state.progressiveVisualsPointsBalance;

bool canAffordZenSpend(GardenState state, int amount) {
  if (amount < 0) {
    throw ArgumentError.value(amount, 'amount', 'must be non-negative');
  }
  return zenSpendableBalance(state) >= amount;
}

/// Applies a zen-garden / progressive-visuals spend.
///
/// Progressive visuals points are deducted first; remainder comes from the
/// shared wallet. [GardenState.lifetimeZenPointsSpent] counts the full amount.
GardenState applyZenSpend(GardenState state, int amount) {
  if (amount < 0) {
    throw ArgumentError.value(amount, 'amount', 'must be non-negative');
  }
  if (amount == 0) return evaluateCherryBlossomUnlock(state);
  if (!canAffordZenSpend(state, amount)) {
    throw StateError(
      'Cannot afford spend of $amount '
      '(pv=${state.progressiveVisualsPointsBalance}, '
      'points=${state.pointsBalance})',
    );
  }
  final fromPv = math.min(state.progressiveVisualsPointsBalance, amount);
  final fromPts = amount - fromPv;
  final next = state.copyWith(
    progressiveVisualsPointsBalance:
        state.progressiveVisualsPointsBalance - fromPv,
    pointsBalance: state.pointsBalance - fromPts,
    lifetimeZenPointsSpent: state.lifetimeZenPointsSpent + amount,
  );
  return evaluateCherryBlossomUnlock(next);
}

/// Restores wallet points from an undone zen-garden spend (tree growth undo).
///
/// Refunds the shared wallet only (PV earn paths are not defined yet).
GardenState refundZenSpend(GardenState state, int amount) {
  if (amount < 0) {
    throw ArgumentError.value(amount, 'amount', 'must be non-negative');
  }
  if (amount == 0) return state;
  final nextLife = state.lifetimeZenPointsSpent - amount;
  return state.copyWith(
    pointsBalance: state.pointsBalance + amount,
    lifetimeZenPointsSpent: nextLife < 0 ? 0 : nextLife,
  );
}
