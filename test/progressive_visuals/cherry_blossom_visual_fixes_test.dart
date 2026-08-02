import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_peace_petal_spec.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_power_petal_spec.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_six_leaves.dart';

void main() {
  group('content baseline anchoring', () {
    test('baseline alignment keeps content bottom fixed under scale math', () {
      // pad=0.15 -> Alignment.y = 1 - 2*0.15 = 0.7
      expect(
        CherryBlossomStageCatalog.contentBaselineAlignmentY(0.15),
        closeTo(0.7, 0.0001),
      );
      expect(
        CherryBlossomStageCatalog.contentBaselineAlignmentY(0),
        closeTo(1.0, 0.0001),
      );
    });

    test('growth uses fixed max height with relative scale from baseline', () {
      final minH = CherryBlossomStageCatalog.treeHeightFraction(
        stageIndex: 2,
        growthStepsInStage: 0,
      );
      final maxH = CherryBlossomStageCatalog.treeHeightFraction(
        stageIndex: 2,
        growthStepsInStage: 24,
      );
      expect(
        CherryBlossomStageCatalog.growthScaleRelativeToMax(
          stageIndex: 2,
          growthStepsInStage: 0,
        ),
        closeTo(minH / maxH, 0.001),
      );
      expect(
        CherryBlossomStageCatalog.growthScaleRelativeToMax(
          stageIndex: 2,
          growthStepsInStage: 24,
        ),
        closeTo(1.0, 0.001),
      );
    });

    test('per-stage content bottom padding is defined for RGB stages', () {
      expect(
        CherryBlossomStageCatalog.contentBottomPaddingFraction(0),
        greaterThan(0.1),
      );
      expect(
        CherryBlossomStageCatalog.contentBottomPaddingFraction(6),
        0.0,
      );
    });

    test('tree layer bottom offset seats baseline on ground top', () {
      const viewportH = 600.0;
      final drawH = viewportH *
          CherryBlossomStageCatalog.maxTreeHeightFraction(2);
      final pad = CherryBlossomStageCatalog.contentBottomPaddingFraction(2);
      final offset = CherryBlossomStageCatalog.treeLayerBottomOffset(
        stageIndex: 2,
        viewportHeight: viewportH,
        drawHeight: drawH,
      );
      final baselineFromViewportBottom = offset + pad * drawH;
      expect(
        baselineFromViewportBottom,
        closeTo(viewportH * CherryBlossomStageCatalog.groundInsetFraction, 0.5),
      );
    });

    test('Early Spring Morning pad matches reauthored asset (~25% empty)', () {
      expect(
        CherryBlossomStageCatalog.contentBottomPaddingFraction(1),
        closeTo(0.2467, 0.005),
      );
    });

    test('Deep Twilight seating bias drops tree ~10% onto ground (main + bonsai)', () {
      const viewportH = 600.0;
      final drawH = viewportH *
          CherryBlossomStageCatalog.maxTreeHeightFraction(4);
      final pad = CherryBlossomStageCatalog.contentBottomPaddingFraction(4);
      final bias = CherryBlossomStageCatalog.seatingBiasFraction(4);
      expect(pad, closeTo(0.0716, 0.005));
      // Sparse alpha fringe sits below bark; nudge seats trunk on ground strip.
      expect(bias, closeTo(0.10, 0.0001));

      final mainOffset = CherryBlossomStageCatalog.treeLayerBottomOffset(
        stageIndex: 4,
        viewportHeight: viewportH,
        drawHeight: drawH,
      );
      final bonsaiOffset = CherryBlossomStageCatalog.bonsaiTreeBottomOffset(
        stageIndex: 4,
        cellHeight: viewportH,
        drawHeight: drawH,
      );
      expect(mainOffset, closeTo(bonsaiOffset, 0.001));

      final barkBaseline = mainOffset + pad * drawH;
      final groundTop = viewportH * CherryBlossomStageCatalog.groundInsetFraction;
      expect(barkBaseline, closeTo(groundTop - viewportH * bias, 0.5));
      expect(groundTop - barkBaseline, closeTo(viewportH * 0.10, 1.0));
    });

    test('non-full-bleed stages use contain so wide canopies are not side-clipped', () {
      for (var s = 0; s <= 5; s++) {
        expect(
          CherryBlossomStageCatalog.imageFitFor(
            stageIndex: s,
            fullBleed: false,
          ),
          BoxFit.contain,
          reason: 'stage $s',
        );
      }
      expect(
        CherryBlossomStageCatalog.imageFitFor(
          stageIndex: 6,
          fullBleed: true,
        ),
        BoxFit.cover,
      );
    });

    test('ground fill colors are earthy not sky scaffold', () {
      final ground = CherryBlossomStageCatalog.groundFillColorFor(2);
      final sky = CherryBlossomStageCatalog.scaffoldColorFor(2);
      expect(ground, isNot(sky));
      // Midday soil is brown (red+green high-ish, blue lower).
      expect(
        (ground.b * 255.0).round().clamp(0, 255),
        lessThan((ground.r * 255.0).round().clamp(0, 255)),
      );
    });
  });

  group('night stage contrast', () {
    test('Deep Twilight and Aurora Veil request contrast boost', () {
      expect(CherryBlossomStageCatalog.needsNightContrastBoost(4), isTrue);
      expect(CherryBlossomStageCatalog.needsNightContrastBoost(5), isTrue);
      expect(CherryBlossomStageCatalog.needsNightContrastBoost(3), isFalse);
      expect(CherryBlossomStageCatalog.needsNightContrastBoost(6), isFalse);
    });
  });

  group('true-alpha stages 0-5', () {
    test('stages 0-5 skip multiply (true-alpha assets)', () {
      for (var s = 0; s <= 5; s++) {
        expect(
          CherryBlossomStageCatalog.usesTrueAlphaAsset(s),
          isTrue,
          reason: 'stage $s true alpha',
        );
        expect(
          CherryBlossomStageCatalog.usesMultiplyBlend(s, 0),
          isFalse,
          reason: 'stage $s multiply',
        );
      }
    });
  });

  group('stage 6 leaf population', () {
    test('target concurrent petals equals display level', () {
      expect(CherryBlossomStageSixLeaves.targetConcurrentCount(1), 1);
      expect(CherryBlossomStageSixLeaves.targetConcurrentCount(2), 2);
      expect(CherryBlossomStageSixLeaves.targetConcurrentCount(3), 3);
      expect(CherryBlossomStageSixLeaves.targetConcurrentCount(25), 25);
    });

    test('lit side is right (brighter canopy), shadow is left', () {
      expect(CherryBlossomStageSixLeaves.isLitSide(fromLeft: false), isTrue);
      expect(CherryBlossomStageSixLeaves.isLitSide(fromLeft: true), isFalse);
    });
  });

  group('peace petal spec', () {
    test('population and layer shares', () {
      expect(CherryBlossomPeacePetalSpec.minConcurrent, 70);
      expect(CherryBlossomPeacePetalSpec.maxConcurrent, 90);
      expect(
        CherryBlossomPeacePetalSpec.backLayerShare +
            CherryBlossomPeacePetalSpec.midLayerShare +
            CherryBlossomPeacePetalSpec.frontLayerShare,
        closeTo(1.0, 0.001),
      );
    });

    test('type weights sum to 1', () {
      expect(
        CherryBlossomPeacePetalSpec.luminousWhiteWeight +
            CherryBlossomPeacePetalSpec.softBlushWeight +
            CherryBlossomPeacePetalSpec.goldKissedWeight,
        closeTo(1.0, 0.001),
      );
    });

    test('classify type by roll', () {
      expect(
        CherryBlossomPeacePetalSpec.typeForRoll(0.0),
        PeacePetalType.luminousWhite,
      );
      expect(
        CherryBlossomPeacePetalSpec.typeForRoll(0.49),
        PeacePetalType.luminousWhite,
      );
      expect(
        CherryBlossomPeacePetalSpec.typeForRoll(0.50),
        PeacePetalType.softBlush,
      );
      expect(
        CherryBlossomPeacePetalSpec.typeForRoll(0.84),
        PeacePetalType.softBlush,
      );
      expect(
        CherryBlossomPeacePetalSpec.typeForRoll(0.85),
        PeacePetalType.goldKissed,
      );
    });
  });

  group('power dark authority petals', () {
    test('bimodal fall and minimal drift', () {
      expect(CherryBlossomPowerPetalSpec.slowFallMinSec, 5);
      expect(CherryBlossomPowerPetalSpec.slowFallMaxSec, 9);
      expect(CherryBlossomPowerPetalSpec.fastFallMinSec, 1.5);
      expect(CherryBlossomPowerPetalSpec.fastFallMaxSec, 3.0);
      expect(CherryBlossomPowerPetalSpec.driftAmplitudeFactor, lessThanOrEqualTo(0.015));
      expect(CherryBlossomPowerPetalSpec.maxConcurrent, lessThanOrEqualTo(18));
    });
  });
}
