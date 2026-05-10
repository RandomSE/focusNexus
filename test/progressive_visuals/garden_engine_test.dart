import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/color_math.dart';
import 'package:focusNexus/progressive_visuals/garden_engine.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/stage_transition_rule.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 10, 12);

  test('addPoints increases balance', () {
    const state = GardenState(pointsBalance: 5, items: []);
    final engine = ProgressiveGardenEngine();
    final r = engine.addPoints(state, 30);
    expect(r.isSuccess, isTrue);
    expect(r.state!.pointsBalance, 35);
  });

  test('placeItem rejects duplicate ids', () {
    final engine = ProgressiveGardenEngine();
    final a = engine.placeItem(
      state: const GardenState(pointsBalance: 0, items: []),
      id: 'a',
      themeId: VisualThemeId.coralReef,
    );
    expect(a.isSuccess, isTrue);
    expect(a.state!.freeFirstGrowthEligibleItemId, 'a');
    final b = engine.placeItem(
      state: a.state!,
      id: 'a',
      themeId: VisualThemeId.coralReef,
    );
    expect(b.isSuccess, isFalse);
  });

  test('first growth free only for first placed object, then post-sprout wait', () {
    final engine = ProgressiveGardenEngine();
    var state = engine.placeItem(
      state: const GardenState(pointsBalance: 30, items: []),
      id: 'coral',
      themeId: VisualThemeId.coralReef,
    ).state!;
    expect(state.freeFirstGrowthEligibleItemId, 'coral');
    expect(state.freeFirstGrowthEverConsumed, isFalse);

    final grow = engine.advanceGrowth(
      state: state,
      itemId: 'coral',
      now: t0,
      random: Random(0),
    );
    expect(grow.isSuccess, isTrue);
    state = grow.state!;
    expect(state.pointsBalance, 30);
    expect(state.freeFirstGrowthEverConsumed, isTrue);
    expect(state.freeFirstGrowthEligibleItemId, isNull);
    final item = state.items.single;
    expect(item.stageIndex, 1);
    expect(item.nextAdvanceAllowedAt, t0.add(const Duration(hours: 2)));
    expect(item.pendingSkipWaitCost, 75);
  });

  test('second plant pays for seed to sprout', () {
    final engine = ProgressiveGardenEngine();
    var state = engine.placeItem(
      state: const GardenState(pointsBalance: 60, items: []),
      id: 'first',
      themeId: VisualThemeId.zenGarden,
    ).state!;
    state = engine.advanceGrowth(state: state, itemId: 'first', now: t0, random: Random(0)).state!;
    state = engine.placeItem(state: state, id: 'second', themeId: VisualThemeId.zenGarden).state!;
    expect(state.freeFirstGrowthEverConsumed, isTrue);
    expect(state.freeFirstGrowthEligibleItemId, isNull);

    final r = engine.advanceGrowth(state: state, itemId: 'second', now: t0, random: Random(0));
    expect(r.isSuccess, isTrue);
    expect(r.state!.pointsBalance, 10);
  });

  test('seed plant charges when first-free already consumed', () {
    final engine = ProgressiveGardenEngine();
    var state = GardenState(
      pointsBalance: 60,
      items: const [
        GardenItem(id: 'a', themeId: VisualThemeId.zenGarden, stageIndex: 0),
      ],
      freeFirstGrowthEverConsumed: true,
    );
    final r = engine.advanceGrowth(state: state, itemId: 'a', now: t0, random: Random(0));
    expect(r.isSuccess, isTrue);
    state = r.state!;
    expect(state.pointsBalance, 10);
  });

  test('timer blocks advance until elapsed or skipped', () {
    final engine = ProgressiveGardenEngine();
    var state = engine.placeItem(
      state: const GardenState(pointsBalance: 100, items: []),
      id: 'x',
      themeId: VisualThemeId.constellation,
    ).state!;
    state = engine.advanceGrowth(state: state, itemId: 'x', now: t0, random: Random(0)).state!;

    final blocked = engine.advanceGrowth(
      state: state,
      itemId: 'x',
      now: t0.add(const Duration(hours: 1)),
      random: Random(0),
    );
    expect(blocked.isSuccess, isFalse);

    final skipped = engine.skipGrowthWait(state, 'x', t0.add(const Duration(hours: 1)));
    expect(skipped.isSuccess, isTrue);
    state = skipped.state!;
    expect(state.pointsBalance, 25);

    final advanced = engine.advanceGrowth(
      state: state,
      itemId: 'x',
      now: t0.add(const Duration(hours: 1)),
      random: Random(0),
    );
    expect(advanced.isSuccess, isTrue);
    expect(advanced.state!.items.single.stageIndex, 2);
  });

  test('mutation rolls on final stage when probability forces success', () {
    final engine = ProgressiveGardenEngine(mutationProbability: 1);
    var state = _stateAtStage3();
    final r = engine.advanceGrowth(state: state, itemId: 'm', now: t0, random: Random(0));
    expect(r.isSuccess, isTrue);
    final item = r.state!.items.single;
    expect(item.isFullyGrown, isTrue);
    expect(item.mutation, MutationKind.invertedColors);
  });

  test('mutation does not roll twice in the same cycle', () {
    final engine = ProgressiveGardenEngine(mutationProbability: 1);
    var state = _stateAtStage3();
    state = engine.advanceGrowth(state: state, itemId: 'm', now: t0, random: Random(0)).state!;
    final again = engine.advanceGrowth(state: state, itemId: 'm', now: t0, random: Random(0));
    expect(again.isSuccess, isFalse);
  });

  test('removeMutation clears variant and blocks reroll until regrowth', () {
    final engine = ProgressiveGardenEngine(mutationProbability: 1);
    var state = _stateAtStage3();
    state = engine.advanceGrowth(state: state, itemId: 'm', now: t0, random: Random(0)).state!;
    expect(state.items.single.mutation, isNotNull);

    final cleared = engine.removeMutation(state, 'm');
    expect(cleared.isSuccess, isTrue);
    state = cleared.state!;
    expect(state.items.single.mutation, isNull);
    expect(state.items.single.awaitingRegrowthForRemutation, isTrue);

    final noRoll = ProgressiveGardenEngine(mutationProbability: 1).advanceGrowth(
      state: state,
      itemId: 'm',
      now: t0,
      random: Random(0),
    );
    expect(noRoll.isSuccess, isFalse);
  });

  test('restartGrowthCycle applies one-fifth grow and skip costs until next restart', () {
    final engine = ProgressiveGardenEngine();
    var state = _stateAtStage3();
    state = engine.advanceGrowth(state: state, itemId: 'm', now: t0, random: Random(0)).state!;
    expect(state.items.single.isFullyGrown, isTrue);
    state = engine.restartGrowthCycle(state: state, itemId: 'm').state!;
    final restarted = state.items.single;
    expect(restarted.stageIndex, 0);
    expect(restarted.regrowthDiscountActive, isTrue);

    final grow = engine.advanceGrowth(state: state, itemId: 'm', now: t0, random: Random(0));
    expect(grow.isSuccess, isTrue);
    // Mature step cost 60 (100→40); regrow 0→1 costs 10 with discount (40→30).
    expect(grow.state!.pointsBalance, 30);
    final afterGrow = grow.state!.items.single;
    expect(afterGrow.stageIndex, 1);
    expect(afterGrow.pendingSkipWaitCost, 15);

    final skip = engine.skipGrowthWait(grow.state!, 'm', t0);
    expect(skip.isSuccess, isTrue);
    expect(skip.state!.pointsBalance, 15);
  });

  test('restartGrowthCycle enables a future mutation roll after maturing', () {
    final engine = ProgressiveGardenEngine(mutationProbability: 1);
    var state = _stateAtStage3();
    state = engine.advanceGrowth(state: state, itemId: 'm', now: t0, random: Random(0)).state!;
    state = engine.removeMutation(state, 'm').state!;
    state = engine.restartGrowthCycle(state: state, itemId: 'm').state!;

    state = _growToMature(engine, state, from: 0);
    expect(state.items.single.mutation, MutationKind.invertedColors);
  });

  test('sandbox moveItem updates normalized coordinates', () {
    final engine = ProgressiveGardenEngine();
    var state = engine.placeItem(
      state: const GardenState(pointsBalance: 0, items: []),
      id: 'p',
      themeId: VisualThemeId.sandGarden,
      x: 0.1,
      y: 0.2,
    ).state!;
    final moved = engine.moveItem(state, 'p', x: 0.9, y: 0.4);
    expect(moved.state!.items.single.positionX, 0.9);
    expect(moved.state!.items.single.positionY, 0.4);
  });

  test('invertArgb32 flips RGB and preserves alpha', () {
    const argb = 0xCC112233;
    final inverted = invertArgb32(argb);
    expect((inverted >> 24) & 0xFF, 0xCC);
    expect((inverted >> 16) & 0xFF, 0xEE);
    expect((inverted >> 8) & 0xFF, 0xDD);
    expect(inverted & 0xFF, 0xCC);
  });

  test('custom rules without waits never set timers', () {
    final engine = ProgressiveGardenEngine(
      transitionRules: const [
        StageTransitionRule(fromStageIndex: 0, pointCost: 0),
        StageTransitionRule(fromStageIndex: 1, pointCost: 0),
        StageTransitionRule(fromStageIndex: 2, pointCost: 0),
        StageTransitionRule(fromStageIndex: 3, pointCost: 0),
      ],
    );
    var state = engine.placeItem(
      state: const GardenState(pointsBalance: 0, items: []),
      id: 'q',
      themeId: VisualThemeId.bonsai,
    ).state!;
    state = engine.advanceGrowth(state: state, itemId: 'q', now: t0, random: Random(0)).state!;
    expect(state.items.single.nextAdvanceAllowedAt, isNull);
  });

  test('removing eligible plant before free growth clears eligibility for next', () {
    final engine = ProgressiveGardenEngine();
    var state = engine.placeItem(
      state: const GardenState(pointsBalance: 30, items: []),
      id: 'a',
      themeId: VisualThemeId.zenGarden,
    ).state!;
    expect(state.freeFirstGrowthEligibleItemId, 'a');
    state = engine.removeItem(state, 'a').state!;
    expect(state.freeFirstGrowthEligibleItemId, isNull);
    state = engine.placeItem(state: state, id: 'b', themeId: VisualThemeId.zenGarden).state!;
    expect(state.freeFirstGrowthEligibleItemId, 'b');
    expect(state.freeFirstGrowthEverConsumed, isFalse);
  });
}

GardenState _stateAtStage3() {
  return const GardenState(
    pointsBalance: 100,
    items: [
      GardenItem(
        id: 'm',
        themeId: VisualThemeId.coralReef,
        stageIndex: 3,
      ),
    ],
    freeFirstGrowthEverConsumed: true,
  );
}

GardenState _growToMature(ProgressiveGardenEngine engine, GardenState state, {required int from}) {
  var s = state;
  var stage = from;
  while (stage < GardenItem.maxStageIndex) {
    final custom = ProgressiveGardenEngine(
      transitionRules: const [
        StageTransitionRule(fromStageIndex: 0, pointCost: 0),
        StageTransitionRule(fromStageIndex: 1, pointCost: 0),
        StageTransitionRule(fromStageIndex: 2, pointCost: 0),
        StageTransitionRule(fromStageIndex: 3, pointCost: 0),
      ],
      mutationProbability: engine.mutationProbability,
    );
    final r = custom.advanceGrowth(state: s, itemId: 'm', now: DateTime.utc(2026, 6, stage), random: Random(0));
    expect(r.isSuccess, isTrue);
    s = r.state!;
    stage = s.items.single.stageIndex;
  }
  return s;
}
