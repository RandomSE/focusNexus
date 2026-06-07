import 'package:intl/intl.dart';

import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/category_achievement_tracking.dart';
import 'package:focusNexus/utils/goal_achievement_eval.dart';
import 'package:focusNexus/utils/streak_logic.dart';

/// Goal-completion streak and achievement counter updates (no widget state).
class AchievementStreakService {
  AchievementStreakService(this._counters, this._prefs);

  final AchievementCountersRepository _counters;
  final UserPrefsRepository _prefs;

  Future<int> readInt(String key) => _counters.readInt(key);

  Future<void> increment(String key) => _counters.increment(key);

  Future<void> incrementBy(String key, int amount) async {
    if (amount <= 0) return;
    final current = await readInt(key);
    await setInt(key, current + amount);
  }

  Future<void> decrement(String key) => _counters.decrement(key);

  Future<void> setInt(String key, int value) => _counters.writeInt(key, value);

  Future<String> readString(String key) async {
    final raw = await _prefs.readString(key);
    return raw ?? '';
  }

  Future<void> writeString(String key, String value) =>
      _prefs.writeString(key, value);

  Future<void> checkOrAddDate() async {
    const key = StorageKeys.dateGoalsCompleted;
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    await checkAndUpdateWeekProgress();
    await checkAndUpdateMonthProgress();

    final extracted = await readString(key);
    final dates = extracted.isNotEmpty
        ? extracted.split(',').map((e) => e.trim()).toList()
        : <String>[];

    if (dates.isNotEmpty && dates.last == today || dates.contains(today)) {
      await updateDailyVariables(dates, today);
      return;
    }

    if (dates.length >= 31) {
      dates.removeAt(0);
    }

    await setInt(StorageKeys.goalsCompletedToday, 1);
    dates.add(today);
    await writeString(key, dates.join(','));
  }

  Future<void> updateDailyVariables(List<String> dates, String dateToday) async {
    await increment(StorageKeys.goalsCompletedToday);

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final formattedYesterday = DateFormat('dd-MM-yyyy').format(yesterday);

    if (dates.contains(formattedYesterday)) {
      await increment(StorageKeys.consecutiveDaysWithGoalsCompleted);
    } else {
      await setInt(StorageKeys.consecutiveDaysWithGoalsCompleted, 1);
    }
  }

  Future<void> checkAndUpdateWeekProgress() async {
    const weekKey = StorageKeys.lastWeekGoalWasCompleted;
    final currentWeek = StreakLogic.getWeekIdentifier(DateTime.now());
    final storedWeek = await readString(weekKey);

    if (storedWeek != currentWeek) {
      await writeString(weekKey, currentWeek);
      await setInt(StorageKeys.goalsCompletedThisWeek, 1);

      if (StreakLogic.isPreviousWeek(storedWeek, currentWeek)) {
        await increment(StorageKeys.consecutiveWeeksWithGoalsCompleted);
      } else {
        await setInt(StorageKeys.consecutiveWeeksWithGoalsCompleted, 1);
      }
    } else {
      await increment(StorageKeys.goalsCompletedThisWeek);
    }
  }

  Future<void> checkAndUpdateMonthProgress() async {
    const monthKey = StorageKeys.lastMonthGoalWasCompleted;
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final storedMonth = await readString(monthKey);

    if (storedMonth != currentMonth) {
      await writeString(monthKey, currentMonth);
      await setInt(StorageKeys.goalsCompletedThisMonth, 1);
    } else {
      await increment(StorageKeys.goalsCompletedThisMonth);
    }
  }

  Future<void> updateCategoryCompletionStats(String category) async {
    await CategoryAchievementTracking(_counters).recordCompletion(category);
  }

  Future<void> backfillCategoryStatsFromGoals(List<GoalSet> completed) async {
    await CategoryAchievementTracking(
      _counters,
    ).backfillFromCompletedGoals(completed);
  }

  Future<void> updateGoalAchievementStats(GoalSet goal) async {
    final increments = GoalAchievementEval.evaluate(goal, DateTime.now());

    if (increments.highPoints) {
      await increment(StorageKeys.goalsCompletedWithHighPoints);
    }
    if (increments.highComplexity) {
      await increment(StorageKeys.goalsCompletedWithHighComplexity);
    }
    if (increments.highEffort) {
      await increment(StorageKeys.goalsCompletedWithHighEffort);
    }
    if (increments.highMotivation) {
      await increment(StorageKeys.goalsCompletedWithHighMotivation);
    }
    if (increments.allHigh) {
      await increment(StorageKeys.goalsCompletedWithAllHigh);
    }
    if (increments.highTimeRequirement) {
      await increment(StorageKeys.goalsCompletedWithHighTimeRequirement);
    }
    if (increments.manySteps) {
      await increment(StorageKeys.goalsCompletedWithManySteps);
    }
    if (increments.completedEarly) {
      await increment(StorageKeys.goalsCompletedEarly);
    }
  }
}
