// lib/services/achievement_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/classes/achievement.dart';
import '../models/classes/achievement_tracking_variables.dart';
import '../views/AchievementDetailView.dart';

class AchievementService {
  static const _key = 'achievements';
  static final _storage = const FlutterSecureStorage();
  static const _numOfAchievements = 99;

  static List<Achievement> _cachedAchievements = [];
  List<Achievement> get all => _cachedAchievements;
  static late List<int> achievementRepetitions;

  static late Map<List<int>, String> achievementVariableMap;

  List<int> repetitionsCreationAndCompletion = [10, 100, 1000];
  List<int> repetitionsActive = [10, 20];
  List<int> repetitionsSingleDay = [3, 5, 10];
  List<int> repetitionsSingleWeek = [5, 10, 20];
  List<int> repetitionsSingleMonth = [10, 25, 50];
  List<int> repetitionsHigh = [3, 5, 10, 25, 50, 100, 250, 500, 1000];
  List<int> repetitionsAllHigh = [3, 5, 10, 25, 50, 100,250];
  List<int> dailyStreakRepetitions = [2, 3, 7, 14, 30];
  List<int> weeklyStreakRepetitions = [2, 4, 8, 12, 16, 20];

  /// Initialize cache from storage
  Future<void> initialize() async {
    await setInitializationPrerequisites();
    final jsonStr = await _storage.read(key: _key);
    if (jsonStr == null || jsonStr == '') { // no achievements in storage. It can be assumed that the user would have no achievement progress at this point.
      debugPrint("No achievements. creating");
      _cachedAchievements = [];
      await initializeAchievements();
    } else {
      debugPrint('Achievements exist.');
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _cachedAchievements = decoded.map((e) => Achievement.fromJson(e)).toList();
    }
    await AchievementTrackingVariables().load();
    for (int i = 1; i<= _numOfAchievements; i++){
      await updateProgress(i.toString());
    }
  }

  /// Save all cached achievements back to storage
  static Future<void> _saveToStorage() async {
    final encoded = jsonEncode(_cachedAchievements.map((a) => a.toJson()).toList());
    await _storage.write(key: _key, value: encoded);
  }

  /// sets pre-requisites needed during initialization
  Future<void> setInitializationPrerequisites () async {


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
      31, // secret achievement
      ...weeklyStreakRepetitions,
    ];

    achievementVariableMap = {
      [1, 2, 3]: 'totalGoalsCreated',
      [4, 5]: 'totalGoalsActive',
      [6, 7, 8]: 'totalGoalsCompleted',
      [9, 10, 11]: 'goalsCompletedToday',
      [12, 13, 14]: 'goalsCompletedThisWeek',
      [15, 16, 17]: 'goalsCompletedThisMonth',
      [18, 19, 20, 21, 22, 23, 24, 25, 26]: 'goalsCompletedWithHighPoints',
      [27, 28, 29, 30, 31, 32, 33, 34, 35]: 'goalsCompletedWithHighComplexity',
      [36, 37, 38, 39, 40, 41, 42, 43, 44]: 'goalsCompletedWithHighEffort',
      [45, 46, 47, 48, 49, 50, 51, 52, 53]: 'goalsCompletedWithHighMotivation',
      [54, 55, 56, 57, 58, 59, 60, 61, 62]: 'goalsCompletedWithHighTimeRequirement',
      [63, 64, 65, 66, 67, 68, 69, 70, 71]: 'goalsCompletedWithManySteps',
      [72, 73, 74, 75, 76, 77, 78]: 'goalsCompletedWithAllHigh',
      [79, 80, 81, 82, 83, 84, 85, 86, 87]: 'goalsCompletedEarly',
      [88, 89, 90, 91, 92, 93]: 'consecutiveDaysWithGoalsCompleted',
      [94, 95, 96, 97, 98, 99]: 'consecutiveWeeksWithGoalsCompleted',
    };
  }

  /// Add a new achievement (if it doesn't already exist)
  Future<void> addAchievement(Achievement achievement) async { // TODO: Mostly use this to initially initialize achievements. Also use it for sequential secret achievements, consider allowing the AI assistant to make special achievements to assist in motivation?
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
      int goalsToCreate,
      ) async {
    const List<String> romanNumerals = [
      'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'
    ]; // maximum of 9.

    for (int i = 0; i < goalsToCreate; i++) {
      final String id = (startingId + i).toString();
      final String title = '$titlePrefix${romanNumerals[i]}';
      final String reward = '${pointRewards[i]} points';
      // Instead of "prefix: repetition", make it flow naturally
      final String task = '$taskPrefix ${repetitions[i].toString()} times';

      await addAchievement(Achievement(
        id: id,
        title: title,
        reward: reward,
        task: task,
        isSecret: isSecret,
      ));
    }
  }


  Future<void> initializeAchievements() async {
    debugPrint('Achievements not initialized — creating.');

    const int numBasicAchievements = 3;
    const int numHighAchievements = 9;
    List<int> pointRewardsCreationAndCompletion = [100, 250, 1000];
    List<int> pointRewardsSingleDay = [100, 250, 500];
    List<int> pointRewardsSingleWeek = [250, 500, 1000];
    List<int> pointRewardsSingleMonth = [250, 500, 1000];
    List<int> pointRewardsHigh = [100, 200, 250, 500, 750, 1000, 1500, 2000, 3000];
    List<int> pointRewardsAllHigh = [1000, 2000, 3000, 4000, 5000, 7500, 10000];
    List<int> pointRewardsDailyStreak = [100, 1000, 250,  500, 1000];
    List<int> pointRewardsWeeklyStreak = [250, 500, 1000, 1500, 2000, 2500,];

    // Goal creation (1-3)
    await addBulkAchievements(1, 'Goal Setter ', false, 'Create goals', pointRewardsCreationAndCompletion, repetitionsCreationAndCompletion, numBasicAchievements);

    // Active goals (4-5)
    await addAchievement(Achievement(id: '4', title: 'Juggler I', reward: '100 points', task: 'Have 10 active goals simultaneously', isSecret: true));
    await addAchievement(Achievement(id: '5', title: 'Juggler II', reward: '250 points', task: 'Have 20 active goals simultaneously', isSecret: true));

    // Completed goals (6-8)
    await addBulkAchievements(6, 'Completionist ', false, 'Complete goals', pointRewardsCreationAndCompletion, repetitionsCreationAndCompletion, numBasicAchievements);

    // Completions in a single day (9-11)
    await addBulkAchievements(9, 'Daily Driver ', false, 'Complete goals in one day', pointRewardsSingleDay, repetitionsSingleDay, numBasicAchievements);

    // Completions in a single week (12-14)
    await addBulkAchievements(12, 'Weekly Warrior ', false, 'Complete goals in one calendar week', pointRewardsSingleWeek, repetitionsSingleWeek, numBasicAchievements);

    // Completions in a single month (15-17)
    await addBulkAchievements(15, 'Monthly Momentum ', false, 'Complete goals in one calendar month', pointRewardsSingleMonth, repetitionsSingleMonth, numBasicAchievements);

    // High-point goals -> 18-26
    await addBulkAchievements(18, 'Power Player ', false, 'Complete high-point goals', pointRewardsHigh, repetitionsHigh, numHighAchievements);

    // High-complexity goals -> 27-35
    await addBulkAchievements(27, 'Strategist ', false, 'Complete high-complexity goals', pointRewardsHigh, repetitionsHigh, numHighAchievements);

    // High-effort goals -> 36-44
    await addBulkAchievements(36, 'Effort Engine ', false, 'Complete high-effort goals',  pointRewardsHigh, repetitionsHigh, numHighAchievements);

    // High-motivation goals -> 45-53
    await addBulkAchievements(45, 'Motivation Master ', false, 'Complete high-motivation goals', pointRewardsHigh, repetitionsHigh, numHighAchievements);

    // High-time-requirement goals -> 54-62
    await addBulkAchievements(54, 'Time Titan ', false, 'Complete high-time-requirement goals', pointRewardsHigh, repetitionsHigh, numHighAchievements);

    // High-steps-goals -> 63-71
    await addBulkAchievements(63, 'Step Master ', false, 'Complete high-step-requirement goals', pointRewardsHigh, repetitionsHigh, numHighAchievements);

    // All-high goals -> 72 -78
    await addBulkAchievements(72, 'All High Requirements ', true, 'Complete high complexity, effort and motivation goals', pointRewardsAllHigh, repetitionsAllHigh, 7);

    // Early completion - 79-87
    await addBulkAchievements(79, 'Early Finisher ', false, 'Complete goals at least 20 hours before deadline times ', pointRewardsHigh,  repetitionsHigh, numHighAchievements);

    // Daily Streak based achievements -> 88-93
    await addBulkAchievements(88, 'Consistent Completionist ', false, 'Complete at least 1 goal a day', pointRewardsDailyStreak, dailyStreakRepetitions, 5);
    await addAchievement(Achievement(id: '93', title: '31-Day Club', reward: '1000 points', task: 'Complete goals on 31 days in a row', isSecret: true));

    // Weekly Streak based achievements -> 94 - 99
    await addBulkAchievements(94, 'Weekly Streak Master ', false, 'Complete at least 1 goal a week', pointRewardsWeeklyStreak, weeklyStreakRepetitions, 6);

    // Special achievement for 100? TODO

  }

  /// Mark an achievement as completed
  Future<void> markCompleted(String id) async {
    final index = _cachedAchievements.indexWhere((a) => a.id == id);
    if (index != -1 && !_cachedAchievements[index].isCompleted) {
      final updated = Achievement(
          id: _cachedAchievements[index].id,
          title: _cachedAchievements[index].title,
          reward: _cachedAchievements[index].reward,
          task: _cachedAchievements[index].task,
          dateCompleted: DateTime.now(),
          isCompleted: true,
          isSecret: false // once it's completed it's no longer secret.
      );
      _cachedAchievements[index] = updated;
      await _saveToStorage();
    }
  }




  static void viewAchievement(String id,
      ThemeData themeData,
      Color primaryColor,
      Color secondaryColor,
      TextStyle textStyle,
      ButtonStyle buttonStyle,
      BuildContext context) {
    final achievement = getById(id);
    if (achievement == null) {
      debugPrint('Achievement not found: $id');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AchievementDetailView(
          achievement: achievement,
          themeData: themeData,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          textStyle: textStyle,
          buttonStyle: buttonStyle,
          achievementService: AchievementService(),
        ),
      ),
    );
  }

  /// update progress for an achievement
  static Future<void> updateProgress(String id) async {
    try {
      final index = _cachedAchievements.indexWhere((a) => a.id == id);
      if (index == -1) {
        debugPrint('updateProgress: achievement not found. id: $id');
        return;
      }

      final variableName = getVariableForAchievement(id);
      if (variableName == null) {
        debugPrint('No tracking variable found for achievement $id');
        return;
      }

      final repetitionsNeeded = achievementRepetitions[index];
      final currentRepetitions = int.parse(await getAchievementTrackingVariable(variableName));
      final achievementProgress = double.parse(((currentRepetitions / repetitionsNeeded) * 100).toStringAsFixed(1));

      // Update the cached achievement
      final currentAchievement = _cachedAchievements[index];
      final currentProgress = currentAchievement.progress;
      if (_cachedAchievements[index].progress >= 100 && achievementProgress <=_cachedAchievements[index].progress) { // For any streak / time based ones that reset. This is so if you fulfilled requirements of an achievement but didn't complete it it doesn't reset.
        debugPrint('Achievement progress will not decrease here for id: $id.');
        return;
      }
      _cachedAchievements[index] = Achievement(
        id: currentAchievement.id,
        title: currentAchievement.title,
        reward: currentAchievement.reward,
        task: currentAchievement.task,
        dateCompleted: currentAchievement.dateCompleted,
        isCompleted: currentAchievement.isCompleted, // User must manually complete achievement.
        isSecret: currentAchievement.isSecret,
        progress: achievementProgress,
      );

      // Persist changes
      if (currentProgress != achievementProgress) { // only save if there's a change
        _saveToStorage();
        debugPrint('Achievement successfully saved. title: ${_cachedAchievements[index].title}, progress: ${_cachedAchievements[index].progress}%');
      }
    } catch (e) {
      debugPrint('updateProgress: failed. id: $id, error: $e');
    }
  }

  /// Remove an achievement by ID
  Future<void> removeAchievement(String id) async {
    _cachedAchievements.removeWhere((a) => a.id == id);
    await _saveToStorage();
  }

  /// Complete an achievement by ID
  Future<void> completeAchievement(String id) async {
    debugPrint('Achievement completed for id: $id');
    final index = _cachedAchievements.indexWhere((a) => a.id == id);
    final currentAchievement = _cachedAchievements[index];
    if (currentAchievement.isCompleted) {
      debugPrint('This achievement is already completed!');
      return;
    }
    _cachedAchievements[index] = Achievement(
      id: currentAchievement.id,
      title: currentAchievement.title,
      reward: currentAchievement.reward,
      task: currentAchievement.task,
      dateCompleted: currentAchievement.dateCompleted,
      isCompleted: true,
      isSecret: currentAchievement.isSecret,
      progress: currentAchievement.progress,
    );
    String reward = currentAchievement.reward;
    if (reward.contains('points')) {
      final pointsToAdd = int.tryParse(reward.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      await _addPoints(pointsToAdd);
    } else {
      // TODO: special rewards
      debugPrint('Special reward spotted. ID: $id reward: $reward');
    }
    await _saveToStorage();
    debugPrint('Achievement successfully saved. title: ${_cachedAchievements[index].title}, progress: ${_cachedAchievements[index].progress}%');
  }

  /// Safely adds points to the user's total in storage. Separate to goal's addition of points.
  static Future<void> _addPoints(int pointsToAdd) async {
    if (pointsToAdd <= 0) return;
    final currentPointsString = await _storage.read(key: 'points');
    final currentPoints = int.tryParse(currentPointsString ?? '0') ?? 0;
    await _storage.write(key: 'points', value: (currentPoints + pointsToAdd).toString());
  }

  /// Clear all achievements (for testing / reset)
  Future<void> clearAll() async {
    _cachedAchievements.clear();
    await _storage.delete(key: _key);
  }

  /// Retrieve one achievement by ID
  static Achievement? getById(String id) {
    try {
      return _cachedAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      debugPrint('getByID: failed. id: $id');
      return null;
    }
  }


  static Future<String> getAchievementTrackingVariable(String key) async {
    final String? storedValue = await _storage.read(key: key);
    if (storedValue == null || storedValue == '') {
      debugPrint('getAchievementTrackingVariable: no value found for key $key');
      return '';
    }
    return storedValue;
  }

  static String? getVariableForAchievement(String id) {
    final int achievementId = int.parse(id);
    for (final entry in achievementVariableMap.entries) {
      if (entry.key.contains(achievementId)) {
        return entry.value;
      }
    }
    return null;
  }



}
