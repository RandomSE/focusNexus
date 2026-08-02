import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_score.dart';

void main() {
  group('MiniGameScore.scaleHighScore', () {
    test('scales positive raw and difficulty', () {
      expect(MiniGameScore.scaleHighScore(10, 1.5), 15);
      expect(MiniGameScore.scaleHighScore(10, 1.24), 12);
    });

    test('returns 0 when rawScore is not positive', () {
      expect(MiniGameScore.scaleHighScore(0, 2), 0);
      expect(MiniGameScore.scaleHighScore(-5, 2), 0);
    });

    test('returns 0 when difficulty is not positive', () {
      expect(MiniGameScore.scaleHighScore(10, 0), 0);
      expect(MiniGameScore.scaleHighScore(10, -1), 0);
    });
  });
}
