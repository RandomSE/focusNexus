import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';

void main() {
  test('legacy JSON resets to initial state', () {
    final legacy = CherryBlossomTreeState.fromJson({
      'growthStepIndex': 50,
      'branchSlots': [1, 2],
      'totalTreePointsInvested': 10000,
    });
    expect(legacy, CherryBlossomTreeState.initial());
  });

  test('new JSON roundtrips', () {
    const original = CherryBlossomTreeState(
      stageIndex: 2,
      growthStepsInStage: 5,
      totalTreePointsInvested: 4000,
      bonsaiFilledSlots: {0: 25, 1: 3},
      highestStageUnlocked: 2,
    );
    final restored = CherryBlossomTreeState.fromJson(original.toJson());
    expect(restored.stageIndex, 2);
    expect(restored.growthStepsInStage, 5);
    expect(restored.bonsaiCountForStage(0), 25);
  });
}
