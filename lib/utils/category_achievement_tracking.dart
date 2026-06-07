import 'dart:convert';

import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Per-category completion counts and derived threshold metrics for achievements.
class CategoryAchievementTracking {
  CategoryAchievementTracking(this._counters);

  final AchievementCountersRepository _counters;

  static const categoryCompletionThresholds = [1, 3, 5, 10, 25];

  static const thresholdStorageKeys = [
    StorageKeys.categoriesWithAtLeast1Goal,
    StorageKeys.categoriesWithAtLeast3Goals,
    StorageKeys.categoriesWithAtLeast5Goals,
    StorageKeys.categoriesWithAtLeast10Goals,
    StorageKeys.categoriesWithAtLeast25Goals,
  ];

  Future<Map<String, int>> readCategoryCounts() async {
    final raw = await _counters.readString(StorageKeys.goalsCompletedByCategory);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> recordCompletion(String category) async {
    final counts = await readCategoryCounts();
    counts[category] = (counts[category] ?? 0) + 1;
    await _writeCounts(counts);
  }

  Future<void> backfillFromCompletedGoals(List<GoalSet> completed) async {
    final existing = await readCategoryCounts();
    if (existing.isNotEmpty) return;

    final counts = <String, int>{};
    for (final goal in completed) {
      final category = goal.category.trim();
      if (category.isEmpty) continue;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    if (counts.isEmpty) return;
    await _writeCounts(counts);
  }

  Future<void> _writeCounts(Map<String, int> counts) async {
    await _counters.writeString(
      StorageKeys.goalsCompletedByCategory,
      jsonEncode(counts),
    );
    await _persistThresholdCounts(counts);
  }

  static int categoriesMeetingThreshold(
    Map<String, int> counts,
    int threshold,
  ) {
    return counts.values.where((count) => count >= threshold).length;
  }

  Future<void> _persistThresholdCounts(Map<String, int> counts) async {
    for (var i = 0; i < categoryCompletionThresholds.length; i++) {
      final qualifying = categoriesMeetingThreshold(
        counts,
        categoryCompletionThresholds[i],
      );
      await _counters.writeInt(thresholdStorageKeys[i], qualifying);
    }
    await _counters.writeInt(
      StorageKeys.categoriesWithAllTypesCompleted,
      categoriesWithAnyCompletion(counts),
    );
  }

  /// Categories with at least one completion (used by "Perfectly balanced").
  static int categoriesWithAnyCompletion(Map<String, int> counts) {
    return kGoalCategories
        .where((category) => (counts[category] ?? 0) >= 1)
        .length;
  }
}
