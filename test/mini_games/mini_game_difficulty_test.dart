import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_difficulty.dart';

void main() {
  const policy = DefaultMiniGameDifficultyPolicy();

  group('DefaultMiniGameDifficultyPolicy', () {
    test('duration returns base', () {
      expect(
        policy.difficultyFor(base: 2.0, endless: false, tick: 10),
        2.0,
      );
    });

    test('endless scales with tick', () {
      expect(
        policy.difficultyFor(base: 2.0, endless: true, tick: 0),
        2.0,
      );
      expect(
        policy.difficultyFor(base: 2.0, endless: true, tick: 2),
        closeTo(2.0 * (1 + 0.05 * 2), 1e-9),
      );
    });
  });
}
