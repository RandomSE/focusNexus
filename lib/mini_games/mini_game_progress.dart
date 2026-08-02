/// Persisted progress for a single mini-game id.
class MiniGameProgress {
  const MiniGameProgress({
    required this.unlocked,
    required this.highScore,
    this.endlessHighScore = 0,
    this.freeDurationEntries = 0,
    this.freeEndlessEntries = 0,
    this.lastPlayedAt,
    this.schemaVersion = currentSchema,
  });

  /// Schema 2+: high scores are raw in-round scores (not difficulty-scaled).
  static const currentSchema = 2;

  /// Complimentary Duration / Endless starts granted on first unlock.
  static const int welcomeFreeEntriesPerMode = 1;

  static const empty = MiniGameProgress(unlocked: false, highScore: 0);

  final bool unlocked;

  /// Best raw score for Duration mode.
  final int highScore;

  /// Best raw score for Endless mode.
  final int endlessHighScore;

  /// Remaining free Duration starts (no points charged).
  final int freeDurationEntries;

  /// Remaining free Endless starts (no points charged).
  final int freeEndlessEntries;

  final DateTime? lastPlayedAt;
  final int schemaVersion;

  int highScoreFor({required bool endless}) =>
      endless ? endlessHighScore : highScore;

  int freeEntriesFor({required bool endless}) =>
      endless ? freeEndlessEntries : freeDurationEntries;

  MiniGameProgress copyWith({
    bool? unlocked,
    int? highScore,
    int? endlessHighScore,
    int? freeDurationEntries,
    int? freeEndlessEntries,
    DateTime? lastPlayedAt,
    int? schemaVersion,
    bool clearLastPlayedAt = false,
  }) {
    return MiniGameProgress(
      unlocked: unlocked ?? this.unlocked,
      highScore: highScore ?? this.highScore,
      endlessHighScore: endlessHighScore ?? this.endlessHighScore,
      freeDurationEntries: freeDurationEntries ?? this.freeDurationEntries,
      freeEndlessEntries: freeEndlessEntries ?? this.freeEndlessEntries,
      lastPlayedAt:
          clearLastPlayedAt ? null : (lastPlayedAt ?? this.lastPlayedAt),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'unlocked': unlocked,
        'highScore': highScore,
        'endlessHighScore': endlessHighScore,
        'freeDurationEntries': freeDurationEntries,
        'freeEndlessEntries': freeEndlessEntries,
        'schemaVersion': schemaVersion,
        if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt!.toIso8601String(),
      };

  factory MiniGameProgress.fromJson(Map<String, dynamic> json) {
    DateTime? lastPlayed;
    final raw = json['lastPlayedAt'];
    if (raw is String && raw.isNotEmpty) {
      lastPlayed = DateTime.tryParse(raw);
    }
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    var highScore = (json['highScore'] as num?)?.toInt() ?? 0;
    var endlessHighScore = (json['endlessHighScore'] as num?)?.toInt() ?? 0;
    // Difficulty-scaled leaderboards inflated scores; reset once to raw schema.
    if (version < currentSchema) {
      highScore = 0;
      endlessHighScore = 0;
    }
    return MiniGameProgress(
      unlocked: json['unlocked'] == true,
      highScore: highScore,
      endlessHighScore: endlessHighScore,
      freeDurationEntries: (json['freeDurationEntries'] as num?)?.toInt() ?? 0,
      freeEndlessEntries: (json['freeEndlessEntries'] as num?)?.toInt() ?? 0,
      lastPlayedAt: lastPlayed,
      schemaVersion: currentSchema,
    );
  }
}
