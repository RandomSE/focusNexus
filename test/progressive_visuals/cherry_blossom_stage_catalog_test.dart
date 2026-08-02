import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';

void main() {
  group('CherryBlossomStageCatalog', () {
    test('stage totals sum to grand total', () {
      expect(CherryBlossomStageCatalog.grandTotalToMaxStage6(), 2665500);
    });

    test('each stage has 25 flat round costs matching total', () {
      const expectedPerLevel = <int>[
        20, // 500
        100, // 2500
        500, // 12500
        2000, // 50000
        4000, // 100000
        20000, // 500000
        80000, // 2000000
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
        80000,
      );
      expect(
        CherryBlossomStageCatalog.costForGrow(
          stageIndex: 6,
          growthStepsInStage: 12,
        ),
        80000,
      );
      expect(
        CherryBlossomStageCatalog.costForPrestige(
          stageIndex: 6,
          growthStepsInStage: 24,
        ),
        80000,
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
