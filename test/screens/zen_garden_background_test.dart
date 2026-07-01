import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_painters.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_static_scenery.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_waterfall.dart';

void main() {
  group('ZenGardenBackgroundPalette', () {
    test('harmonized palette stays warm and muted for placeable contrast', () {
      final palette = ZenGardenBackgroundPalette.harmonized(
        themePrimary: Colors.deepPurple,
        themeSecondary: Colors.white,
      );

      expect(palette.highlight.r, greaterThan(palette.shadow.r));
      expect(palette.highlight.g, greaterThan(palette.deepShadow.g));
      expect(palette.mossVeil, const Color(0xFF6B9E54));
    });

    test('harmonized factory applies only a light theme tint', () {
      final plain = ZenGardenBackgroundPalette.harmonized();
      final tinted = ZenGardenBackgroundPalette.harmonized(
        themePrimary: Colors.red,
        themeSecondary: Colors.blue,
      );

      expect(tinted.midTone, isNot(equals(plain.midTone)));
      expect(
        (tinted.midTone.r - plain.midTone.r).abs(),
        lessThan(20),
      );
    });
  });

  group('ZenGardenStaticSceneryPainter', () {
    testWidgets('renders static scenery without error', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomPaint(
            size: const Size(420, 320),
            painter: ZenGardenStaticSceneryPainter.harmonized(),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('ZenGardenDecorPainter', () {
    testWidgets('renders each decor kind at max stage without error', (tester) async {
      const kinds = [
        'zen.stone_path',
        'zen.koi_pond',
        'zen.stone_lantern',
        'zen.wood_bench',
        'zen.bamboo_fence',
        'zen.moss_rock',
      ];
      for (final kind in kinds) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomPaint(
              size: const Size(94, 78),
              painter: ZenDecorPainter(
                item: DecorItem(
                  id: 'test-$kind',
                  themeId: VisualThemeId.zenGarden,
                  kind: kind,
                  stageIndex: 4,
                ),
                primary: Colors.green,
                secondary: Colors.brown,
                animPhase: 0.35,
              ),
            ),
          ),
        );
      }
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('ZenGardenWaterfallLayer', () {
    testWidgets('renders animated waterfall without error', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ZenGardenWaterfallLayer(
            size: const Size(420, 320),
            reduceMotion: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });
}
