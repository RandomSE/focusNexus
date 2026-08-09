import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';

void main() {
  group('CherryBlossomStageCatalog', () {
    test('stage totals sum to grand total', () {
      expect(CherryBlossomStageCatalog.grandTotalToMaxStage6(), 1682500);
    });

    test('path switch cost is 100000 after rebalance', () {
      expect(CherryBlossomStageCatalog.pathSwitchCost, 100000);
    });

    test('each stage has 25 flat round costs matching total', () {
      const expectedPerLevel = <int>[
        20, // 500
        80, // 2000
        320, // 8000
        1280, // 32000
        5120, // 128000
        20480, // 512000
        40000, // 1000000
      ];
      for (var stage = 0; stage < CherryBlossomStageCatalog.stageCount; stage++) {
        final costs = CherryBlossomStageCatalog.stageCostsFor(stage);
        expect(costs.length, 25);
        expect(
          costs.toSet(),
          {expectedPerLevel[stage]},
          reason: 'stage $stage should be flat ${expectedPerLevel[stage]}',
        );
        expect(
          costs.fold<int>(0, (a, b) => a + b),
          CherryBlossomStageCatalog.stageTotalFor(stage),
        );
      }
    });

    test('grow cost stays constant within a stage', () {
      expect(
        CherryBlossomStageCatalog.costForGrow(
          stageIndex: 6,
          growthStepsInStage: 0,
        ),
        40000,
      );
      expect(
        CherryBlossomStageCatalog.costForGrow(
          stageIndex: 6,
          growthStepsInStage: 12,
        ),
        40000,
      );
      expect(
        CherryBlossomStageCatalog.costForPrestige(
          stageIndex: 6,
          growthStepsInStage: 24,
        ),
        40000,
      );
    });

    test('scale boundaries', () {
      expect(
        CherryBlossomStageCatalog.scaleFor(stageIndex: 0, growthStepsInStage: 0),
        closeTo(1.0, 0.001),
      );
      expect(
        CherryBlossomStageCatalog.scaleFor(
          stageIndex: 0,
          growthStepsInStage: 24,
        ),
        closeTo(1.18, 0.001),
      );
      expect(
        CherryBlossomStageCatalog.scaleFor(stageIndex: 2, growthStepsInStage: 0),
        closeTo(0.60, 0.001),
      );
      expect(
        CherryBlossomStageCatalog.scaleFor(
          stageIndex: 2,
          growthStepsInStage: 24,
        ),
        closeTo(1.0, 0.001),
      );
    });

    test('asset paths', () {
      expect(
        CherryBlossomStageCatalog.assetPathFor(stageIndex: 3),
        'assets/images/cherry_blossom_tree/stage_3.png',
      );
    });
  });
}
