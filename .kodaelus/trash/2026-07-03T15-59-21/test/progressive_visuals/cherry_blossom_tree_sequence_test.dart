import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_growth.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_sequence.dart';

void main() {
  group('CherryBlossomTreeSequence', () {
    test('step costs sum to 1M with exact milestone boundaries', () {
      expect(CherryBlossomTreeSequence.totalSteps, 110);
      expect(
        CherryBlossomTreeSequence.stepCosts.fold<int>(0, (a, b) => a + b),
        CherryBlossomTreeSequence.milestone1m,
      );
      expect(
        CherryBlossomTreeSequence.cumulativeInvestment(
          CherryBlossomTreeSequence.stepsAt1k,
        ),
        CherryBlossomTreeSequence.milestone1k,
      );
      expect(
        CherryBlossomTreeSequence.cumulativeInvestment(
          CherryBlossomTreeSequence.stepsAt10k,
        ),
        CherryBlossomTreeSequence.milestone10k,
      );
    });

    test('focuses align with band step counts and branch unlock order', () {
      expect(
        CherryBlossomTreeSequence.stepFocuses.length,
        CherryBlossomTreeSequence.totalSteps,
      );
      expect(
        CherryBlossomTreeSequence.bandTrunkStepCounts.fold<int>(0, (a, b) => a + b),
        CherryBlossomTreeSequence.totalTrunkGrowthSteps,
      );

      var branchSlotsSeen = <int>{};
      for (var i = 0; i < CherryBlossomTreeSequence.stepsAt1k; i++) {
        final f = CherryBlossomTreeSequence.stepFocuses[i];
        if (f.kind == CherryBlossomGrowthKind.branch) {
          branchSlotsSeen.add(f.slotIndex);
        }
        if (f.kind == CherryBlossomGrowthKind.leaf) {
          final branch = f.slotIndex ~/ 3;
          expect(
            branch,
            lessThanOrEqualTo(CherryBlossomTreeSequence.maxBranchSlotUnlocked(i + 1)),
          );
        }
      }
      expect(branchSlotsSeen, {0, 1, 2, 3});
    });
  });
}
