import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/category_achievement_tracking.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late CategoryAchievementTracking tracking;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    tracking = CategoryAchievementTracking(AchievementCountersRepository(storage));
  });

  test('recordCompletion increments per-category counts and thresholds', () async {
    await tracking.recordCompletion('Health');
    await tracking.recordCompletion('Health');
    await tracking.recordCompletion('Work');

    final counts = await tracking.readCategoryCounts();
    expect(counts['Health'], 2);
    expect(counts['Work'], 1);

    final counters = AchievementCountersRepository(storage);
    expect(await counters.readInt(StorageKeys.categoriesWithAtLeast1Goal), 2);
    expect(await counters.readInt(StorageKeys.categoriesWithAtLeast3Goals), 0);
    expect(
      await counters.readInt(StorageKeys.categoriesWithAllTypesCompleted),
      2,
    );
  });

  test('threshold counts reflect three qualifying categories', () async {
    for (final category in ['Health', 'Work', 'Learning']) {
      for (var i = 0; i < 3; i++) {
        await tracking.recordCompletion(category);
      }
    }

    final counters = AchievementCountersRepository(storage);
    expect(await counters.readInt(StorageKeys.categoriesWithAtLeast1Goal), 3);
    expect(await counters.readInt(StorageKeys.categoriesWithAtLeast3Goals), 3);
    expect(await counters.readInt(StorageKeys.categoriesWithAtLeast5Goals), 0);
  });

  test('categoriesWithAnyCompletion only counts canonical categories', () {
    final counts = {
      'Health': 2,
      'Work': 1,
      'Mystery': 5,
    };
    expect(
      CategoryAchievementTracking.categoriesWithAnyCompletion(counts),
      2,
    );
    expect(kGoalCategoryCount, 8);
  });

  test('backfillFromCompletedGoals runs once when map is empty', () async {
    final completed = [
      GoalSet(
        title: 'A',
        category: 'Social',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: 5,
        deadline: 'no deadline',
        steps: 1,
        points: 10,
        goalId: 1,
      ),
      GoalSet(
        title: 'B',
        category: 'Social',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: 5,
        deadline: 'no deadline',
        steps: 1,
        points: 10,
        goalId: 2,
      ),
    ];

    await tracking.backfillFromCompletedGoals(completed);
    expect((await tracking.readCategoryCounts())['Social'], 2);

    await tracking.backfillFromCompletedGoals(completed);
    expect((await tracking.readCategoryCounts())['Social'], 2);
  });
}
