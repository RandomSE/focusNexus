import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/utils/notifier.dart';

/// One-time startup: settings, points, achievements, notifications.
/// Call from [main] — not from individual screens.
Future<void> ensureAppReady() async {
  final repos = AppRepositories.instance;
  await repos.settings.load();
  await repos.points.ensureInitialized();
  await AchievementTrackingVariables().initializeIfNeeded();
  await AchievementService().initialize();
  await GoalNotifier.initialize();
}
