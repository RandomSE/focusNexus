import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_unlock.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';

void main() {
  test('unlock via wallet balance >= 10k', () {
    const state = GardenState(pointsBalance: 10000);
    final unlocked = evaluateCherryBlossomUnlock(state);
    expect(unlocked.cherryBlossomTreeUnlocked, isTrue);
  });

  test('unlock via lifetime zen spend >= 10k', () {
    const state = GardenState(
      pointsBalance: 0,
      lifetimeZenPointsSpent: 10000,
    );
    final unlocked = evaluateCherryBlossomUnlock(state);
    expect(unlocked.cherryBlossomTreeUnlocked, isTrue);
  });

  test('stays unlocked after balance drops', () {
    const state = GardenState(
      pointsBalance: 100,
      cherryBlossomTreeUnlocked: true,
      lifetimeZenPointsSpent: 12000,
    );
    final result = evaluateCherryBlossomUnlock(state);
    expect(result.cherryBlossomTreeUnlocked, isTrue);
  });

  test('isCherryBlossomTreeUnlocked reflects live balance before persist flag', () {
    const state = GardenState(pointsBalance: 15000);
    expect(isCherryBlossomTreeUnlocked(state), isTrue);
    expect(state.cherryBlossomTreeUnlocked, isFalse);
  });
}
