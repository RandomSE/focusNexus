// lib/services/achievement_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';
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
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';

class AchievementService {
  AchievementService({
    required KeyValueStorage storage,
    AchievementRepository? repository,
    PointsRepository? pointsRepository,
    SoundService? soundService,
    List<Achievement>? cachedAchievements,
  }) : _storage = storage,
       _repository = repository ?? AchievementRepository(storage),
       _pointsRepository = pointsRepository,
       _soundService = soundService ?? SoundService(storage),
       _cachedAchievements = List.of(cachedAchievements ?? []);

  static const _numOfAchievements = 139;

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
  List<int> openStreakRepetitions = [3, 7, 30, 90];

  /// IDs created by [_addOpenStreakAchievements] / [_ensureOpenStreakAchievements].
  static const List<String> openStreakAchievementIds = [
    '114',
    '115',
    '116',
    '117',
  ];

  List<int> fireflyDurationRepetitions = [100, 150, 200, 250];
  static const int fireflyEndlessRepetition = 500;
  List<int> stoneBalanceHeightRepetitions = [25, 35, 40, 50, 60];
  static const int stoneBalanceEndlessRepetition = 500;
  static const int stoneBalanceTimeoutRepetition = 30;
  static const List<int> breathPacerScoreRepetitions = [
    200,
    500,
    1000,
    1500,
    5000,
  ];
  List<int> meteorCatchDurationRepetitions = [15, 35, 80, 100];
  static const int meteorCatchEndlessRepetition = 250;
  static const List<int> meteorCatchStreakRepetitions = [10, 20, 30, 40, 50];
  static const int meteorCatchEndlessStreakRepetition = 100;
  static const List<int> wordBloomDurationRepetitions = [
    50,
    100,
    175,
    250,
    350,
  ];
  static const int wordBloomEndlessRepetition = 1000;
  static const List<int> wordBloomStreakRepetitions = [3, 6, 9, 12, 15];
  static const int wordBloomEndlessStreakRepetition = 30;
  static const List<int> rainCatcherDurationRepetitions =
      RainCatcherConstants.durationTiers;
  static const List<int> rainCatcherEndlessRepetitions =
      RainCatcherConstants.endlessTiers;
  static const List<int> rainCatcherStreakRepetitions =
      RainCatcherConstants.streakTiers;
  static const int rainCatcherEndlessStreakRepetition =
      RainCatcherConstants.endlessStreakTarget;

  /// Initialize cache from storage (idempotent - safe to call once at startup).
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
      await _ensureZenGardenAchievements();
      await _ensureOpenStreakAchievements();
      await _ensureFireflyJarAchievements();
      await _ensureStoneBalanceAchievements();
      await _ensurePatientOneAchievement();
      await _ensureBreathPacerAchievements();
      await _ensureMeteorCatchAchievements();
      await _ensureWordBloomAchievements();
      await _ensureRainCatcherAchievements();
    }
    await _sanitizeStoredProgress();
    _initialized = true;
  }

  /// Recomputes all achievement progress from tracking variables (migration/tests only).
  Future<void> recomputeAllProgress() async {
    await _syncTrackingVariablesFromStorage();
    // Use cached catalog IDs (covers gaps such as 112-117); do not dense-loop 1..N.
    for (final achievement in List<Achievement>.from(_cachedAchievements)) {
      await updateProgress(achievement.id);
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

  /// One-time cleanup for retired assistant-create achievements (ids 106-111).
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
      goalsCompletedThisMonth: await readInt(
        StorageKeys.goalsCompletedThisMonth,
      ),
      goalsCompletedWithHighPoints: await readInt(
        StorageKeys.goalsCompletedWithHighPoints,
      ),
      goalsCompletedWithHighComplexity: await readInt(
        StorageKeys.goalsCompletedWithHighComplexity,
      ),
      goalsCompletedWithHighEffort: await readInt(
        StorageKeys.goalsCompletedWithHighEffort,
      ),
      goalsCompletedWithHighMotivation: await readInt(
        StorageKeys.goalsCompletedWithHighMotivation,
      ),
      goalsCompletedWithAllHigh: await readInt(
        StorageKeys.goalsCompletedWithAllHigh,
      ),
      goalsCompletedWithHighTimeRequirement: await readInt(
        StorageKeys.goalsCompletedWithHighTimeRequirement,
      ),
      goalsCompletedWithManySteps: await readInt(
        StorageKeys.goalsCompletedWithManySteps,
      ),
      goalsCompletedEarly: await readInt(StorageKeys.goalsCompletedEarly),
      datesGoalsCompleted: await readString(StorageKeys.dateGoalsCompleted),
      lastWeekGoalWasCompleted: await readString(
        StorageKeys.lastWeekGoalWasCompleted,
      ),
      lastMonthGoalWasCompleted: await readString(
        StorageKeys.lastMonthGoalWasCompleted,
      ),
      consecutiveDaysWithGoalsCompleted: await readInt(
        StorageKeys.consecutiveDaysWithGoalsCompleted,
      ),
      consecutiveWeeksWithGoalsCompleted: await readInt(
        StorageKeys.consecutiveWeeksWithGoalsCompleted,
      ),
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
      1,
      1,
      // Cherry stage clears (141-147) + Peace/Power (148-149); added with 112/113
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      ...openStreakRepetitions,
      ...fireflyDurationRepetitions,
      fireflyEndlessRepetition,
      ...stoneBalanceHeightRepetitions,
      stoneBalanceEndlessRepetition,
      stoneBalanceTimeoutRepetition,
      1,
      ...breathPacerScoreRepetitions,
      ...meteorCatchDurationRepetitions,
      meteorCatchEndlessRepetition,
      ...meteorCatchStreakRepetitions,
      meteorCatchEndlessStreakRepetition,
      ...wordBloomDurationRepetitions,
      wordBloomEndlessRepetition,
      ...wordBloomStreakRepetitions,
      wordBloomEndlessStreakRepetition,
      ...rainCatcherDurationRepetitions,
      ...rainCatcherEndlessRepetitions,
      ...rainCatcherStreakRepetitions,
      rainCatcherEndlessStreakRepetition,
    ];

    achievementVariableMap = {
      [1, 2, 3]: StorageKeys.totalGoalsCreated,
      [4, 5]: StorageKeys.totalGoalsActive,
      [6, 7, 8]: StorageKeys.totalGoalsCompleted,
      [9, 10, 11]: StorageKeys.goalsCompletedToday,
      [12, 13, 14]: StorageKeys.goalsCompletedThisWeek,
      [15, 16, 17]: StorageKeys.goalsCompletedThisMonth,
      [18, 19, 20, 21, 22, 23, 24, 25, 26]:
          StorageKeys.goalsCompletedWithHighPoints,
      [27, 28, 29, 30, 31, 32, 33, 34, 35]:
          StorageKeys.goalsCompletedWithHighComplexity,
      [36, 37, 38, 39, 40, 41, 42, 43, 44]:
          StorageKeys.goalsCompletedWithHighEffort,
      [45, 46, 47, 48, 49, 50, 51, 52, 53]:
          StorageKeys.goalsCompletedWithHighMotivation,
      [54, 55, 56, 57, 58, 59, 60, 61, 62]:
          StorageKeys.goalsCompletedWithHighTimeRequirement,
      [63, 64, 65, 66, 67, 68, 69, 70, 71]:
          StorageKeys.goalsCompletedWithManySteps,
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
      [112]: StorageKeys.cherryBlossomTreeUnlockedFlag,
      [113]: StorageKeys.cherryBlossomTreeMaxedFlag,
      [141]: StorageKeys.cherryBlossomStage0CompleteFlag,
      [142]: StorageKeys.cherryBlossomStage1CompleteFlag,
      [143]: StorageKeys.cherryBlossomStage2CompleteFlag,
      [144]: StorageKeys.cherryBlossomStage3CompleteFlag,
      [145]: StorageKeys.cherryBlossomStage4CompleteFlag,
      [146]: StorageKeys.cherryBlossomStage5CompleteFlag,
      [147]: StorageKeys.cherryBlossomStage6CompleteFlag,
      [148]: StorageKeys.cherryBlossomPeacePathFlag,
      [149]: StorageKeys.cherryBlossomPowerPathFlag,
      [114, 115, 116, 117]: StorageKeys.consecutiveDaysAppOpened,
      [118, 119, 120, 121]: StorageKeys.fireflyJarBestDuration,
      [122]: StorageKeys.fireflyJarBestEndless,
      [123, 124, 125, 126, 127]: StorageKeys.stoneBalanceBestHeight,
      [128]: StorageKeys.stoneBalanceBestEndless,
      [129]: StorageKeys.stoneBalanceBestTimeoutHeight,
      [130]: StorageKeys.breathBackgroundFullListenFlag,
      [131, 132, 133, 134]: StorageKeys.breathPacerBestDuration,
      [135]: StorageKeys.breathPacerBestEndless,
      [136, 137, 138, 139]: StorageKeys.meteorCatchBestDuration,
      [140]: StorageKeys.meteorCatchBestEndless,
      [150, 151, 152, 153, 154]: StorageKeys.meteorCatchBestStreak,
      [155]: StorageKeys.meteorCatchBestEndlessStreak,
      [156, 157, 158, 159, 160]: StorageKeys.wordBloomBestDuration,
      [161]: StorageKeys.wordBloomBestEndless,
      [162, 163, 164, 165, 166]: StorageKeys.wordBloomBestStreak,
      [167]: StorageKeys.wordBloomBestEndlessStreak,
      [168, 169, 170, 171, 172]: StorageKeys.rainCatcherBestDuration,
      [173, 180, 181, 182, 183, 184, 185, 186, 187]:
          StorageKeys.rainCatcherBestEndless,
      [174, 175, 176, 177, 178]: StorageKeys.rainCatcherBestStreak,
      [179]: StorageKeys.rainCatcherBestEndlessStreak,
    };
  }

  Future<void> addAchievement(Achievement achievement) async {
    final exists = _cachedAchievements.any((a) => a.id == achievement.id);
    if (!exists) {
      _cachedAchievements.add(achievement);
      await _saveToStorage();
    }
  }

  /// Inserts after Sakura Gate / Eternal Bloom so repetition indices stay aligned.
  Future<void> _addAchievementAfterZenGate(Achievement achievement) async {
    final exists = _cachedAchievements.any((a) => a.id == achievement.id);
    if (exists) return;
    const anchorIds = [
      '149',
      '148',
      '147',
      '146',
      '145',
      '144',
      '143',
      '142',
      '141',
      '113',
      '112',
    ];
    var insertAt = -1;
    for (final id in anchorIds) {
      insertAt = _cachedAchievements.indexWhere((a) => a.id == id);
      if (insertAt != -1) break;
    }
    if (insertAt == -1) {
      _cachedAchievements.add(achievement);
    } else {
      _cachedAchievements.insert(insertAt + 1, achievement);
    }
    await _saveToStorage();
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
    debugLog('Achievements not initialized - creating.');

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
    await _addZenGardenAchievements();
    await _addOpenStreakAchievements();
    await _addFireflyJarAchievements();
    await _addStoneBalanceAchievements();
    await _addPatientOneAchievement();
    await _addBreathPacerAchievements();
    await _addMeteorCatchAchievements();
    await _addWordBloomAchievements();
    await _addRainCatcherAchievements();
  }

  Future<void> _addZenGardenAchievements() async {
    await addAchievement(
      Achievement(
        id: '112',
        title: 'Sakura Gate',
        reward: '500 points',
        task: 'Unlock the Cherry Blossom Tree in the Zen garden',
        isSecret: false,
      ),
    );
    await addAchievement(
      Achievement(
        id: '113',
        title: 'Eternal Bloom',
        reward: '5000 points',
        task: 'Fully grow the Cherry Blossom Tree (~1,000,000 points invested)',
        isSecret: true,
      ),
    );
    await _addCherryBlossomStageAndPathAchievements();
  }

  Future<void> _addCherryBlossomStageAndPathAchievements() async {
    const stageNames = [
      'Bare Beginning',
      'Early Spring Morning',
      'Midday Spring',
      'Golden Afternoon',
      'Deep Twilight',
      'Aurora Veil',
      'Living Canopy',
    ];
    const stageTotals = [500, 2500, 12500, 50000, 100000, 500000, 2000000];
    for (var i = 0; i < stageNames.length; i++) {
      final reward = stageTotals[i] * 10 ~/ 100;
      final points = reward < 100 ? 100 : reward;
      await _addAchievementAfterZenGate(
        Achievement(
          id: '${141 + i}',
          title: 'Cherry: ${stageNames[i]}',
          reward: '$points points',
          task: 'Clear Cherry Blossom Tree stage ${stageNames[i]}',
          isSecret: false,
        ),
      );
    }
    await _addAchievementAfterZenGate(
      Achievement(
        id: '148',
        title: 'Path of Peace',
        reward: '500000 points',
        task: 'Complete the Peace finale path on the Cherry Blossom Tree',
        isSecret: true,
      ),
    );
    await _addAchievementAfterZenGate(
      Achievement(
        id: '149',
        title: 'Path of Power',
        reward: '500000 points',
        task: 'Complete the Power finale path on the Cherry Blossom Tree',
        isSecret: true,
      ),
    );
  }

  Future<void> _ensureZenGardenAchievements() async {
    final hasGate = _cachedAchievements.any((a) => a.id == '112');
    final hasStages = _cachedAchievements.any((a) => a.id == '141');
    if (!hasGate) {
      await bulkSetAchievementVariablesInStorage([
        StorageKeys.cherryBlossomTreeUnlockedFlag,
        StorageKeys.cherryBlossomTreeMaxedFlag,
        ...StorageKeys.cherryBlossomStageCompleteFlags,
        StorageKeys.cherryBlossomPeacePathFlag,
        StorageKeys.cherryBlossomPowerPathFlag,
      ]);
      await _addZenGardenAchievements();
      _buildAchievementIdsByVariable();
      return;
    }
    if (!hasStages) {
      await bulkSetAchievementVariablesInStorage([
        ...StorageKeys.cherryBlossomStageCompleteFlags,
        StorageKeys.cherryBlossomPeacePathFlag,
        StorageKeys.cherryBlossomPowerPathFlag,
      ]);
      await _addCherryBlossomStageAndPathAchievements();
      _buildAchievementIdsByVariable();
    }
  }

  Future<void> _addOpenStreakAchievements() async {
    await addAchievement(
      Achievement(
        id: openStreakAchievementIds[0],
        title: 'Open Streak Novice',
        reward: '100 points',
        task: 'Open the app on 3 consecutive days',
        isSecret: false,
      ),
    );
    await addAchievement(
      Achievement(
        id: openStreakAchievementIds[1],
        title: 'Open Streak Regular',
        reward: '250 points',
        task: 'Open the app on 7 consecutive days',
        isSecret: false,
      ),
    );
    await addAchievement(
      Achievement(
        id: openStreakAchievementIds[2],
        title: 'Open Streak Dedicated',
        reward: '1000 points',
        task: 'Open the app on 30 consecutive days',
        isSecret: false,
      ),
    );
    await addAchievement(
      Achievement(
        id: openStreakAchievementIds[3],
        title: 'Ninety Sunrises',
        reward: '5000 points',
        task: 'Open the app on 90 consecutive days',
        isSecret: true,
      ),
    );
  }

  Future<void> _ensureOpenStreakAchievements() async {
    if (_cachedAchievements.any(
      (a) => a.id == openStreakAchievementIds.first,
    )) {
      return;
    }

    await bulkSetAchievementVariablesInStorage([
      StorageKeys.consecutiveDaysAppOpened,
    ]);
    await _addOpenStreakAchievements();
    _buildAchievementIdsByVariable();
  }

  Future<void> _addFireflyJarAchievements() async {
    await addAchievement(
      const Achievement(
        id: '118',
        title: 'Firefly Swarm I',
        reward: '100 points',
        task: 'Catch 100 fireflies in one Duration round of Firefly Jar',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '119',
        title: 'Firefly Swarm II',
        reward: '250 points',
        task: 'Catch 150 fireflies in one Duration round of Firefly Jar',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '120',
        title: 'Firefly Swarm III',
        reward: '500 points',
        task: 'Catch 200 fireflies in one Duration round of Firefly Jar',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '121',
        title: 'Firefly Swarm IV',
        reward: '1000 points',
        task: 'Catch 250 fireflies in one Duration round of Firefly Jar',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '122',
        title: 'Endless Lantern',
        reward: '2500 points',
        task: 'Catch 500 fireflies in one Endless round of Firefly Jar',
        isSecret: false,
      ),
    );
  }

  Future<void> _ensureFireflyJarAchievements() async {
    if (_cachedAchievements.any((a) => a.id == '118')) return;

    await bulkSetAchievementVariablesInStorage([
      StorageKeys.fireflyJarBestDuration,
      StorageKeys.fireflyJarBestEndless,
    ]);
    await _addFireflyJarAchievements();
    _buildAchievementIdsByVariable();
  }

  Future<void> _addStoneBalanceAchievements() async {
    await addAchievement(
      const Achievement(
        id: '123',
        title: 'Cairn Climber I',
        reward: '100 points',
        task: 'Reach height 25 in Stone Balance',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '124',
        title: 'Cairn Climber II',
        reward: '250 points',
        task: 'Reach height 35 in Stone Balance',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '125',
        title: 'Cairn Climber III',
        reward: '500 points',
        task: 'Reach height 40 in Stone Balance',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '126',
        title: 'Cairn Climber IV',
        reward: '1000 points',
        task: 'Reach height 50 in Stone Balance',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '127',
        title: 'Cairn Climber V',
        reward: '2500 points',
        task: 'Reach height 60 in Stone Balance',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '128',
        title: 'Endless Summit',
        reward: '5000 points',
        task: 'Reach height 500 in one Endless round of Stone Balance',
        isSecret: false,
      ),
    );
    await addAchievement(
      const Achievement(
        id: '129',
        title: 'Beat the Clock',
        reward: '250 points',
        task:
            'Reach height 30 before time runs out in a Duration round of Stone Balance',
        isSecret: false,
      ),
    );
  }

  Future<void> _ensureStoneBalanceAchievements() async {
    if (_cachedAchievements.any((a) => a.id == '123')) return;

    await bulkSetAchievementVariablesInStorage([
      StorageKeys.stoneBalanceBestHeight,
      StorageKeys.stoneBalanceBestEndless,
      StorageKeys.stoneBalanceBestTimeoutHeight,
    ]);
    await _addStoneBalanceAchievements();
    _buildAchievementIdsByVariable();
  }

  Future<void> _addPatientOneAchievement() async {
    await addAchievement(
      const Achievement(
        id: '130',
        title: 'Patient One',
        reward: '1000 points',
        task:
            'Listen to the entire Breath background track from Sound effects Preview',
        isSecret: true,
      ),
    );
  }

  Future<void> _ensurePatientOneAchievement() async {
    if (_cachedAchievements.any((a) => a.id == '130')) return;

    await bulkSetAchievementVariablesInStorage([
      StorageKeys.breathBackgroundFullListenFlag,
    ]);
    await _addPatientOneAchievement();
    _buildAchievementIdsByVariable();
  }

  /// Marks full Breath background Preview listen for Patient One (secret).
  Future<List<Achievement>> recordBreathBackgroundFullListen() async {
    final existing = await _storage.read(
      key: StorageKeys.breathBackgroundFullListenFlag,
    );
    if (existing == '1') return const [];
    await _storage.write(
      key: StorageKeys.breathBackgroundFullListenFlag,
      value: '1',
    );
    return updateProgressForTrackingKeys({
      StorageKeys.breathBackgroundFullListenFlag,
    });
  }

  Future<void> _addBreathPacerAchievements() async {
    const definitions = [
      (
        id: '131',
        title: 'First Breath',
        reward: '100 points',
        task: 'Reach 200 points in one Duration round of Breath Pacer',
      ),
      (
        id: '132',
        title: 'Steady Rhythm',
        reward: '250 points',
        task: 'Reach 500 points in one Duration round of Breath Pacer',
      ),
      (
        id: '133',
        title: 'Deep Focus',
        reward: '500 points',
        task: 'Reach 1000 points in one Duration round of Breath Pacer',
      ),
      (
        id: '134',
        title: 'Breath Master',
        reward: '1000 points',
        task: 'Reach 1500 points in one Duration round of Breath Pacer',
      ),
      (
        id: '135',
        title: 'Endless Serenity',
        reward: '2500 points',
        task: 'Reach 5000 points in one Endless round of Breath Pacer',
      ),
    ];
    for (final definition in definitions) {
      await addAchievement(
        Achievement(
          id: definition.id,
          title: definition.title,
          reward: definition.reward,
          task: definition.task,
          isSecret: false,
        ),
      );
    }
  }

  Future<void> _ensureBreathPacerAchievements() async {
    const ids = {'131', '132', '133', '134', '135'};
    if (ids.every((id) => _cachedAchievements.any((a) => a.id == id))) {
      return;
    }
    await bulkSetAchievementVariablesInStorage([
      StorageKeys.breathPacerBestDuration,
      StorageKeys.breathPacerBestEndless,
    ]);
    await _addBreathPacerAchievements();
    _buildAchievementIdsByVariable();
  }

  Future<void> _addMeteorCatchAchievements() async {
    const definitions = [
      (
        id: '136',
        title: 'Meteor Shower I',
        reward: '100 points',
        task: 'Score 15 points in one Duration round of Meteor Catch',
      ),
      (
        id: '137',
        title: 'Meteor Shower II',
        reward: '250 points',
        task: 'Score 35 points in one Duration round of Meteor Catch',
      ),
      (
        id: '138',
        title: 'Meteor Shower III',
        reward: '500 points',
        task: 'Score 80 points in one Duration round of Meteor Catch',
      ),
      (
        id: '139',
        title: 'Meteor Shower IV',
        reward: '1000 points',
        task: 'Score 100 points in one Duration round of Meteor Catch',
      ),
      (
        id: '140',
        title: 'Endless Skies',
        reward: '2500 points',
        task: 'Score 250 points in one Endless round of Meteor Catch',
      ),
      (
        id: '150',
        title: 'Meteor Streak I',
        reward: '100 points',
        task: 'Catch 10 meteors in a row in one Duration round of Meteor Catch',
      ),
      (
        id: '151',
        title: 'Meteor Streak II',
        reward: '250 points',
        task: 'Catch 20 meteors in a row in one Duration round of Meteor Catch',
      ),
      (
        id: '152',
        title: 'Meteor Streak III',
        reward: '500 points',
        task: 'Catch 30 meteors in a row in one Duration round of Meteor Catch',
      ),
      (
        id: '153',
        title: 'Meteor Streak IV',
        reward: '1000 points',
        task: 'Catch 40 meteors in a row in one Duration round of Meteor Catch',
      ),
      (
        id: '154',
        title: 'Meteor Streak V',
        reward: '2500 points',
        task: 'Catch 50 meteors in a row in one Duration round of Meteor Catch',
      ),
      (
        id: '155',
        title: 'Endless Streak',
        reward: '2500 points',
        task:
            'Catch 100 meteors in a row in one Endless round of Meteor Catch',
      ),
    ];
    for (final definition in definitions) {
      await addAchievement(
        Achievement(
          id: definition.id,
          title: definition.title,
          reward: definition.reward,
          task: definition.task,
          isSecret: false,
        ),
      );
    }
  }

  Future<void> _ensureMeteorCatchAchievements() async {
    const scoreIds = {'136', '137', '138', '139', '140'};
    const streakIds = {'150', '151', '152', '153', '154', '155'};
    final hasScore =
        scoreIds.every((id) => _cachedAchievements.any((a) => a.id == id));
    final hasStreak =
        streakIds.every((id) => _cachedAchievements.any((a) => a.id == id));
    if (hasScore && hasStreak) return;

    final keys = <String>[];
    if (!hasScore) {
      keys.addAll([
        StorageKeys.meteorCatchBestDuration,
        StorageKeys.meteorCatchBestEndless,
      ]);
    }
    if (!hasStreak) {
      keys.addAll([
        StorageKeys.meteorCatchBestStreak,
        StorageKeys.meteorCatchBestEndlessStreak,
      ]);
    }
    if (keys.isNotEmpty) {
      await bulkSetAchievementVariablesInStorage(keys);
    }
    await _addMeteorCatchAchievements();
    _buildAchievementIdsByVariable();
  }

  Future<void> _addWordBloomAchievements() async {
    const definitions = [
      (
        id: '156',
        title: 'Word Bloom I',
        reward: '100 points',
        task: 'Score 50 in one Duration round of Word Bloom',
      ),
      (
        id: '157',
        title: 'Word Bloom II',
        reward: '250 points',
        task: 'Score 100 in one Duration round of Word Bloom',
      ),
      (
        id: '158',
        title: 'Word Bloom III',
        reward: '500 points',
        task: 'Score 175 in one Duration round of Word Bloom',
      ),
      (
        id: '159',
        title: 'Word Bloom IV',
        reward: '1000 points',
        task: 'Score 250 in one Duration round of Word Bloom',
      ),
      (
        id: '160',
        title: 'Word Bloom V',
        reward: '2500 points',
        task: 'Score 350 in one Duration round of Word Bloom',
      ),
      (
        id: '161',
        title: 'Endless Lexicon',
        reward: '2500 points',
        task: 'Score 1000 in one Endless round of Word Bloom',
      ),
      (
        id: '162',
        title: 'Order Streak I',
        reward: '100 points',
        task:
            'Reach an order streak of 3 in one Duration round of Word Bloom',
      ),
      (
        id: '163',
        title: 'Order Streak II',
        reward: '250 points',
        task:
            'Reach an order streak of 6 in one Duration round of Word Bloom',
      ),
      (
        id: '164',
        title: 'Order Streak III',
        reward: '500 points',
        task:
            'Reach an order streak of 9 in one Duration round of Word Bloom',
      ),
      (
        id: '165',
        title: 'Order Streak IV',
        reward: '1000 points',
        task:
            'Reach an order streak of 12 in one Duration round of Word Bloom',
      ),
      (
        id: '166',
        title: 'Order Streak V',
        reward: '2500 points',
        task:
            'Reach an order streak of 15 in one Duration round of Word Bloom',
      ),
      (
        id: '167',
        title: 'Endless Order',
        reward: '2500 points',
        task:
            'Reach an order streak of 30 in one Endless round of Word Bloom',
      ),
    ];
    for (final definition in definitions) {
      await addAchievement(
        Achievement(
          id: definition.id,
          title: definition.title,
          reward: definition.reward,
          task: definition.task,
          isSecret: false,
        ),
      );
    }
  }

  Future<void> _ensureWordBloomAchievements() async {
    const wordIds = {'156', '157', '158', '159', '160', '161'};
    const streakIds = {'162', '163', '164', '165', '166', '167'};
    final hasWords =
        wordIds.every((id) => _cachedAchievements.any((a) => a.id == id));
    final hasStreak =
        streakIds.every((id) => _cachedAchievements.any((a) => a.id == id));
    if (hasWords && hasStreak) return;

    final keys = <String>[];
    if (!hasWords) {
      keys.addAll([
        StorageKeys.wordBloomBestDuration,
        StorageKeys.wordBloomBestEndless,
      ]);
    }
    if (!hasStreak) {
      keys.addAll([
        StorageKeys.wordBloomBestStreak,
        StorageKeys.wordBloomBestEndlessStreak,
      ]);
    }
    if (keys.isNotEmpty) {
      await bulkSetAchievementVariablesInStorage(keys);
    }
    await _addWordBloomAchievements();
    _buildAchievementIdsByVariable();
  }

  Future<void> _addRainCatcherAchievements() async {
    final duration = RainCatcherConstants.durationTiers;
    final endless = RainCatcherConstants.endlessTiers;
    final streak = RainCatcherConstants.streakTiers;
    const endlessIds = [
      '173',
      '180',
      '181',
      '182',
      '183',
      '184',
      '185',
      '186',
      '187',
    ];
    const endlessRomans = [
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
    const endlessRewards = [
      '100 points',
      '250 points',
      '500 points',
      '750 points',
      '1000 points',
      '1500 points',
      '2000 points',
      '2500 points',
      '2500 points',
    ];
    final definitions = <({
      String id,
      String title,
      String reward,
      String task,
    })>[
      (
        id: '168',
        title: 'Rain Catcher I',
        reward: '100 points',
        task:
            'Catch ${duration[0]} raindrops in one Duration round of Rain Catcher',
      ),
      (
        id: '169',
        title: 'Rain Catcher II',
        reward: '250 points',
        task:
            'Catch ${duration[1]} raindrops in one Duration round of Rain Catcher',
      ),
      (
        id: '170',
        title: 'Rain Catcher III',
        reward: '500 points',
        task:
            'Catch ${duration[2]} raindrops in one Duration round of Rain Catcher',
      ),
      (
        id: '171',
        title: 'Rain Catcher IV',
        reward: '1000 points',
        task:
            'Catch ${duration[3]} raindrops in one Duration round of Rain Catcher',
      ),
      (
        id: '172',
        title: 'Rain Catcher V',
        reward: '2500 points',
        task:
            'Catch ${duration[4]} raindrops in one Duration round of Rain Catcher',
      ),
      for (var i = 0; i < endless.length; i++)
        (
          id: endlessIds[i],
          title: 'Endless Deluge ${endlessRomans[i]}',
          reward: endlessRewards[i],
          task:
              'Catch ${endless[i]} raindrops in one Endless round of Rain Catcher',
        ),
      (
        id: '174',
        title: 'Rain Streak I',
        reward: '100 points',
        task:
            'Reach a catch streak of ${streak[0]} in one Duration round of Rain Catcher',
      ),
      (
        id: '175',
        title: 'Rain Streak II',
        reward: '250 points',
        task:
            'Reach a catch streak of ${streak[1]} in one Duration round of Rain Catcher',
      ),
      (
        id: '176',
        title: 'Rain Streak III',
        reward: '500 points',
        task:
            'Reach a catch streak of ${streak[2]} in one Duration round of Rain Catcher',
      ),
      (
        id: '177',
        title: 'Rain Streak IV',
        reward: '1000 points',
        task:
            'Reach a catch streak of ${streak[3]} in one Duration round of Rain Catcher',
      ),
      (
        id: '178',
        title: 'Rain Streak V',
        reward: '2500 points',
        task:
            'Reach a catch streak of ${streak[4]} in one Duration round of Rain Catcher',
      ),
      (
        id: '179',
        title: 'Endless Rain Streak',
        reward: '2500 points',
        task:
            'Reach a catch streak of ${RainCatcherConstants.endlessStreakTarget} in one Endless round of Rain Catcher',
      ),
    ];
    for (final definition in definitions) {
      await addAchievement(
        Achievement(
          id: definition.id,
          title: definition.title,
          reward: definition.reward,
          task: definition.task,
          isSecret: false,
        ),
      );
    }
  }

  Future<void> _ensureRainCatcherAchievements() async {
    const durationIds = {'168', '169', '170', '171', '172'};
    const endlessIds = {
      '173',
      '180',
      '181',
      '182',
      '183',
      '184',
      '185',
      '186',
      '187',
    };
    const streakIds = {'174', '175', '176', '177', '178', '179'};
    final hasDuration =
        durationIds.every((id) => _cachedAchievements.any((a) => a.id == id));
    final hasEndless =
        endlessIds.every((id) => _cachedAchievements.any((a) => a.id == id));
    final hasStreak =
        streakIds.every((id) => _cachedAchievements.any((a) => a.id == id));
    if (hasDuration && hasEndless && hasStreak) {
      await _syncRainCatcherAchievementCopy();
      return;
    }

    final keys = <String>[
      StorageKeys.rainCatcherBestDuration,
      StorageKeys.rainCatcherBestEndless,
      StorageKeys.rainCatcherBestStreak,
      StorageKeys.rainCatcherBestEndlessStreak,
    ];
    await bulkSetAchievementVariablesInStorage(keys);
    await _addRainCatcherAchievements();
    await _reorderRainCatcherAchievements();
    await _syncRainCatcherAchievementCopy();
    _buildAchievementIdsByVariable();
  }

  /// Keeps Rain Catcher rows contiguous so repetition indices stay aligned.
  Future<void> _reorderRainCatcherAchievements() async {
    const order = [
      '168',
      '169',
      '170',
      '171',
      '172',
      '173',
      '180',
      '181',
      '182',
      '183',
      '184',
      '185',
      '186',
      '187',
      '174',
      '175',
      '176',
      '177',
      '178',
      '179',
    ];
    final byId = {
      for (final a in _cachedAchievements) a.id: a,
    };
    if (!order.every(byId.containsKey)) return;
    final others =
        _cachedAchievements.where((a) => !order.contains(a.id)).toList();
    final rain = [for (final id in order) byId[id]!];
    final insertAt = others.indexWhere((a) => int.parse(a.id) > 167);
    if (insertAt == -1) {
      _cachedAchievements
        ..clear()
        ..addAll([...others, ...rain]);
    } else {
      _cachedAchievements
        ..clear()
        ..addAll([
          ...others.sublist(0, insertAt),
          ...rain,
          ...others.sublist(insertAt),
        ]);
    }
    await _saveToStorage();
  }

  Future<void> _syncRainCatcherAchievementCopy() async {
    final duration = RainCatcherConstants.durationTiers;
    final endless = RainCatcherConstants.endlessTiers;
    final streak = RainCatcherConstants.streakTiers;
    const endlessIds = [
      '173',
      '180',
      '181',
      '182',
      '183',
      '184',
      '185',
      '186',
      '187',
    ];
    const endlessRomans = [
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
    final desired = <String, (String title, String task)>{
      '168': (
        'Rain Catcher I',
        'Catch ${duration[0]} raindrops in one Duration round of Rain Catcher',
      ),
      '169': (
        'Rain Catcher II',
        'Catch ${duration[1]} raindrops in one Duration round of Rain Catcher',
      ),
      '170': (
        'Rain Catcher III',
        'Catch ${duration[2]} raindrops in one Duration round of Rain Catcher',
      ),
      '171': (
        'Rain Catcher IV',
        'Catch ${duration[3]} raindrops in one Duration round of Rain Catcher',
      ),
      '172': (
        'Rain Catcher V',
        'Catch ${duration[4]} raindrops in one Duration round of Rain Catcher',
      ),
      for (var i = 0; i < endless.length; i++)
        endlessIds[i]: (
          'Endless Deluge ${endlessRomans[i]}',
          'Catch ${endless[i]} raindrops in one Endless round of Rain Catcher',
        ),
      '174': (
        'Rain Streak I',
        'Reach a catch streak of ${streak[0]} in one Duration round of Rain Catcher',
      ),
      '175': (
        'Rain Streak II',
        'Reach a catch streak of ${streak[1]} in one Duration round of Rain Catcher',
      ),
      '176': (
        'Rain Streak III',
        'Reach a catch streak of ${streak[2]} in one Duration round of Rain Catcher',
      ),
      '177': (
        'Rain Streak IV',
        'Reach a catch streak of ${streak[3]} in one Duration round of Rain Catcher',
      ),
      '178': (
        'Rain Streak V',
        'Reach a catch streak of ${streak[4]} in one Duration round of Rain Catcher',
      ),
      '179': (
        'Endless Rain Streak',
        'Reach a catch streak of ${RainCatcherConstants.endlessStreakTarget} in one Endless round of Rain Catcher',
      ),
    };
    var changed = false;
    for (var i = 0; i < _cachedAchievements.length; i++) {
      final current = _cachedAchievements[i];
      final want = desired[current.id];
      if (want == null) continue;
      if (current.title == want.$1 && current.task == want.$2) continue;
      _cachedAchievements[i] = current.copyWith(
        title: want.$1,
        task: want.$2,
      );
      changed = true;
    }
    if (changed) await _saveToStorage();
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

  Future<void> bulkSetAchievementVariablesInStorage(
    List<String> variables,
  ) async {
    for (final variable in variables) {
      await _storage.write(key: variable, value: '0');
    }
  }

  Future<void> markCompleted(String id) async {
    final index = _cachedAchievements.indexWhere((a) => a.id == id);
    if (index != -1 && !_cachedAchievements[index].isCompleted) {
      final updated = _cachedAchievements[index].copyWith(
        dateCompleted: CompletionTimestamp.atMinute(),
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
    try {
      final index = _cachedAchievements.indexWhere((a) => a.id == id);
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
      dateCompleted: CompletionTimestamp.atMinute(),
      isCompleted: true,
      progress: 100,
    );
    final reward = currentAchievement.reward;
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

  /// Claim every completable unclaimed achievement. Returns count + points.
  Future<({int claimedCount, int pointsGained})> completeAllClaimable() async {
    final claimable = _cachedAchievements
        .where((a) => !a.isCompleted && a.progress >= 100)
        .toList(growable: false);
    if (claimable.isEmpty) {
      return (claimedCount: 0, pointsGained: 0);
    }
    var pointsGained = 0;
    for (final achievement in claimable) {
      final index = _cachedAchievements.indexWhere((a) => a.id == achievement.id);
      if (index == -1) continue;
      final current = _cachedAchievements[index];
      if (current.isCompleted) continue;
      _cachedAchievements[index] = current.copyWith(
        dateCompleted: CompletionTimestamp.atMinute(),
        isCompleted: true,
        progress: 100,
      );
      if (current.reward.contains('points')) {
        pointsGained += AchievementProgress.parsePointsFromReward(current.reward);
      }
    }
    if (pointsGained > 0) {
      await _addPoints(pointsGained);
    }
    await _saveToStorage();
    await _soundService.playAchievementCompleted();
    return (claimedCount: claimable.length, pointsGained: pointsGained);
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
    _initialized = false;
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
