import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/rewards/reward_type_selection.dart';

void main() {
  group('RewardTypeSelection', () {
    test('normalizeForLoad orders known values and drops unknowns', () {
      expect(
        RewardTypeSelection.normalizeForLoad([
          'Customization',
          'bogus',
          'Mini-games',
        ]),
        ['Mini-games', 'Customization'],
      );
    });

    test('normalizeForLoad defaults empty to Mini-games', () {
      expect(RewardTypeSelection.normalizeForLoad([]), ['Mini-games']);
      expect(RewardTypeSelection.normalizeForLoad(['nope']), ['Mini-games']);
    });

    test('decode empty or invalid defaults to Mini-games', () {
      expect(RewardTypeSelection.decode(null), ['Mini-games']);
      expect(RewardTypeSelection.decode(''), ['Mini-games']);
      expect(RewardTypeSelection.decode('not-json'), ['Mini-games']);
      expect(RewardTypeSelection.decode('"Mini-games"'), ['Mini-games']);
    });

    test('decode reads rewardTypes JSON in stable order', () {
      expect(
        RewardTypeSelection.decode('["Customization","Mini-games"]'),
        ['Mini-games', 'Customization'],
      );
    });

    test('encode round-trips', () {
      final encoded = RewardTypeSelection.encode([
        'Customization',
        'Mini-games',
      ]);
      expect(
        RewardTypeSelection.decode(encoded),
        ['Mini-games', 'Customization'],
      );
    });

    test('routeForStorageValue maps each kind', () {
      expect(
        RewardTypeSelection.routeForStorageValue('Mini-games'),
        AppRoute.miniGames,
      );
      expect(
        RewardTypeSelection.routeForStorageValue('Progressive visuals'),
        AppRoute.progressiveVisual,
      );
      expect(
        RewardTypeSelection.routeForStorageValue('Customization'),
        AppRoute.customization,
      );
    });
  });
}
