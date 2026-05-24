import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

void main() {
  group('decode edge cases', () {
    test('null and empty JSON yield empty garden with wallet points', () {
      for (final input in [null, '']) {
        final state = GardenPersistence.decodeZenGarden(input, 77);
        expect(state.pointsBalance, 77);
        expect(state.items, isEmpty);
        expect(state.decor, isEmpty);
      }
    });

    test('malformed JSON falls back to empty garden', () {
      final state = GardenPersistence.decodeZenGarden('{not json', 5);
      expect(state.pointsBalance, 5);
      expect(state.items, isEmpty);
    });

    test('legacy freeFirst infers eligible id for single stage-0 plant', () {
      const json = '{"items":[{"id":"solo","themeId":"zenGarden","stageIndex":0}],"freeFirst":true}';
      final state = GardenPersistence.decodeZenGarden(json, 0);
      expect(state.freeFirstGrowthEverConsumed, isFalse);
      expect(state.freeFirstGrowthEligibleItemId, 'solo');
    });

    test('freeFirst false marks ever consumed', () {
      const json = '{"items":[],"freeFirst":false}';
      final state = GardenPersistence.decodeZenGarden(json, 0);
      expect(state.freeFirstGrowthEverConsumed, isTrue);
    });

    test('stash filters zero and negative counts', () {
      const json = '{"stash":{"zen.moss_rock":2,"bad":0,"worse":-1,"gone":null}}';
      final state = GardenPersistence.decodeZenGarden(json, 0);
      expect(state.decorStash, {'zen.moss_rock': 2});
    });

    test('unknown theme and mutation fall back safely', () {
      const json =
          '{"items":[{"id":"x","themeId":"unknownTheme","stageIndex":0,"mutation":"unknownMut"}]}';
      final item = GardenPersistence.decodeZenGarden(json, 0).items.single;
      expect(item.themeId, VisualThemeId.zenGarden);
      expect(item.mutation, MutationKind.invertedColors);
    });

    test('missing optional item fields use defaults', () {
      const json = '{"items":[{"id":"min","themeId":"zenGarden","stageIndex":0}]}';
      final item = GardenPersistence.decodeZenGarden(json, 0).items.single;
      expect(item.positionX, 0.5);
      expect(item.positionY, 0.5);
      expect(item.regrowthDiscountActive, isFalse);
    });
  });

  group('encode/decode roundtrip', () {
    test('multiple plants and decor preserve state', () {
      final original = GardenState(
        pointsBalance: 500,
        items: [
          GardenItem(
            id: 'plant-a',
            themeId: VisualThemeId.coralReef,
            stageIndex: 1,
            positionX: 0.1,
            positionY: 0.9,
          ),
          GardenItem(
            id: 'plant-b',
            themeId: VisualThemeId.bonsai,
            stageIndex: 4,
            mutation: MutationKind.invertedColors,
            mutationRolledThisCycle: true,
          ),
        ],
        decor: [
          DecorItem(
            id: 'decor-1',
            themeId: VisualThemeId.zenGarden,
            kind: 'zen.stone_lantern',
            stageIndex: 2,
            positionX: 0.4,
            positionY: 0.6,
            pendingSkipWaitCost: 75,
            nextAdvanceAllowedAt: DateTime.utc(2026, 6, 1, 8),
          ),
        ],
        decorStash: {'zen.moss_rock': 3},
        freeFirstGrowthEverConsumed: false,
        freeFirstGrowthEligibleItemId: 'plant-a',
      );

      final json = GardenPersistence.encodeZenGarden(original);
      final restored = GardenPersistence.decodeZenGarden(json, 999);

      expect(restored.pointsBalance, 999);
      expect(restored.items.length, 2);
      expect(restored.decor.length, 1);
      expect(restored.decorStash['zen.moss_rock'], 3);
      expect(restored.freeFirstGrowthEligibleItemId, 'plant-a');

      final decor = restored.decor.single;
      expect(decor.kind, 'zen.stone_lantern');
      expect(decor.stageIndex, 2);
      expect(decor.nextAdvanceAllowedAt, DateTime.utc(2026, 6, 1, 8));
    });

    test('encode then decode is stable for flags', () {
      final original = GardenState(
        pointsBalance: 1,
        items: const [
          GardenItem(
            id: 'a',
            themeId: VisualThemeId.zenGarden,
            stageIndex: 2,
            awaitingRegrowthForRemutation: true,
            regrowthDiscountActive: true,
          ),
        ],
        freeFirstGrowthEverConsumed: true,
      );
      final roundtrip = GardenPersistence.decodeZenGarden(
        GardenPersistence.encodeZenGarden(original),
        42,
      );
      final item = roundtrip.items.single;
      expect(item.awaitingRegrowthForRemutation, isTrue);
      expect(item.regrowthDiscountActive, isTrue);
      expect(roundtrip.freeFirstGrowthEverConsumed, isTrue);
    });
  });
}
