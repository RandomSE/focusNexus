import 'package:focusNexus/goals/goals_controller.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/garden_repository.dart';
import 'package:focusNexus/repositories/goals_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/templates_repository.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/achievement_streak_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/services/storage/flutter_secure_key_value_storage.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/utils/notifier.dart';

/// Shared storage-backed repositories and settings for the app.
class AppRepositories {
  AppRepositories._(this.storage)
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
    goalsController = GoalsController(goalsUseCase);
    _wireServices();
  }

  static AppRepositories? _instance;

  static AppRepositories get instance {
    _instance ??= AppRepositories._(const FlutterSecureKeyValueStorage());
    return _instance!;
  }

  static void configureForTesting(KeyValueStorage storage) {
    _instance = AppRepositories._(storage);
  }

  static void resetForTesting() {
    _instance = null;
  }

  void _wireServices() {
    AchievementService.storage = storage;
    GoalNotifier.storage = storage;
    SoundService.storage = storage;
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
  late final GoalsController goalsController;
}
