import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_cartoon_style.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_decor_painters.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_painters.dart';
import 'package:focusNexus/screens/zen_garden/zen_placeable_layout.dart';

DecorItem _decor(String kind) => DecorItem(
      id: 'test',
      themeId: VisualThemeId.zenGarden,
      kind: kind,
      stageIndex: 2,
      positionX: 0.5,
      positionY: 0.5,
    );

void main() {
  group('contact shadows', () {
    test('use offset bottom-right contact shadow parameters', () {
      expect(ZenCartoonStyle.placeableShadowOffset, const Offset(3, 4));
      expect(ZenCartoonStyle.placeableShadowBlur, 6);
      expect(ZenCartoonStyle.placeableShadowAlpha, closeTo(0.18, 0.001));
    });

    test('ground shadow only for elevated decor, not sand-flush items', () {
      expect(zenDecorUsesGroundShadow('zen.stone_path'), isFalse);
      expect(zenDecorUsesGroundShadow('zen.koi_pond'), isFalse);
      expect(zenDecorUsesGroundShadow('zen.stone_lantern'), isFalse);
      expect(zenDecorUsesGroundShadow('zen.bamboo_fence'), isFalse);
      expect(zenDecorUsesGroundShadow('zen.moss_rock'), isFalse);
      expect(zenDecorUsesGroundShadow('zen.wood_bench'), isTrue);
    });
  });

  group('bamboo fence canvas', () {
    test('paint canvas is tall enough for full stalk height', () {
      final size = zenDecorPaintCanvasSize(_decor('zen.bamboo_fence'));
      expect(size.height, greaterThan(78.0));
      // Stalks extend ~45px above center; center sits at mid-canvas.
      expect(size.height / 2, greaterThan(zenBambooFenceStalkExtent + 4));
    });

    test('uses rounded top clip radius', () {
      expect(zenDecorTopClipRadius('zen.bamboo_fence'), greaterThan(0.0));
      expect(zenDecorTopClipRadius('zen.koi_pond'), 0.0);
    });
  });

  group('tree canopy progression', () {
    test('canopy diameters match reduced stage targets', () {
      final diameters = List.generate(5, zenTreeCanopyDiameter);
      expect(diameters, [22.0, 30.0, 40.0, 50.0, 60.0]);
      for (var i = 1; i < diameters.length; i++) {
        expect(diameters[i], greaterThan(diameters[i - 1]));
      }
    });

    test('canopy foliage uses light 1.5px stroke', () {
      expect(zenTreeCanopyStrokeWidth, 1.5);
    });
  });

  group('lantern glow sizing', () {
    test('no sand glow canvas until stage 3 (index 2)', () {
      expect(ZenGardenDecorPainter.lanternSandGlowSize(0), Size.zero);
      expect(ZenGardenDecorPainter.lanternSandGlowSize(1), Size.zero);
    });

    test('stage 5 outer glow fits 70px ring', () {
      final size = ZenGardenDecorPainter.lanternSandGlowSize(4);
      expect(size.width, greaterThanOrEqualTo(140));
    });
  });
}
