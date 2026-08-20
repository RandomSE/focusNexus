import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/utils/notifier.dart';

/// Phase timings from the latest bootstrap call (tests / debug).
@visibleForTesting
BootstrapTimings? lastBootstrapTimings;

@visibleForTesting
void clearBootstrapTimingsForTesting() {
  lastBootstrapTimings = null;
}

/// Measured bootstrap phases in milliseconds.
class BootstrapTimings {
  BootstrapTimings({Map<String, int>? phases}) : phases = phases ?? {};

  final Map<String, int> phases;

  void record(String name, int elapsedMs) {
    phases[name] = elapsedMs;
  }
}

void _logPhase(String name, int elapsedMs) {
  debugLog('bootstrap[$name]: ${elapsedMs}ms');
}

Future<T> _timed<T>(
  BootstrapTimings timings,
  String name,
  Future<T> Function() action,
) async {
  final sw = Stopwatch()..start();
  try {
    return await action();
  } finally {
    sw.stop();
    timings.record(name, sw.elapsedMilliseconds);
    _logPhase(name, sw.elapsedMilliseconds);
  }
}

/// Gate-critical startup only: wiring, settings, points, tracking vars.
///
/// Call from [main] before choosing [AppRouteGuard] / [runApp]. Heavy work
/// (achievements, ambient, notifications) belongs in
/// [scheduleDeferredStartupWork].
Future<void> ensureAppReady(ProviderContainer container) async {
  final timings = BootstrapTimings();
  lastBootstrapTimings = timings;
  final total = Stopwatch()..start();

  await _timed(timings, 'gate', () async {
    container.read(goalNotifierWiringProvider);
    container.read(achievementTrackingWiringProvider);
    final repos = container.read(appRepositoriesProvider);
    await Future.wait([
      container.read(appSettingsProvider.notifier).load(),
      repos.points.ensureInitialized(),
      AchievementTrackingVariables().initializeIfNeeded(),
    ]);
  });

  total.stop();
  timings.record('ensureAppReady_total', total.elapsedMilliseconds);
  _logPhase('ensureAppReady_total', total.elapsedMilliseconds);
}

/// Work that can run after the first Flutter frame.
///
/// Includes achievements/backfill, sound cache + ambient prep, and optional
/// notification plugin init. Failures are logged and do not propagate.
Future<void> scheduleDeferredStartupWork({
  required ProviderContainer container,
  bool initializeNotifications = true,
  bool warmAmbient = true,
}) async {
  final timings = lastBootstrapTimings ?? BootstrapTimings();
  lastBootstrapTimings = timings;
  final total = Stopwatch()..start();

  try {
    await _timed(timings, 'deferred', () async {
      final repos = container.read(appRepositoriesProvider);

      await _timed(timings, 'achievements_init', () async {
        await container.read(achievementServiceProvider).initialize();
      });

      await _timed(timings, 'category_backfill', () async {
        await repos.goalsUseCase.backfillCategoryAchievementStats();
      });

      await _timed(timings, 'category_progress', () async {
        await container
            .read(achievementServiceProvider)
            .updateProgressForTrackingKeys({
          StorageKeys.categoriesWithAtLeast1Goal,
          StorageKeys.categoriesWithAtLeast3Goals,
          StorageKeys.categoriesWithAtLeast5Goals,
          StorageKeys.categoriesWithAtLeast10Goals,
          StorageKeys.categoriesWithAtLeast25Goals,
          StorageKeys.categoriesWithAllTypesCompleted,
        });
      });

      // Refresh dashboard claimable badge after catalog is ready.
      container.read(achievementsListRefreshProvider.notifier).bump();

      // Warm the async points provider without blocking first paint.
      await _timed(timings, 'points_balance', () async {
        await container.read(pointsBalanceProvider.future);
      });

      if (warmAmbient) {
        await _timed(timings, 'ambient_warm', () async {
          final sounds = container.read(soundServiceProvider);
          await sounds.warmPlaybackCache();
          final channel = await repos.ambientSoundscapes.resolveForSection(
            AmbientAppSection.dashboard,
          );
          if (channel != null) {
            await sounds.prepareAmbient(channel);
          }
        });
      }

      if (initializeNotifications) {
        await _timed(timings, 'notifications', () async {
          await GoalNotifier.initialize();
        });
      }
    });
  } catch (e, stack) {
    debugLog('Deferred startup work failed: $e\n$stack');
  } finally {
    total.stop();
    timings.record('deferred_wall', total.elapsedMilliseconds);
    _logPhase('deferred_wall', total.elapsedMilliseconds);
  }
}
