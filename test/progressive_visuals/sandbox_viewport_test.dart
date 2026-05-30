import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/sandbox_entity.dart';
import 'package:focusNexus/progressive_visuals/sandbox_viewport.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/progressive_visuals/zen_garden_hit_test.dart';

void main() {
  group('sandboxNormFromLocal', () {
    test('maps center to 0.5, 0.5', () {
      final norm = sandboxNormFromLocal(const Offset(100, 50), const Size(200, 100));
      expect(norm.dx, 0.5);
      expect(norm.dy, 0.5);
    });

    test('clamps to unit square', () {
      final norm = sandboxNormFromLocal(const Offset(-10, 300), const Size(200, 100));
      expect(norm.dx, 0);
      expect(norm.dy, 1);
    });
  });

  group('zenGardenNearestPick', () {
    GardenState gardenWith({
      List<GardenItem> items = const [],
      List<DecorItem> decor = const [],
    }) =>
        GardenState(pointsBalance: 0, items: items, decor: decor);

    test('returns null on empty sand', () {
      expect(zenGardenNearestPick(0.5, 0.5, gardenWith()), isNull);
    });

    test('picks plant at its position', () {
      final garden = gardenWith(
        items: [
          GardenItem(
            id: 'p1',
            themeId: VisualThemeId.zenGarden,
            positionX: 0.5,
            positionY: 0.5,
          ),
        ],
      );
      final pick = zenGardenNearestPick(0.5, 0.5, garden);
      expect(pick?.id, 'p1');
      expect(pick?.kind, SandboxEntityKind.primary);
    });

    test('prefers closer plant over farther decor', () {
      final garden = gardenWith(
        items: [
          GardenItem(
            id: 'near',
            themeId: VisualThemeId.zenGarden,
            positionX: 0.5,
            positionY: 0.5,
          ),
        ],
        decor: [
          DecorItem(
            id: 'far',
            themeId: VisualThemeId.zenGarden,
            kind: 'zen.stone_path',
            positionX: 0.9,
            positionY: 0.9,
          ),
        ],
      );
      final pick = zenGardenNearestPick(0.5, 0.5, garden);
      expect(pick?.id, 'near');
    });
  });

  group('sandboxViewportIsDefault', () {
    test('identity matrix is default', () {
      expect(sandboxViewportIsDefault(Matrix4.identity()), isTrue);
    });

    test('translated matrix is not default', () {
      final m = Matrix4.identity()..translate(12.0, 8.0);
      expect(sandboxViewportIsDefault(m), isFalse);
    });
  });

  test('lerpSandboxViewportMatrix reaches identity at t=1', () {
    final from = Matrix4.identity()..scale(2.0)..translate(40.0, 20.0);
    final result = lerpSandboxViewportMatrix(from, Matrix4.identity(), 1);
    expect(sandboxViewportIsDefault(result), isTrue);
  });
}
