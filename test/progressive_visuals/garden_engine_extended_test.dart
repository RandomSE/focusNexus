import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/stage_transition_rule.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

import '../helpers/garden_fixtures.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 10, 12);
  final engine = ProgressiveGardenEngine();
  final fastEngine = ProgressiveGardenEngine(
    transitionRules: const [
      StageTransitionRule(fromStageIndex: 0, pointCost: 0),
      StageTransitionRule(fromStageIndex: 1, pointCost: 0),
      StageTransitionRule(fromStageIndex: 2, pointCost: 0),
      StageTransitionRule(fromStageIndex: 3, pointCost: 0),
    ],
    mutationProbability: 1,
  );

  group('failure paths — plants', () {
    test('addPoints rejects negative delta', () {
      final r = engine.addPoints(const GardenState(pointsBalance: 10, items: []), -1);
      expect(r.isSuccess, isFalse);
      expect(r.error, contains('negative'));
    });

    test('removeItem returns failure when id missing', () {
      final r = engine.removeItem(emptyGarden(), 'missing');
      expect(r.isSuccess, isFalse);
    });

    test('moveItem returns failure when id missing', () {
      final r = engine.moveItem(emptyGarden(), 'missing', x: 0.5, y: 0.5);
      expect(r.isSuccess, isFalse);
    });

    test('removeItemsBulk rejects empty selection', () {
      final r = engine.removeItemsBulk(emptyGarden(), {});
      expect(r.isSuccess, isFalse);
      expect(r.error, contains('Nothing selected'));
    });

    test('removeItemsBulk removes partial set and ignores unknown ids', () {
      var state = engine.placeItem(
        state: emptyGarden(),
        id: 'a',
        themeId: VisualThemeId.zenGarden,
      ).state!;
      state = engine.placeItem(state: state, id: 'b', themeId: VisualThemeId.zenGarden).state!;
      final r = engine.removeItemsBulk(state, {'a', 'ghost'});
      expect(r.isSuccess, isTrue);
      expect(r.state!.items.single.id, 'b');
    });

    test('removeItemsBulk fails when none match', () {
      final r = engine.removeItemsBulk(emptyGarden(), {'x'});
      expect(r.isSuccess, isFalse);
    });

    test('advanceGrowth fails when item missing', () {
      final r = engine.advanceGrowth(
        state: emptyGarden(),
        itemId: 'nope',
        now: t0,
      );
      expect(r.isSuccess, isFalse);
    });

    test('advanceGrowth fails when fully grown', () {
      final state = stateAtStage3();
      final mature = fastEngine.advanceGrowth(
        state: state,
        itemId: 'm',
        now: t0,
        random: Random(0),
      ).state!;
      final again = fastEngine.advanceGrowth(
        state: mature,
        itemId: 'm',
        now: t0,
        random: Random(0),
      );
      expect(again.isSuccess, isFalse);
      expect(again.error, contains('fully grown'));
    });

    test('advanceGrowth fails when not enough points', () {
      var state = engine.placeItem(
        state: const GardenState(pointsBalance: 0, items: []),
        id: 'p',
        themeId: VisualThemeId.zenGarden,
      ).state!;
      state = GardenState(
        pointsBalance: 0,
        items: state.items,
        freeFirstGrowthEverConsumed: true,
      );
      final r = engine.advanceGrowth(state: state, itemId: 'p', now: t0);
      expect(r.isSuccess, isFalse);
    });

    test('skipGrowthWait failure paths', () {
      var state = engine.placeItem(
        state: const GardenState(pointsBalance: 100, items: []),
        id: 'w',
        themeId: VisualThemeId.zenGarden,
      ).state!;
      state = engine.advanceGrowth(state: state, itemId: 'w', now: t0).state!;

      expect(engine.skipGrowthWait(state, 'missing', t0).isSuccess, isFalse);
      expect(engine.skipGrowthWait(state, 'w', state.items.single.nextAdvanceAllowedAt!).isSuccess, isFalse);

      final broke = engine.skipGrowthWait(
        GardenState(pointsBalance: 0, items: state.items),
        'w',
        t0,
      );
      expect(broke.isSuccess, isFalse);

      final cleared = engine.skipGrowthWait(state, 'w', t0);
      expect(cleared.isSuccess, isTrue);
      expect(
        engine.skipGrowthWait(cleared.state!, 'w', t0).isSuccess,
        isFalse,
      );
    });

    test('mutation fail roll sets mutationRolledThisCycle without mutation', () {
      final failEngine = ProgressiveGardenEngine(mutationProbability: 0);
      var state = stateAtStage3();
      final r = failEngine.advanceGrowth(
        state: state,
        itemId: 'm',
        now: t0,
        random: Random(0),
      );
      expect(r.isSuccess, isTrue);
      final item = r.state!.items.single;
      expect(item.mutation, isNull);
      expect(item.mutationRolledThisCycle, isTrue);
    });

    test('removeMutation fails without active mutation', () {
      final r = engine.removeMutation(stateAtStage3(), 'm');
      expect(r.isSuccess, isFalse);
    });

    test('restartGrowthCycle fails when insufficient points for cost', () {
      final r = engine.restartGrowthCycle(
        state: const GardenState(pointsBalance: 0, items: []),
        itemId: 'm',
        pointCost: 10,
      );
      expect(r.isSuccess, isFalse);
    });

    test('restartGrowthCycle fails when item missing', () {
      final r = engine.restartGrowthCycle(
        state: emptyGarden(),
        itemId: 'missing',
      );
      expect(r.isSuccess, isFalse);
    });

    test('custom engine without rules throws when advancing unknown stage', () {
      final broken = ProgressiveGardenEngine(transitionRules: const []);
      var state = engine.placeItem(
        state: emptyGarden(),
        id: 'z',
        themeId: VisualThemeId.zenGarden,
      ).state!;
      expect(
        () => broken.advanceGrowth(state: state, itemId: 'z', now: t0),
        throwsStateError,
      );
    });
  });

  group('decor lifecycle', () {
    test('purchaseDecor adds to stash and deducts points', () {
      final r = engine.purchaseDecor(emptyGarden(points: 200), 'zen.moss_rock');
      expect(r.isSuccess, isTrue);
      expect(r.state!.pointsBalance, 150);
      expect(r.state!.decorStash['zen.moss_rock'], 1);
    });

    test('purchaseDecor rejects unknown kind, bad quantity, insufficient points', () {
      expect(engine.purchaseDecor(emptyGarden(), 'unknown.x').isSuccess, isFalse);
      expect(engine.purchaseDecor(emptyGarden(), 'zen.moss_rock', quantity: 0).isSuccess, isFalse);
      expect(engine.purchaseDecor(emptyGarden(points: 10), 'zen.moss_rock').isSuccess, isFalse);
    });

    test('placeDecorFromStash places decor and decrements stash', () {
      var state = engine.purchaseDecor(emptyGarden(points: 200), 'zen.moss_rock', quantity: 2).state!;
      final placed = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.2,
        y: 0.8,
        themeId: VisualThemeId.zenGarden,
      );
      expect(placed.isSuccess, isTrue);
      expect(placed.state!.decor.single.kind, 'zen.moss_rock');
      expect(placed.state!.decorStash['zen.moss_rock'], 1);

      final last = engine.placeDecorFromStash(
        state: placed.state!,
        kind: 'zen.moss_rock',
        id: 'd2',
        x: 0.3,
        y: 0.3,
        themeId: VisualThemeId.zenGarden,
      );
      expect(last.state!.decorStash.containsKey('zen.moss_rock'), isFalse);
    });

    test('placeDecorFromStash failure paths', () {
      expect(
        engine.placeDecorFromStash(
          state: emptyGarden(),
          kind: 'zen.moss_rock',
          id: 'd',
          x: 0.5,
          y: 0.5,
          themeId: VisualThemeId.zenGarden,
        ).isSuccess,
        isFalse,
      );

      var state = engine.purchaseDecor(emptyGarden(points: 100), 'zen.moss_rock').state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.5,
        y: 0.5,
        themeId: VisualThemeId.zenGarden,
      ).state!;
      expect(
        engine.placeDecorFromStash(
          state: state,
          kind: 'zen.moss_rock',
          id: 'd1',
          x: 0.1,
          y: 0.1,
          themeId: VisualThemeId.zenGarden,
        ).isSuccess,
        isFalse,
      );
    });

    test('removeDecor and bulk remove', () {
      var state = engine.purchaseDecor(emptyGarden(points: 200), 'zen.moss_rock', quantity: 2).state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.5,
        y: 0.5,
        themeId: VisualThemeId.zenGarden,
      ).state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd2',
        x: 0.6,
        y: 0.6,
        themeId: VisualThemeId.zenGarden,
      ).state!;

      final removed = engine.removeDecor(state, 'd1');
      expect(removed.state!.decor.single.id, 'd2');

      expect(engine.removeDecor(state, 'ghost').isSuccess, isFalse);
      expect(engine.removeDecorsBulk(state, {}).isSuccess, isFalse);
      expect(engine.removeDecorsBulk(state, {'ghost'}).isSuccess, isFalse);

      final bulk = engine.removeDecorsBulk(state, {'d1', 'd2'});
      expect(bulk.state!.decor, isEmpty);
    });

    test('moveDecor updates coordinates', () {
      var state = engine.purchaseDecor(emptyGarden(points: 100), 'zen.moss_rock').state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.1,
        y: 0.2,
        themeId: VisualThemeId.zenGarden,
      ).state!;
      final moved = engine.moveDecor(state, 'd1', x: 0.9, y: 0.4);
      expect(moved.state!.decor.single.positionX, 0.9);
      expect(engine.moveDecor(state, 'ghost', x: 0, y: 0).isSuccess, isFalse);
    });

    test('advanceDecorGrowth charges and sets wait timer', () {
      var state = engine.purchaseDecor(emptyGarden(points: 500), 'zen.moss_rock').state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.5,
        y: 0.5,
        themeId: VisualThemeId.zenGarden,
      ).state!;

      final grown = engine.advanceDecorGrowth(
        state: state,
        decorId: 'd1',
        now: t0,
        random: Random(0),
      );
      expect(grown.isSuccess, isTrue);
      expect(grown.state!.decor.single.stageIndex, 1);
      expect(grown.state!.decor.single.nextAdvanceAllowedAt, isNotNull);
    });

    test('skipDecorGrowthWait and decor mutation cycle', () {
      var state = engine.purchaseDecor(emptyGarden(points: 500), 'zen.moss_rock').state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.5,
        y: 0.5,
        themeId: VisualThemeId.zenGarden,
      ).state!;
      state = engine.advanceDecorGrowth(state: state, decorId: 'd1', now: t0).state!;

      expect(engine.skipDecorGrowthWait(state, 'missing', t0).isSuccess, isFalse);
      final skipped = engine.skipDecorGrowthWait(state, 'd1', t0);
      expect(skipped.isSuccess, isTrue);

      var matureDecor = DecorItem(
        id: 'd1',
        themeId: VisualThemeId.zenGarden,
        kind: 'zen.moss_rock',
        stageIndex: DecorItem.maxStageIndex - 1,
      );
      state = GardenState(pointsBalance: 500, items: const [], decor: [matureDecor]);
      final mutated = fastEngine.advanceDecorGrowth(
        state: state,
        decorId: 'd1',
        now: t0,
        random: Random(0),
      );
      expect(mutated.isSuccess, isTrue);
      expect(mutated.state!.decor.single.mutation, MutationKind.invertedColors);

      final cleared = engine.removeDecorMutation(mutated.state!, 'd1');
      expect(cleared.state!.decor.single.mutation, isNull);
      expect(engine.removeDecorMutation(cleared.state!, 'd1').isSuccess, isFalse);

      final restarted = engine.restartDecorGrowthCycle(state: mutated.state!, decorId: 'd1');
      expect(restarted.state!.decor.single.stageIndex, 0);

      expect(
        engine.restartDecorGrowthCycle(state: emptyGarden(), decorId: 'x', pointCost: 99).isSuccess,
        isFalse,
      );
    });

    test('advanceDecorGrowth failure paths', () {
      expect(
        engine.advanceDecorGrowth(state: emptyGarden(), decorId: 'x', now: t0).isSuccess,
        isFalse,
      );

      var state = engine.purchaseDecor(emptyGarden(points: 500), 'zen.moss_rock').state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.5,
        y: 0.5,
        themeId: VisualThemeId.zenGarden,
      ).state!;
      state = engine.advanceDecorGrowth(state: state, decorId: 'd1', now: t0).state!;

      expect(
        engine.advanceDecorGrowth(state: state, decorId: 'd1', now: t0).isSuccess,
        isFalse,
      );

      final mature = DecorItem(
        id: 'd1',
        themeId: VisualThemeId.zenGarden,
        kind: 'zen.moss_rock',
        stageIndex: DecorItem.maxStageIndex,
      );
      expect(
        engine.advanceDecorGrowth(
          state: GardenState(pointsBalance: 0, items: const [], decor: [mature]),
          decorId: 'd1',
          now: t0,
        ).isSuccess,
        isFalse,
      );
    });

    test('skipDecorGrowthWait failure paths', () {
      var state = engine.purchaseDecor(emptyGarden(points: 500), 'zen.moss_rock').state!;
      state = engine.placeDecorFromStash(
        state: state,
        kind: 'zen.moss_rock',
        id: 'd1',
        x: 0.5,
        y: 0.5,
        themeId: VisualThemeId.zenGarden,
      ).state!;

      expect(engine.skipDecorGrowthWait(state, 'd1', t0).isSuccess, isFalse);

      state = engine.advanceDecorGrowth(state: state, decorId: 'd1', now: t0).state!;
      expect(
        engine.skipDecorGrowthWait(
          GardenState(pointsBalance: 0, items: const [], decor: state.decor),
          'd1',
          t0,
        ).isSuccess,
        isFalse,
      );
    });
  });

  group('defaultTransitionRules', () {
    test('covers stages 0 through 3', () {
      final rules = defaultTransitionRules();
      expect(rules.map((r) => r.fromStageIndex).toList(), [0, 1, 2, 3]);
      expect(rules.every((r) => r.waitBeforeNextAdvance != null), isTrue);
    });
  });
}
