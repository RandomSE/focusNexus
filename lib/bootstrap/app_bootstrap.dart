import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/notifier.dart';

/// One-time startup: settings, points, achievements cache.
/// Call from [main] with the root [ProviderContainer] — not from individual screens.
///
/// Notification init is deferred via [scheduleDeferredStartupWork].
Future<void> ensureAppReady(ProviderContainer container) async {
  container.read(goalNotifierWiringProvider);
  container.read(achievementTrackingWiringProvider);
  final repos = container.read(appRepositoriesProvider);
  await Future.wait([
    container.read(appSettingsProvider.notifier).load(),
    repos.points.ensureInitialized(),
    AchievementTrackingVariables().initializeIfNeeded(),
  ]);
  await container.read(achievementServiceProvider).initialize();
  await repos.goalsUseCase.backfillCategoryAchievementStats();
  await container.read(achievementServiceProvider).updateProgressForTrackingKeys({
    StorageKeys.categoriesWithAtLeast1Goal,
    StorageKeys.categoriesWithAtLeast3Goals,
    StorageKeys.categoriesWithAtLeast5Goals,
    StorageKeys.categoriesWithAtLeast10Goals,
    StorageKeys.categoriesWithAtLeast25Goals,
    StorageKeys.categoriesWithAllTypesCompleted,
  });
  await container.read(pointsBalanceProvider.future);
}

/// Heavy work that can run after [runApp] (notifications only).
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
  } catch (e, stack) {
    debugPrint('Deferred startup work failed: $e\n$stack');
  }
}
