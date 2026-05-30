import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/zen_garden/zen_inventory_stacks.dart';

void main() {
  group('inventory stack keys', () {
    test('next plant id stays within same stage and mutation', () {
      const theme = VisualThemeId.zenGarden;
      final inventory = [
        GardenItem(id: 'p0', themeId: theme, stageIndex: 0),
        GardenItem(id: 'p2a', themeId: theme, stageIndex: 2),
        GardenItem(
          id: 'p2m',
          themeId: theme,
          stageIndex: 2,
          mutation: MutationKind.invertedColors,
        ),
        GardenItem(id: 'p2b', themeId: theme, stageIndex: 2),
      ];
      final stackKey = plantInventoryStackKey(inventory[1]);
      expect(
        nextPlantInventoryIdInStack(inventory, stackKey),
        'p2a',
      );
      final afterFirst = inventory.where((p) => p.id != 'p2a').toList();
      expect(
        nextPlantInventoryIdInStack(afterFirst, stackKey),
        'p2b',
      );
      expect(
        nextPlantInventoryIdInStack(
          afterFirst.where((p) => p.id != 'p2b').toList(),
          stackKey,
        ),
        isNull,
      );
    });

    test('next decor id stays within same kind stage and mutation', () {
      final inventory = [
        DecorItem(id: 'd0', themeId: VisualThemeId.zenGarden, kind: 'zen.moss_rock'),
        DecorItem(
          id: 'd2a',
          themeId: VisualThemeId.zenGarden,
          kind: 'zen.stone_path',
          stageIndex: 2,
        ),
        DecorItem(
          id: 'd2m',
          themeId: VisualThemeId.zenGarden,
          kind: 'zen.stone_path',
          stageIndex: 2,
          mutation: MutationKind.invertedColors,
        ),
        DecorItem(
          id: 'd2b',
          themeId: VisualThemeId.zenGarden,
          kind: 'zen.stone_path',
          stageIndex: 2,
        ),
      ];
      final stackKey = decorInventoryStackKey(inventory[1]);
      expect(nextDecorInventoryIdInStack(inventory, stackKey), 'd2a');
      expect(
        decorInventoryStackKey(inventory[2]),
        isNot(equals(stackKey)),
      );
    });
  });
}
