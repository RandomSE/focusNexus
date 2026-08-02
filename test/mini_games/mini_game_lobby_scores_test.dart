import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_lobby_scores.dart';
import 'package:focusNexus/mini_games/mini_game_progress.dart';

void main() {
  test('formats both duration and endless high scores', () {
    const progress = MiniGameProgress(
      unlocked: true,
      highScore: 12,
      endlessHighScore: 40,
    );
    expect(
      MiniGameLobbyScores.format(progress),
      'Duration high score: 12\nEndless high score: 40',
    );
  });

  test('uses dash placeholders when scores are zero', () {
    expect(
      MiniGameLobbyScores.format(null),
      'Duration high score: -\nEndless high score: -',
    );
    expect(
      MiniGameLobbyScores.format(MiniGameProgress.empty),
      'Duration high score: -\nEndless high score: -',
    );
  });
}
