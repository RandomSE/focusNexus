import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_valuation.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/zen_placeable_bounds.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_decor_painters.dart';
import 'package:focusNexus/screens/zen_garden/zen_placeable_layout.dart';

void main() {
  group('hit bounds', () {
    test('stage 0 stepping stones hit at painted stone centers', () {
      final decor = DecorItem(
        id: 'sp',
        themeId: VisualThemeId.zenGarden,
        kind: 'zen.stone_path',
        stageIndex: 0,
        positionX: 0.5,
        positionY: 0.5,
      );
      final centers = zenStonePathStoneCentersNorm(decor, zenReferenceGardenSize);
      expect(centers.length, 2);
      for (final c in centers) {
        expect(zenDecorHitNorm(c.dx, c.dy, decor), isTrue);
      }
      expect(zenDecorHitNorm(0.5, 0.2, decor), isFalse);
    });

    test('stage 1 stepping stones hit on each painted stone', () {
      final decor = DecorItem(
        id: 'sp1',
        themeId: VisualThemeId.zenGarden,
        kind: 'zen.stone_path',
        stageIndex: 1,
        positionX: 0.5,
        positionY: 0.5,
      );
      final centers = zenStonePathStoneCentersNorm(decor, zenReferenceGardenSize);
      expect(centers.length, 4);
      for (final c in centers) {
        expect(zenDecorHitNorm(c.dx, c.dy, decor), isTrue);
      }
      // First stone sits at the path start (bottom-left of paint canvas).
      expect(zenDecorHitNorm(centers.first.dx, centers.first.dy, decor), isTrue);
      expect(zenDecorHitNorm(0.5, 0.12, decor), isFalse);
    });

    test('decor hit rect center matches painted visual center offset', () {
      const decor = DecorItem(
        id: 'kp',
        themeId: VisualThemeId.zenGarden,
        kind: 'zen.koi_pond',
        stageIndex: 2,
        positionX: 0.4,
        positionY: 0.6,
      );
      final rect = zenDecorVisualNormRect(decor, zenReferenceGardenSize);
      final expected = Offset(decor.positionX, decor.positionY) +
          zenDecorVisualCenterOffsetNorm(decor, zenReferenceGardenSize);
      expect(rect.center.dx, closeTo(expected.dx, 0.001));
      expect(rect.center.dy, closeTo(expected.dy, 0.001));
    });

    test('bamboo fence uses wide horizontal bounds', () {
      final decor = DecorItem(
        id: 'bf',
        themeId: VisualThemeId.zenGarden,
        kind: 'zen.bamboo_fence',
        positionX: 0.5,
        positionY: 0.5,
      );
      final rect = zenDecorVisualNormRect(decor, zenReferenceGardenSize);
      expect(rect.width, greaterThan(rect.height));
    });
  });

  group('placement margins', () {
    test('visual margins are tighter than separation radii for bamboo fence', () {
      const decor = DecorItem(
        id: 'bf',
        themeId: VisualThemeId.zenGarden,
        kind: 'zen.bamboo_fence',
        stageIndex: 0,
      );
      final (pmx, _) = zenDecorPlacementMargins(decor);
      final (smx, _) = zenDecorSeparationRadii(decor);
      expect(pmx, lessThan(smx));
    });

    test('collects entities overlapping a norm rect', () {
      final garden = GardenState(
        pointsBalance: 0,
        items: [
          GardenItem(
            id: 'p1',
            themeId: VisualThemeId.zenGarden,
            positionX: 0.3,
            positionY: 0.5,
          ),
        ],
        decor: [
          DecorItem(
            id: 'd1',
            themeId: VisualThemeId.zenGarden,
            kind: 'zen.moss_rock',
            positionX: 0.8,
            positionY: 0.5,
          ),
        ],
      );
      final primary = <String>{};
      final decor = <String>{};
      zenGardenCollectInNormRect(
        const Rect.fromLTWH(0.2, 0.3, 0.2, 0.4),
        garden,
        zenReferenceGardenSize,
        bulkPrimary: primary,
        bulkDecor: decor,
      );
      expect(primary, {'p1'});
      expect(decor, isEmpty);
    });
  });

  group('valuation', () {
    test('sell value is half of stage investment regardless of restarts', () {
      const kind = 'zen.stone_path';
      expect(decorSellValue(
        DecorItem(id: 'a', themeId: VisualThemeId.zenGarden, kind: kind, stageIndex: 3),
      ), decorInvestmentPoints(kind, 3) ~/ 2);
      expect(plantSellValue(
        GardenItem(id: 'p', themeId: VisualThemeId.zenGarden, stageIndex: 2),
      ), plantInvestmentPoints(2) ~/ 2);
    });
  });
}
