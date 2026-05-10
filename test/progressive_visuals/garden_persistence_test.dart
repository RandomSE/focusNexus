import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

void main() {
  test('Zen garden persistence roundtrip', () {
    final original = GardenState(
      pointsBalance: 99,
      items: [
        GardenItem(
          id: 'a',
          themeId: VisualThemeId.zenGarden,
          stageIndex: 2,
          positionX: 0.3,
          positionY: 0.7,
          nextAdvanceAllowedAt: DateTime.utc(2026, 5, 10, 14, 30),
          pendingSkipWaitCost: 15,
          mutation: MutationKind.invertedColors,
          awaitingRegrowthForRemutation: true,
          mutationRolledThisCycle: true,
          regrowthDiscountActive: true,
        ),
      ],
      decorStash: {'zen.moss_rock': 2},
      freeFirstGrowthEverConsumed: true,
      freeFirstGrowthEligibleItemId: null,
    );
    final json = GardenPersistence.encodeZenGarden(original);
    final restored = GardenPersistence.decodeZenGarden(json, 42);

    expect(restored.pointsBalance, 42);
    expect(restored.freeFirstGrowthEverConsumed, isTrue);
    expect(restored.decorStash['zen.moss_rock'], 2);
    expect(restored.items.length, 1);
    final i = restored.items.single;
    expect(i.id, 'a');
    expect(i.themeId, VisualThemeId.zenGarden);
    expect(i.stageIndex, 2);
    expect(i.positionX, 0.3);
    expect(i.positionY, 0.7);
    expect(i.nextAdvanceAllowedAt, DateTime.utc(2026, 5, 10, 14, 30));
    expect(i.pendingSkipWaitCost, 15);
    expect(i.mutation, MutationKind.invertedColors);
    expect(i.awaitingRegrowthForRemutation, isTrue);
    expect(i.mutationRolledThisCycle, isTrue);
    expect(i.regrowthDiscountActive, isTrue);
  });
}
