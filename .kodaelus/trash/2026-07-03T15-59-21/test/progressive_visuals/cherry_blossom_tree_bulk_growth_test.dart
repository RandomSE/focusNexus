import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_sequence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';

void main() {
  group('bulk growth budget', () {
    test('caps at next milestone room', () {
      expect(
        CherryBlossomTreeEngine.bulkGrowthBudget(
          walletBalance: 500,
          treeInvested: 0,
        ),
        500,
      );
      expect(
        CherryBlossomTreeEngine.bulkGrowthBudget(
          walletBalance: 5000,
          treeInvested: 0,
        ),
        1000,
      );
      expect(
        CherryBlossomTreeEngine.bulkGrowthBudget(
          walletBalance: 5000,
          treeInvested: 1000,
        ),
        5000,
      );
      expect(
        CherryBlossomTreeEngine.bulkGrowthBudget(
          walletBalance: 50000,
          treeInvested: 1000,
        ),
        9000,
      );
    });

    test('returns zero when tree is perfect', () {
      expect(
        CherryBlossomTreeEngine.bulkGrowthBudget(
          walletBalance: 3000,
          treeInvested: 1000000,
        ),
        0,
      );
    });
  });

  group('growBulk', () {
    test('fails when balance cannot afford next step', () {
      const garden = GardenState(pointsBalance: 10);
      final r = CherryBlossomTreeEngine().growBulk(garden);
      expect(r.isSuccess, isFalse);
    });

    test('fast grow reaches exactly next milestone', () {
      const garden = GardenState(pointsBalance: 50000);
      final r = CherryBlossomTreeEngine().growBulk(garden);
      expect(r.isSuccess, isTrue);
      expect(r.state!.cherryBlossomTree.totalTreePointsInvested, 1000);
      expect(50000 - r.state!.pointsBalance, 1000);
    });

    test('fast grow from 1k to 10k spends exactly 9000', () {
      final garden = GardenState(
        pointsBalance: 50000,
        cherryBlossomTree: CherryBlossomTreeEngine.milestoneStateForInvestment(1000),
      );
      final r = CherryBlossomTreeEngine(garden.cherryBlossomTree).growBulk(garden);
      expect(r.isSuccess, isTrue);
      expect(r.state!.cherryBlossomTree.totalTreePointsInvested, 10000);
      expect(50000 - r.state!.pointsBalance, 9000);
    });

    test('bulk growth is a single undo step that refunds wallet', () {
      const garden = GardenState(pointsBalance: 5000);
      final r = CherryBlossomTreeEngine().growBulk(garden);
      expect(r.isSuccess, isTrue);
      expect(r.state!.cherryBlossomTree.undoStack.length, 1);

      final undone = CherryBlossomTreeEngine(r.state!.cherryBlossomTree).undo(r.state!);
      expect(undone.isSuccess, isTrue);
      expect(undone.state!.cherryBlossomTree.totalTreePointsInvested, 0);
      expect(undone.state!.pointsBalance, 5000);
    });

    test('full tree costs exactly one million', () {
      var garden = const GardenState(pointsBalance: 2000000);
      while (true) {
        final engine = CherryBlossomTreeEngine(garden.cherryBlossomTree);
        if (!engine.canGrow()) break;
        final r = engine.growBulk(garden);
        if (!r.isSuccess) {
          final single = engine.growNext(garden);
          if (!single.isSuccess) break;
          garden = single.state!;
          continue;
        }
        garden = r.state!;
      }
      expect(
        garden.cherryBlossomTree.totalTreePointsInvested,
        CherryBlossomTreeSequence.milestone1m,
      );
      expect(2000000 - garden.pointsBalance, 1000000);
    });
  });
}
