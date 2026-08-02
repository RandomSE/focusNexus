/// Catalog entry for a mini-game (metadata only; no play logic).
class MiniGameDefinition {
  const MiniGameDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockCost,
    required this.playCost,
    required this.endlessCost,
    required this.defaultDurationSeconds,
    required this.baseDifficulty,
    required this.implemented,
    this.hubImageAsset,
  });

  final String id;
  final String title;
  final String description;

  /// Points to unlock once. `<= 0` means free / always unlocked.
  final int unlockCost;

  /// Points charged each Duration round Start.
  final int playCost;

  /// Extra points charged (with [playCost]) when Endless is selected for this round.
  final int endlessCost;

  final int defaultDurationSeconds;
  final double baseDifficulty;

  /// When false, lobby Start is disabled ("Coming soon").
  final bool implemented;

  /// Optional hub thumbnail under `assets/images/mini_games/`. Null = placeholder.
  final String? hubImageAsset;

  bool get isFreeUnlock => unlockCost <= 0;

  /// Total points charged on successful Start for the chosen mode.
  int startCost({required bool endless}) =>
      playCost + (endless ? endlessCost : 0);
}
