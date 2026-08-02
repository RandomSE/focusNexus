import 'package:focusNexus/mini_games/mini_game_progress.dart';

/// Lobby score labels for duration and endless modes.
abstract final class MiniGameLobbyScores {
  static String format(MiniGameProgress? progress) {
    final duration = _label(progress?.highScore ?? 0);
    final endless = _label(progress?.endlessHighScore ?? 0);
    return 'Duration high score: $duration\nEndless high score: $endless';
  }

  static String _label(int score) => score <= 0 ? '-' : '$score';
}
