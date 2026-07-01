import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/achievement_repository.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
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
        goals = GoalsRepository(storage),
        templates = TemplatesRepository(storage),
        userPrefs = UserPrefsRepository(storage),
        counters = AchievementCountersRepository(storage),
        achievements = AchievementRepository(storage) {
    theme = ThemeRepository(userPrefs);
    streaks = AchievementStreakService(counters, userPrefs);
        garden = GardenRepository(storage, points: points);
    settings = AppSettings(userPrefs, theme);
    timeWindowRepeats = TimeWindowRepeatRepository(storage);
    goalsUseCase = GoalsUseCase(
      goals: goals,
      points: points,
      streaks: streaks,
      settings: settings,
      repeatSeries: timeWindowRepeats,
    );
  }

  final KeyValueStorage storage;
  final PointsRepository points;
  final GoalsRepository goals;
  final TemplatesRepository templates;
  final UserPrefsRepository userPrefs;
  final AchievementCountersRepository counters;
  final AchievementRepository achievements;
  late final ThemeRepository theme;
  late final AchievementStreakService streaks;
  late final GardenRepository garden;
  late final AppSettings settings;
  late final TimeWindowRepeatRepository timeWindowRepeats;
  late final GoalsUseCase goalsUseCase;

  /// Wipes all persisted data and resets in-memory wallet cache to default.
  Future<void> wipeAllUserData() async {
    await storage.deleteAll();
    await points.resetToDefaultBalance();
  }
}
