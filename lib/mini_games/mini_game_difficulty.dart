/// Difficulty for a round given catalog base and mode.
abstract class MiniGameDifficultyPolicy {
  double difficultyFor({
    required double base,
    required bool endless,
    required int tick,
  });
}

/// Duration uses [base]; Endless scales `base * (1 + 0.05 * tick)`.
class DefaultMiniGameDifficultyPolicy implements MiniGameDifficultyPolicy {
  const DefaultMiniGameDifficultyPolicy();

  @override
  double difficultyFor({
    required double base,
    required bool endless,
    required int tick,
  }) {
    if (!endless) return base;
    return base * (1 + 0.05 * tick);
  }
}
