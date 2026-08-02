import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_definition.dart';

void main() {
  group('MiniGameDefinition.startCost', () {
    const game = MiniGameDefinition(
      id: 'demo',
      title: 'Demo',
      description: 'd',
      unlockCost: 100,
      playCost: 10,
      endlessCost: 5,
      defaultDurationSeconds: 60,
      baseDifficulty: 1,
      implemented: false,
    );

    test('duration is playCost only', () {
      expect(game.startCost(endless: false), 10);
    });

    test('endless adds endlessCost', () {
      expect(game.startCost(endless: true), 15);
    });

    test('isFreeUnlock when unlockCost <= 0', () {
      const free = MiniGameDefinition(
        id: 'free',
        title: 'Free',
        description: 'd',
        unlockCost: 0,
        playCost: 1,
        endlessCost: 1,
        defaultDurationSeconds: 30,
        baseDifficulty: 1,
        implemented: false,
      );
      expect(free.isFreeUnlock, isTrue);
    });
  });
}
