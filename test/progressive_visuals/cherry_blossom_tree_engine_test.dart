import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';

void main() {
  group('CherryBlossomTreeEngine', () {
    test('growOne spends and increments bonsai', () {
      const garden = GardenState(pointsBalance: 10000);
      final engine = CherryBlossomTreeEngine();
      final cost = engine.nextGrowCost()!;
      final result = engine.growOne(garden);
      expect(result.isSuccess, isTrue);
      expect(result.state!.pointsBalance, 10000 - cost);
      expect(result.state!.cherryBlossomTree.growthStepsInStage, 1);
      expect(result.state!.cherryBlossomTree.bonsaiCountForStage(0), 1);
    });

    test('growToAffordableMax stops at wallet or stage cap', () {
      final engine = CherryBlossomTreeEngine();
      final firstCost = engine.nextGrowCost()!;
      final garden = GardenState(pointsBalance: firstCost);
      final result = engine.growToAffordableMax(garden);
      expect(result.isSuccess, isTrue);
      expect(result.state!.pointsBalance, 0);
      expect(result.state!.cherryBlossomTree.growthStepsInStage, 1);
    });

    test('prestige charges final grow cost and advances stage', () {
      var tree = CherryBlossomTreeState.initial();
      for (var i = 0; i < CherryBlossomStageCatalog.levelsPerStage - 1; i++) {
        tree = CherryBlossomTreeEngine(tree).growOne(
          GardenState(pointsBalance: 1000000),
        ).state!.cherryBlossomTree;
      }
      expect(tree.growthStepsInStage, CherryBlossomStageCatalog.levelsPerStage - 1);
      expect(tree.displayLevel, CherryBlossomStageCatalog.levelsPerStage);

      final prestigeCost = CherryBlossomTreeEngine(tree).prestigeCost()!;
      final garden = GardenState(pointsBalance: prestigeCost, cherryBlossomTree: tree);
      final engine = CherryBlossomTreeEngine(tree);
      final result = engine.prestige(garden);
      expect(result.isSuccess, isTrue);
      expect(result.state!.pointsBalance, 0);
      expect(result.state!.cherryBlossomTree.stageIndex, 1);
      expect(result.state!.cherryBlossomTree.growthStepsInStage, 0);
      expect(result.state!.cherryBlossomTree.bonsaiCountForStage(0), 25);
      expect(result.prestiged, isTrue);
    });

    test('stage 6 prestige requires path and unlocks finale', () {
      final tree = CherryBlossomTreeEngine.maxedStageSix();
      final prestigeCost = CherryBlossomTreeEngine(tree).prestigeCost()!;
      final garden = GardenState(
        pointsBalance: prestigeCost,
        cherryBlossomTree: tree,
      );
      final engine = CherryBlossomTreeEngine(tree);
      expect(
        engine.prestige(garden).error,
        contains('Power or Peace'),
      );
      final peace = engine.prestige(
        garden,
        path: CherryBlossomPrestigePath.peace,
      );
      expect(peace.isSuccess, isTrue);
      expect(peace.state!.cherryBlossomTree.stageIndex, 7);
      expect(
        peace.state!.cherryBlossomTree.prestigePath,
        CherryBlossomPrestigePath.peace,
      );
      expect(peace.state!.cherryBlossomTree.assetPath, contains('stage_7a'));
      expect(
        peace.state!.cherryBlossomTree.peaceBonsaiCount,
        25,
      );
    });

    test('grow fails with insufficient wallet', () {
      const garden = GardenState(pointsBalance: 0);
      final result = CherryBlossomTreeEngine().growOne(garden);
      expect(result.isSuccess, isFalse);
    });
  });
}
