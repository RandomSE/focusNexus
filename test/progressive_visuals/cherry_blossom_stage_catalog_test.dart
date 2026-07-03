import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';

void main() {
  group('CherryBlossomStageCatalog', () {
    test('stage totals sum to grand total', () {
      expect(CherryBlossomStageCatalog.grandTotalToMaxStage6(), 2665500);
    });

    test('each stage has 25 strictly increasing costs matching total', () {
      for (var stage = 0; stage < CherryBlossomStageCatalog.stageCount; stage++) {
        final costs = CherryBlossomStageCatalog.stageCostsFor(stage);
        expect(costs.length, 25);
        for (var i = 1; i < costs.length; i++) {
          expect(costs[i], greaterThan(costs[i - 1]));
        }
        expect(
          costs.fold<int>(0, (a, b) => a + b),
          CherryBlossomStageCatalog.stageTotalFor(stage),
        );
      }
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
