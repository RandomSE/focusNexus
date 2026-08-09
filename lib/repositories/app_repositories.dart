import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/mini_games/mini_game_progress_repository.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/achievement_repository.dart';
import 'package:focusNexus/repositories/ambient_soundscape_repository.dart';
import 'package:focusNexus/repositories/custom_affirmation_pack_repository.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/progressive_visuals_points_repository.dart';
import 'package:focusNexus/repositories/templates_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/time_window_repeat_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';

/// Shared storage-backed repositories and settings for the app.
class AppRepositories {
  AppRepositories(this.storage)
      : points = PointsRepository(storage),
        progressiveVisualsPoints = ProgressiveVisualsPointsRepository(storage),
        goals = GoalsRepository(storage),
        templates = TemplatesRepository(storage),
        userPrefs = UserPrefsRepository(storage),
        counters = AchievementCountersRepository(storage),
        achievements = AchievementRepository(storage),
        miniGames = MiniGameProgressRepository(storage) {
    theme = ThemeRepository(userPrefs);
    streaks = AchievementStreakService(counters, userPrefs);
    garden = GardenRepository(
      storage,
      points: points,
      progressiveVisualsPoints: progressiveVisualsPoints,
    );
    settings = AppSettings(userPrefs, theme);
    timeWindowRepeats = TimeWindowRepeatRepository(storage);
    ambientSoundscapes = AmbientSoundscapeRepository(storage, points: points);
    phrasePacks = PhrasePackRepository(storage, points: points);
    goalsUseCase = GoalsUseCase(
      goals: goals,
      points: points,
      streaks: streaks,
      settings: settings,
      repeatSeries: timeWindowRepeats,
      progressiveVisualsPoints: progressiveVisualsPoints,
    );
  }

  final KeyValueStorage storage;
  final PointsRepository points;
  final ProgressiveVisualsPointsRepository progressiveVisualsPoints;
  final GoalsRepository goals;
  final TemplatesRepository templates;
  final UserPrefsRepository userPrefs;
  final AchievementCountersRepository counters;
  final AchievementRepository achievements;
  final MiniGameProgressRepository miniGames;
  late final ThemeRepository theme;
  late final AchievementStreakService streaks;
  late final GardenRepository garden;
  late final AppSettings settings;
  late final TimeWindowRepeatRepository timeWindowRepeats;
  late final GoalsUseCase goalsUseCase;
  late final AmbientSoundscapeRepository ambientSoundscapes;
  late final PhrasePackRepository phrasePacks;

  /// Deprecated alias; use [phrasePacks] with [PhrasePackKind].
  PhrasePackRepository get customAffirmationPacks => phrasePacks;

  /// Wipes all persisted data and resets in-memory wallet / ambient caches.
  ///
  /// Callers must also stop [SoundService] ambient/music and invalidate its
  /// playback cache so in-memory audio does not survive into a new account.
  Future<void> wipeAllUserData() async {
    // Drop ambient selection cache before delete so mid-wipe resolves cannot
    // replay stale enabled/track ids against an empty disk.
    ambientSoundscapes.invalidateSelectionCache();
    await storage.deleteAll();
    await points.resetToDefaultBalance();
    await progressiveVisualsPoints.resetToZero();
    await ambientSoundscapes.resetForAccountWipe();
  }
}
