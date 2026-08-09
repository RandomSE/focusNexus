import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/garden_zen_spend.dart';

void main() {
  test('zenSpendableBalance sums PV and points', () {
    const garden = GardenState(
      pointsBalance: 300,
      progressiveVisualsPointsBalance: 700,
    );
    expect(zenSpendableBalance(garden), 1000);
    expect(canAffordZenSpend(garden, 1000), isTrue);
    expect(canAffordZenSpend(garden, 1001), isFalse);
  });

  test('applyZenSpend deducts progressive visuals points first', () {
    const garden = GardenState(
      pointsBalance: 300,
      progressiveVisualsPointsBalance: 700,
    );
    final next = applyZenSpend(garden, 1000);
    expect(next.progressiveVisualsPointsBalance, 0);
    expect(next.pointsBalance, 0);
    expect(next.lifetimeZenPointsSpent, 1000);
  });

  test('applyZenSpend leaves points untouched when PV covers cost', () {
    const garden = GardenState(
      pointsBalance: 500,
      progressiveVisualsPointsBalance: 200,
    );
    final next = applyZenSpend(garden, 150);
    expect(next.progressiveVisualsPointsBalance, 50);
    expect(next.pointsBalance, 500);
  });

  test('applyZenSpend throws when combined wallets cannot cover', () {
    const garden = GardenState(
      pointsBalance: 100,
      progressiveVisualsPointsBalance: 50,
    );
    expect(() => applyZenSpend(garden, 200), throwsStateError);
  });

  test('refundZenSpend restores shared points only', () {
    const garden = GardenState(
      pointsBalance: 10,
      progressiveVisualsPointsBalance: 0,
      lifetimeZenPointsSpent: 40,
    );
    final next = refundZenSpend(garden, 25);
    expect(next.pointsBalance, 35);
    expect(next.progressiveVisualsPointsBalance, 0);
    expect(next.lifetimeZenPointsSpent, 15);
  });
}
