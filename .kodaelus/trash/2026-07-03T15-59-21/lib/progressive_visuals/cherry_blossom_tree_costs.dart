import 'cherry_blossom_tree_sequence.dart';
import 'cherry_blossom_tree_state.dart';

/// Growth costs from the fixed cherry blossom sequence (exactly 1M total).
abstract final class CherryBlossomTreeCosts {
  CherryBlossomTreeCosts._();

  static int costAtStep(int stepIndex) => CherryBlossomTreeSequence.stepCosts[stepIndex];

  static int totalMaxCost() => CherryBlossomTreeSequence.milestone1m;

  static int remainingToMax(CherryBlossomTreeState state) {
    final normalized = state.normalized();
    if (normalized.growthStepIndex >= CherryBlossomTreeSequence.totalSteps) {
      return 0;
    }
    return CherryBlossomTreeSequence.milestone1m -
        normalized.totalTreePointsInvested;
  }
}
