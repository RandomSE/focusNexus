import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/providers/achievement_ready_toast_provider.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';

/// After mini-game (or other) progress updates: toast newly ready + refresh lists/dashboard.
void notifyAchievementProgressUpdated(
  WidgetRef ref,
  Iterable<Achievement> newlyReady,
) {
  if (newlyReady.isNotEmpty) {
    ref.read(achievementReadyToastQueueProvider.notifier).enqueueTitles(
          newlyReady.map((a) => a.title),
        );
  }
  ref.read(achievementsListRefreshProvider.notifier).bump();
}
