import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';

part 'achievement_catalog_provider.g.dart';

/// In-progress and completed achievement lists (reads initialized service cache).
class AchievementCatalog {
  const AchievementCatalog({
    required this.inProgress,
    required this.completed,
  });

  final List<Achievement> inProgress;
  final List<Achievement> completed;
}

/// Synchronous catalog snapshot from the achievement service cache.
@Riverpod(keepAlive: true)
AchievementCatalog achievementCatalog(Ref ref) {
  ref.watch(achievementsListRefreshProvider);
  final service = ref.watch(achievementServiceProvider);
  final all = service.all;
  return AchievementCatalog(
    inProgress: all
        .where((a) => !a.isSecret)
        .where((a) => !a.isCompleted)
        .toList(),
    completed: all.where((a) => a.isCompleted).toList(),
  );
}
