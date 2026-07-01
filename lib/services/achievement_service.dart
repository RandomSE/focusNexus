// lib/services/achievement_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/repositories/achievement_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_progress.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import '../models/classes/achievement.dart';
import 'package:focusNexus/models/achievement_tracking_snapshot.dart';
import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
class AchievementService {
  AchievementService({
    required KeyValueStorage storage,
    AchievementRepository? repository,
    PointsRepository? pointsRepository,
    SoundService? soundService,
    List<Achievement>? cachedAchievements,
  })  : _storage = storage,
        _repository = repository ?? AchievementRepository(storage),
        _pointsRepository = pointsRepository,
        _soundService = soundService ?? SoundService(storage),
        _cachedAchievements = List.of(cachedAchievements ?? []);

  static const _numOfAchievements = 105;

  final KeyValueStorage _storage;
  final AchievementRepository _repository;
  final PointsRepository? _pointsRepository;
  final SoundService _soundService;

  List<Achievement> _cachedAchievements;
  bool _initialized = false;
  Map<String, List<String>> _achievementIdsByVariable = {};

  /// Test-only: count of [updateProgress] invocations.
  @visibleForTesting
  int updateProgressInvocationCount = 0;

  List<Achievement> get all => List.unmodifiable(_cachedAchievements);

  bool get isInitialized => _initialized;

  @visibleForTesting
  void resetInitializedForTesting() {
    _initialized = false;
  }
  late List<int> achievementRepetitions;
  late Map<List<int>, String> achievementVariableMap;

  List<int> repetitionsCreationAndCompletion = [10, 100, 1000];
  List<int> repetitionsActive = [10, 20];
  List<int> repetitionsSingleDay = [3, 5, 10];
  List<int> repetitionsSingleWeek = [5, 10, 20];
  List<int> repetitionsSingleMonth = [10, 25, 50];
  List<int> repetitionsHigh = [3, 5, 10, 25, 50, 100, 250, 500, 1000];
  List<int> repetitionsAllHigh = [3, 5, 10, 25, 50, 100, 250];
  List<int> dailyStreakRepetitions = [2, 3, 7, 14, 30];
  List<int> weeklyStreakRepetitions = [2, 4, 8, 12, 16, 20];
  List<int> categoryTripletsRepetitions = [3, 3, 3, 3, 3];

  /// Initialize cache from storage (idempotent — safe to call once at startup).
  Future<void> initialize() async {
    if (_initialized) return;
    await setInitializationPrerequisites();
    _buildAchievementIdsByVariable();
    final stored = await _repository.loadAll();
    if (stored == null) {
      debugLog('No achievements. creating');
      _cachedAchievements = [];
      await initializeAchievements();
    } else {
      debugLog('Achievements exist.');
      _cachedAchievements = stored;
      await _pruneOrphanedAssistantAchievements();
      await _ensureCategoryAchievements();
    }
    await _sanitizeStoredProgress();
    _initialized = true;
  }

  /// Recomputes all achievement progress from tracking variables (migration/tests only).
  Future<void> recomputeAllProgress() async {
    await _syncTrackingVariablesFromStorage();
    for (var i = 1; i <= _numOfAchievements; i++) {
      await updateProgress(i.toString());
    }
  }

  /// Updates progress only for achievements tied to the given tracking keys.
  ///
  /// Returns achievements that newly reached 100% (completable, not yet claimed).
  Future<List<Achievement>> updateProgressForTrackingKeys(
    Set<String> trackingKeys,
  ) async {
    if (!_initialized) {
      await initialize();
    }
    final ids = <String>{};
    for (final key in trackingKeys) {
      final mapped = _achievementIdsByVariable[key];
      if (mapped != null) ids.addAll(mapped);
    }
    final newlyReady = <Achievement>[];
    for (final id in ids) {
      final ready = await updateProgress(id);
      if (ready != null) newlyReady.add(ready);
    }
    return newlyReady;
  }

  void _buildAchievementIdsByVariable() {
    final reverse = <String, List<String>>{};
    for (final entry in achievementVariableMap.entries) {
      for (final achievementId in entry.key) {
        final id = achievementId.toString();
        final variable = entry.value;
        reverse.putIfAbsent(variable, () => []).add(id);
      }
    }
    for (final list in reverse.values) {
      list.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    }
    _achievementIdsByVariable = reverse;
  }

  Future<void> _sanitizeStoredProgress() async {
    var changed = false;
    for (var i = 0; i < _cachedAchievements.length; i++) {
      final current = _cachedAchievements[i];
      final display = AchievementProgress.displayPercent(
        progress: current.progress,
        isCompleted: current.isCompleted,
      );
      if (display == current.progress) continue;
      _cachedAchievements[i] = current.copyWith(progress: display);
      changed = true;
    }
    if (changed) await _saveToStorage();
  }

  /// One-time cleanup for retired assistant-create achievements (ids 106–111).
  Future<void> _pruneOrphanedAssistantAchievements() async {
    const orphanIds = {'106', '107', '108', '109', '110', '111'};
    const orphanStorageKeys = [
      'goalsCreatedViaAssistant',
      'templatesSavedViaAssistant',
      'timeSlotGoalsCreatedViaAssistant',
      'assistantCreateKindsUsed',
    ];

    final beforeCount = _cachedAchievements.length;
    _cachedAchievements.removeWhere((a) => orphanIds.contains(a.id));
    var changed = beforeCount != _cachedAchievements.length;

    for (final key in orphanStorageKeys) {
      final existing = await _storage.read(key: key);
      if (existing != null) {
        await _storage.delete(key: key);
        changed = true;
      }
    }

    if (changed) await _saveToStorage();
  }

  /// Mirrors scalar counters into the achievement tracking blob (same [KeyValueStorage]).
  Future<void> _syncTrackingVariablesFromStorage() async {
    Future<int> readInt(String key) async {
      final raw = await _storage.read(key: key);
      return int.tryParse(raw ?? '') ?? 0;
    }

    Future<String> readString(String key) async =>
        await _storage.read(key: key) ?? '';

    final snapshot = AchievementTrackingSnapshot(
      totalGoalsCreated: await readInt(StorageKeys.totalGoalsCreated),
      totalGoalsActive: await readInt(StorageKeys.totalGoalsActive),
      totalGoalsCompleted: await readInt(StorageKeys.totalGoalsCompleted),
      goalsCompletedToday: await readInt(StorageKeys.goalsCompletedToday),
      goalsCompletedThisWeek: await readInt(StorageKeys.goalsCompletedThisWeek),
      goalsCompletedThisMonth: await readInt(StorageKeys.goalsCompletedThisMonth),
      goalsCompletedWithHighPoints:
          await readInt(StorageKeys.goalsCompletedWithHighPoints),
      goalsCompletedWithHighComplexity:
          await readInt(StorageKeys.goalsCompletedWithHighComplexity),
      goalsCompletedWithHighEffort:
          await readInt(StorageKeys.goalsCompletedWithHighEffort),
      goalsCompletedWithHighMotivation:
          await readInt(StorageKeys.goalsCompletedWithHighMotivation),
      goalsCompletedWithAllHigh: await readInt(StorageKeys.goalsCompletedWithAllHigh),
      goalsCompletedWithHighTimeRequirement:
          await readInt(StorageKeys.goalsCompletedWithHighTimeRequirement),
      goalsCompletedWithManySteps:
          await readInt(StorageKeys.goalsCompletedWithManySteps),
      goalsCompletedEarly: await readInt(StorageKeys.goalsCompletedEarly),
      datesGoalsCompleted: await readString(StorageKeys.dateGoalsCompleted),
      lastWeekGoalWasCompleted:
          await readString(StorageKeys.lastWeekGoalWasCompleted),
      lastMonthGoalWasCompleted:
          await readString(StorageKeys.lastMonthGoalWasCompleted),
      consecutiveDaysWithGoalsCompleted:
          await readInt(StorageKeys.consecutiveDaysWithGoalsCompleted),
      consecutiveWeeksWithGoalsCompleted:
          await readInt(StorageKeys.consecutiveWeeksWithGoalsCompleted),
    );

    await _storage.write(
      key: StorageKeys.achievementTrackingData,
      value: jsonEncode(snapshot.toJson()),
    );
  }

  Future<void> _saveToStorage() async {
    await _repository.saveAll(_cachedAchievements);
  }
  Future<void> setInitializationPrerequisites() async {
    achievementRepetitions = [
      ...repetitionsCreationAndCompletion,
      ...repetitionsActive,
      ...repetitionsCreationAndCompletion,
      ...repetitionsSingleDay,
      ...repetitionsSingleWeek,
      ...repetitionsSingleMonth,
      ...repetitionsHigh,
      ...repetitionsHigh,
      ...repetitionsHigh,
      ...repetitionsHigh,
      ...repetitionsHigh,
      ...repetitionsHigh,
      ...repetitionsAllHigh,
      ...repetitionsHigh,
      ...dailyStreakRepetitions,
      31,
      ...weeklyStreakRepetitions,
      ...categoryTripletsRepetitions,
      kGoalCategoryCount,
    ];

    achievementVariableMap = {
      [1, 2, 3]: StorageKeys.totalGoalsCreated,
      [4, 5]: StorageKeys.totalGoalsActive,
      [6, 7, 8]: StorageKeys.totalGoalsCompleted,
      [9, 10, 11]: StorageKeys.goalsCompletedToday,
      [12, 13, 14]: StorageKeys.goalsCompletedThisWeek,
      [15, 16, 17]: StorageKeys.goalsCompletedThisMonth,
      [18, 19, 20, 21, 22, 23, 24, 25, 26]: StorageKeys.goalsCompletedWithHighPoints,
      [27, 28, 29, 30, 31, 32, 33, 34, 35]: StorageKeys.goalsCompletedWithHighComplexity,
      [36, 37, 38, 39, 40, 41, 42, 43, 44]: StorageKeys.goalsCompletedWithHighEffort,
      [45, 46, 47, 48, 49, 50, 51, 52, 53]: StorageKeys.goalsCompletedWithHighMotivation,
      [54, 55, 56, 57, 58, 59, 60, 61, 62]: StorageKeys.goalsCompletedWithHighTimeRequirement,
      [63, 64, 65, 66, 67, 68, 69, 70, 71]: StorageKeys.goalsCompletedWithManySteps,
      [72, 73, 74, 75, 76, 77, 78]: StorageKeys.goalsCompletedWithAllHigh,
      [79, 80, 81, 82, 83, 84, 85, 86, 87]: StorageKeys.goalsCompletedEarly,
      [88, 89, 90, 91, 92, 93]: StorageKeys.consecutiveDaysWithGoalsCompleted,
      [94, 95, 96, 97, 98, 99]: StorageKeys.consecutiveWeeksWithGoalsCompleted,
      [100]: StorageKeys.categoriesWithAtLeast1Goal,
      [101]: StorageKeys.categoriesWithAtLeast3Goals,
      [102]: StorageKeys.categoriesWithAtLeast5Goals,
      [103]: StorageKeys.categoriesWithAtLeast10Goals,
      [104]: StorageKeys.categoriesWithAtLeast25Goals,
      [105]: StorageKeys.categoriesWithAllTypesCompleted,
    };
  }

  Future<void> addAchievement(Achievement achievement) async {
    final exists = _cachedAchievements.any((a) => a.id == achievement.id);
    if (!exists) {
      _cachedAchievements.add(achievement);
      await _saveToStorage();
    }
  }

  Future<void> addBulkAchievements(
    int startingId,
    String titlePrefix,
    bool isSecret,
    String taskPrefix,
    List<int> pointRewards,
    List<int> repetitions,
    int goalsToCreate, {
    String taskSuffix = ' times',
  }) async {
    const romanNumerals = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
    ];

    for (var i = 0; i < goalsToCreate; i++) {
      final id = (startingId + i).toString();
      final title = '$titlePrefix${romanNumerals[i]}';
      final reward = '${pointRewards[i]} points';
      final task = '$taskPrefix ${repetitions[i]}$taskSuffix';

      await addAchievement(
        Achievement(
          id: id,
          title: title,
          reward: reward,
          task: task,
          isSecret: isSecret,
        ),
      );
    }
  }

  Future<void> initializeAchievements() async {
    debugLog('Achievements not initialized — creating.');

    final achievementVariables = achievementVariableMap.values.toList();
    await bulkSetAchievementVariablesInStorage(achievementVariables);

    const numBasicAchievements = 3;
    const numHighAchievements = 9;
    const pointRewardsCreationAndCompletion = [100, 250, 1000];
    const pointRewardsSingleDay = [100, 250, 500];
    const pointRewardsSingleWeek = [250, 500, 1000];
    const pointRewardsSingleMonth = [250, 500, 1000];
    const pointRewardsHigh = [100, 200, 250, 500, 750, 1000, 1500, 2000, 3000];
    const pointRewardsAllHigh = [1000, 2000, 3000, 4000, 5000, 7500, 10000];
    const pointRewardsDailyStreak = [100, 1000, 250, 500, 1000];
    const pointRewardsWeeklyStreak = [250, 500, 1000, 1500, 2000, 2500];

    await addBulkAchievements(
      1,
      'Goal Setter ',
      false,
      'Create goals',
      pointRewardsCreationAndCompletion,
      repetitionsCreationAndCompletion,
      numBasicAchievements,
    );
    await addAchievement(
      Achievement(
        id: '4',
        title: 'Juggler I',
        reward: '100 points',
        task: 'Have 10 active goals simultaneously',
        isSecret: true,
      ),
    );
    await addAchievement(
      Achievement(
        id: '5',
        title: 'Juggler II',
        reward: '250 points',
        task: 'Have 20 active goals simultaneously',
        isSecret: true,
      ),
    );
    await addBulkAchievements(
      6,
      'Completionist ',
      false,
      'Complete goals',
      pointRewardsCreationAndCompletion,
      repetitionsCreationAndCompletion,
      numBasicAchievements,
    );
    await addBulkAchievements(
      9,
      'Daily Driver ',
      false,
      'Complete goals in one day',
      pointRewardsSingleDay,
      repetitionsSingleDay,
      numBasicAchievements,
    );
    await addBulkAchievements(
      12,
      'Weekly Warrior ',
      false,
      'Complete goals in one calendar week',
      pointRewardsSingleWeek,
      repetitionsSingleWeek,
      numBasicAchievements,
    );
    await addBulkAchievements(
      15,
      'Monthly Momentum ',
      false,
      'Complete goals in one calendar month',
      pointRewardsSingleMonth,
      repetitionsSingleMonth,
      numBasicAchievements,
    );
    await addBulkAchievements(
      18,
      'Power Player ',
      false,
      'Complete high-point goals',
      pointRewardsHigh,
      repetitionsHigh,
      numHighAchievements,
    );
    await addBulkAchievements(
      27,
      'Strategist ',
      false,
      'Complete high-complexity goals',
      pointRewardsHigh,
      repetitionsHigh,
      numHighAchievements,
    );
    await addBulkAchievements(
      36,
      'Effort Engine ',
      false,
      'Complete high-effort goals',
      pointRewardsHigh,
      repetitionsHigh,
      numHighAchievements,
    );
    await addBulkAchievements(
      45,
      'Motivation Master ',
      false,
      'Complete high-motivation goals',
      pointRewardsHigh,
      repetitionsHigh,
      numHighAchievements,
    );
    await addBulkAchievements(
      54,
      'Time Titan ',
      false,
      'Complete high-time-requirement goals',
      pointRewardsHigh,
      repetitionsHigh,
      numHighAchievements,
    );
    await addBulkAchievements(
      63,
      'Step Master ',
      false,
      'Complete high-step-requirement goals',
      pointRewardsHigh,
      repetitionsHigh,
      numHighAchievements,
    );
    await addBulkAchievements(
      72,
      'All High Requirements ',
      true,
      'Complete high complexity, effort and motivation goals',
      pointRewardsAllHigh,
      repetitionsAllHigh,
      7,
    );
    await addBulkAchievements(
      79,
      'Early Finisher ',
      false,
      'Complete goals at least 20 hours before deadline times ',
      pointRewardsHigh,
      repetitionsHigh,
      numHighAchievements,
    );
    await addBulkAchievements(
      88,
      'Consistent Completionist ',
      false,
      'Complete at least 1 goal a day',
      pointRewardsDailyStreak,
      dailyStreakRepetitions,
      5,
    );
    await addAchievement(
      Achievement(
        id: '93',
        title: '31-Day Club',
        reward: '1000 points',
        task: 'Complete goals on 31 days in a row',
        isSecret: true,
      ),
    );
    await addBulkAchievements(
      94,
      'Weekly Streak Master ',
      false,
      'Complete at least 1 goal a week',
      pointRewardsWeeklyStreak,
      weeklyStreakRepetitions,
      6,
    );
    await _addCategoryAchievements();
  }

  Future<void> _addCategoryAchievements() async {
    const pointRewardsCategoryTriplets = [100, 250, 500, 750, 1000];
    const categoryThresholds = [1, 3, 5, 10, 25];
    const romanNumerals = ['I', 'II', 'III', 'IV', 'V'];

    for (var i = 0; i < categoryThresholds.length; i++) {
      final threshold = categoryThresholds[i];
      final goalWord = threshold == 1 ? 'goal' : 'goals';
      await addAchievement(
        Achievement(
          id: '${100 + i}',
          title: 'Category Explorer ${romanNumerals[i]}',
          reward: '${pointRewardsCategoryTriplets[i]} points',
          task:
              'Complete at least $threshold $goalWord in each of 3 different categories',
          isSecret: false,
        ),
      );
    }

    await addAchievement(
      Achievement(
        id: '105',
        title: 'Perfectly balanced',
        reward: '1000 points',
        task:
            'Complete at least 1 goal in every category ($kGoalCategoryCount categories)',
        isSecret: true,
      ),
    );
  }

  Future<void> _ensureCategoryAchievements() async {
    if (_cachedAchievements.length >= _numOfAchievements) return;

    final categoryKeys = [
      StorageKeys.goalsCompletedByCategory,
      StorageKeys.categoriesWithAtLeast1Goal,
      StorageKeys.categoriesWithAtLeast3Goals,
      StorageKeys.categoriesWithAtLeast5Goals,
      StorageKeys.categoriesWithAtLeast10Goals,
      StorageKeys.categoriesWithAtLeast25Goals,
      StorageKeys.categoriesWithAllTypesCompleted,
    ];
    await bulkSetAchievementVariablesInStorage(categoryKeys);

    final hasCategoryExplorer = _cachedAchievements.any((a) => a.id == '100');
    if (!hasCategoryExplorer) {
      await _addCategoryAchievements();
    } else if (!_cachedAchievements.any((a) => a.id == '105')) {
      await addAchievement(
        Achievement(
          id: '105',
          title: 'Perfectly balanced',
          reward: '1000 points',
          task:
              'Complete at least 1 goal in every category ($kGoalCategoryCount categories)',
          isSecret: true,
        ),
      );
    }
  }

  Future<void> bulkSetAchievementVariablesInStorage(List<String> variables) async {
    for (final variable in variables) {
      await _storage.write(key: variable, value: '0');
    }
  }

  Future<void> markCompleted(String id) async {
    final index = _cachedAchievements.indexWhere((a) => a.id == id);
    if (index != -1 && !_cachedAchievements[index].isCompleted) {
      final updated = _cachedAchievements[index].copyWith(
        dateCompleted: DateTime.now(),
        isCompleted: true,
        isSecret: false,
        progress: 100,
      );
      _cachedAchievements[index] = updated;
      await _saveToStorage();
    }
  }

  /// Returns the achievement when it newly becomes completable (reaches 100%).
  Future<Achievement?> updateProgress(String id) async {
    updateProgressInvocationCount++;
    try {      final index = _cachedAchievements.indexWhere((a) => a.id == id);
      if (index == -1) {
        debugLog('updateProgress: achievement not found. id: $id');
        return null;
      }
      final variableName = getVariableForAchievement(id);
      if (variableName == null) {
        debugLog('No tracking variable found for achievement $id');
        return null;
      }
      final repetitionsNeeded = achievementRepetitions[index];
      final currentRepetitions = int.parse(
        await getAchievementTrackingVariable(variableName),
      );
      final achievementProgress = AchievementProgress.percentComplete(
        currentRepetitions,
        repetitionsNeeded,
      );

      final currentAchievement = _cachedAchievements[index];
      if (currentAchievement.isCompleted) return null;

      final currentProgress = currentAchievement.progress;
      if (AchievementProgress.shouldBlockProgressDecrease(
        currentProgress,
        achievementProgress,
      )) {
        debugLog('Achievement progress will not decrease here for id: $id.');
        return null;
      }

      final wasCompletable = currentProgress >= 100;
      final nowCompletable = achievementProgress >= 100;

      _cachedAchievements[index] = currentAchievement.copyWith(
        progress: achievementProgress,
      );

      if (currentProgress != achievementProgress) {
        await _saveToStorage();
        debugLog(
          'Achievement successfully saved. title: ${_cachedAchievements[index].title}, progress: ${_cachedAchievements[index].progress}%',
        );
      }

      if (!wasCompletable && nowCompletable) {
        return _cachedAchievements[index];
      }
      return null;
    } catch (e) {
      debugLog('updateProgress: failed. id: $id, error: $e');
      return null;
    }
  }
  Future<void> removeAchievement(String id) async {
    _cachedAchievements.removeWhere((a) => a.id == id);
    await _saveToStorage();
  }

  Future<void> completeAchievement(String id) async {
    debugLog('Achievement completed for id: $id');
    final index = _cachedAchievements.indexWhere((a) => a.id == id);
    final currentAchievement = _cachedAchievements[index];
    if (currentAchievement.isCompleted) {
      debugLog('This achievement is already completed!');
      return;
    }
    _cachedAchievements[index] = currentAchievement.copyWith(
      dateCompleted: DateTime.now(),
      isCompleted: true,
      progress: 100,
    );    final reward = currentAchievement.reward;
    if (reward.contains('points')) {
      final pointsToAdd = AchievementProgress.parsePointsFromReward(reward);
      await _addPoints(pointsToAdd);
    } else {
      debugLog('Special reward spotted. ID: $id reward: $reward');
    }
    await _saveToStorage();
    await _soundService.playAchievementCompleted();
    debugLog(
      'Achievement successfully saved. title: ${_cachedAchievements[index].title}, progress: ${_cachedAchievements[index].progress}%',
    );
  }

  Future<void> _addPoints(int pointsToAdd) async {
    if (pointsToAdd <= 0) return;
    final repo = _pointsRepository;
    if (repo != null) {
      await repo.add(pointsToAdd);
      return;
    }
    final currentPointsString = await _storage.read(key: StorageKeys.points);
    final currentPoints = int.tryParse(currentPointsString ?? '0') ?? 0;
    await _storage.write(
      key: StorageKeys.points,
      value: (currentPoints + pointsToAdd).toString(),
    );
  }

  Future<void> clearAll() async {
    _cachedAchievements = [];
    await _repository.clear();
  }
  Achievement? getById(String id) {
    try {
      return _cachedAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      debugLog('getByID: failed. id: $id');
      return null;
    }
  }

  Future<String> getAchievementTrackingVariable(String key) async {
    final storedValue = await _storage.read(key: key);
    if (storedValue == null || storedValue.isEmpty) {
      return '0';
    }
    return storedValue;
  }

  String? getVariableForAchievement(String id) {
    final achievementId = int.parse(id);
    for (final entry in achievementVariableMap.entries) {
      if (entry.key.contains(achievementId)) {
        return entry.value;
      }
    }
    return null;
  }
}
