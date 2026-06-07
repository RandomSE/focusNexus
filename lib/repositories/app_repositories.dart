import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/templates_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/services/storage/flutter_secure_key_value_storage.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';

/// Shared storage-backed repositories and settings for the app.
class AppRepositories {
  AppRepositories(this.storage)
      : points = PointsRepository(storage),
        goals = GoalsRepository(storage),
        templates = TemplatesRepository(storage),
        userPrefs = UserPrefsRepository(storage),
        counters = AchievementCountersRepository(storage) {
    theme = ThemeRepository(userPrefs);
    streaks = AchievementStreakService(counters, userPrefs);
    garden = GardenRepository(storage, points: points);
    settings = AppSettings(userPrefs, theme);
    goalsUseCase = GoalsUseCase(
      goals: goals,
      points: points,
      streaks: streaks,
      settings: settings,
    );
  }

  /// Legacy singleton for tests not yet on [ProviderScope]; prefer [appRepositoriesProvider].
  static AppRepositories? _legacyInstance;

  static AppRepositories get instance {
    _legacyInstance ??= AppRepositories(const FlutterSecureKeyValueStorage());
    return _legacyInstance!;
  }

  static void configureForTesting(KeyValueStorage storage) {
    _legacyInstance = AppRepositories(storage);
  }

  static void resetForTesting() {
    _legacyInstance = null;
  }

  final KeyValueStorage storage;
  final PointsRepository points;
  final GoalsRepository goals;
  final TemplatesRepository templates;
  final UserPrefsRepository userPrefs;
  final AchievementCountersRepository counters;
  late final ThemeRepository theme;
  late final AchievementStreakService streaks;
  late final GardenRepository garden;
  late final AppSettings settings;
  late final GoalsUseCase goalsUseCase;
}
