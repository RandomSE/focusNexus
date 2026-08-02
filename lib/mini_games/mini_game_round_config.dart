/// Config passed into the play stub after a successful lobby Start.
class MiniGameRoundConfig {
  const MiniGameRoundConfig({
    required this.gameId,
    required this.endless,
  });

  final String gameId;
  final bool endless;

  Map<String, Object> toJson() => {
        'gameId': gameId,
        'endless': endless,
      };

  factory MiniGameRoundConfig.fromArguments(Object? arguments) {
    if (arguments is MiniGameRoundConfig) return arguments;
    if (arguments is Map) {
      final id = arguments['gameId']?.toString() ?? '';
      final endless = arguments['endless'] == true;
      return MiniGameRoundConfig(gameId: id, endless: endless);
    }
    return const MiniGameRoundConfig(gameId: '', endless: false);
  }
}
