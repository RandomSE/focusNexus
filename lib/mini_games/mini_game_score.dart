/// High-score scaling helpers (no game-specific logic).
abstract final class MiniGameScore {
  /// `round(raw * difficulty)` when both are positive; otherwise `0`.
  static int scaleHighScore(num rawScore, num difficulty) {
    if (rawScore <= 0 || difficulty <= 0) return 0;
    return (rawScore * difficulty).round();
  }
}
