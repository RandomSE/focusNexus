import 'cherry_blossom_unlock.dart';
import 'garden_state.dart';

/// Applies a zen-garden point spend and increments lifetime investment counter.
GardenState applyZenSpend(GardenState state, int amount) {
  if (amount < 0) {
    throw ArgumentError.value(amount, 'amount', 'must be non-negative');
  }
  final next = state.copyWith(
    pointsBalance: state.pointsBalance - amount,
    lifetimeZenPointsSpent: state.lifetimeZenPointsSpent + amount,
  );
  return evaluateCherryBlossomUnlock(next);
}

/// Restores wallet points from an undone zen-garden spend (tree growth undo).
GardenState refundZenSpend(GardenState state, int amount) {
  if (amount < 0) {
    throw ArgumentError.value(amount, 'amount', 'must be non-negative');
  }
  if (amount == 0) return state;
  final nextLifetime = state.lifetimeZenPointsSpent - amount;
  return state.copyWith(
    pointsBalance: state.pointsBalance + amount,
    lifetimeZenPointsSpent: nextLifetime < 0 ? 0 : nextLifetime,
  );
}
