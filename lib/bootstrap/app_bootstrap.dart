import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/utils/notifier.dart';

/// One-time startup: settings, points, achievements cache.
/// Call from [main] with the root [ProviderContainer] — not from individual screens.
///
/// Notification init and achievement progress recompute are deferred via
/// [scheduleDeferredStartupWork] so the first frame is not blocked.
Future<void> ensureAppReady(ProviderContainer container) async {
  container.read(goalNotifierWiringProvider);
  final repos = container.read(appRepositoriesProvider);
  await Future.wait([
    container.read(appSettingsProvider.notifier).load(),
    repos.points.ensureInitialized(),
    AchievementTrackingVariables().initializeIfNeeded(),
  ]);
  await container.read(achievementServiceProvider).initialize();
  await repos.goalsUseCase.backfillCategoryAchievementStats();
  await container.read(pointsBalanceProvider.future);
}

/// Heavy work that can run after [runApp] (notifications, progress sync).
///
/// Returns a [Future] so callers can await or attach error handling. Failures
/// are logged and do not propagate as unhandled async errors.
Future<void> scheduleDeferredStartupWork({
  required ProviderContainer container,
  bool initializeNotifications = true,
}) async {
  try {
    if (initializeNotifications) {
      await GoalNotifier.initialize();
    }
    await container.read(achievementServiceProvider).recomputeAllProgress();
  } catch (e, stack) {
    debugPrint('Deferred startup work failed: $e\n$stack');
  }
}
