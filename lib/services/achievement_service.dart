// lib/services/achievement_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/classes/achievement.dart';
import '../models/classes/achievement_tracking_variables.dart';

class AchievementService {
  static const _key = 'achievements';
  final _storage = const FlutterSecureStorage();

  List<Achievement> _cachedAchievements = [];

  /// Initialize cache from storage
  Future<void> initialize() async {
    await _storage.write(key: _key, value: ''); // clear storage (for testing) TODO: remove this after adding all the unique achievements.
    final jsonStr = await _storage.read(key: _key);
    if (jsonStr == null || jsonStr == '') { // no achievements in storage
      debugPrint("No achievements. creating");
      _cachedAchievements = [];
      await initializeAchievements();
    } else {
      debugPrint('Achievements exist.');
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _cachedAchievements =
          decoded.map((e) => Achievement.fromJson(e)).toList();
    }
    await AchievementTrackingVariables().load();
  }

  /// Returns all cached achievements
  List<Achievement> get all => _cachedAchievements;

  /// Save all cached achievements back to storage
  Future<void> _saveToStorage() async {
    final encoded =
    jsonEncode(_cachedAchievements.map((a) => a.toJson()).toList());
    await _storage.write(key: _key, value: encoded);
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
      int startingId, String titlePrefix, bool isSecret, String taskPrefix, List<String> pointRewards, List<String> repetitions, int goalsToCreate,
      ) async {
    const List<String> romanNumerals = [
      'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'
    ]; // maximum of 9.

    for (int i = 0; i < goalsToCreate; i++) {
      final String id = (startingId + i).toString();
      final String title = '$titlePrefix${romanNumerals[i]}';
      final String reward = pointRewards[i];
      final String task = '$taskPrefix: ${repetitions[i]}';

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

    const int numHighAchievements = 9;

    List<String> pointRewardsHigh = [
      '100 points', '200 points', '250 points', '500 points',
      '750 points', '1000 points', '1500 points', '2000 points', '3000 points'
    ];

    List<String> repetitionsHigh = [
      '3', '5', '10', '25', '50', '100', '250', '500', '1000'
    ];

    List<String> pointRewardsAllHigh = [
      '1000 points', '2000 points', '3000 points', '4000 points', '5000 points', '7500 points',
      '10000 points'
    ];

    List<String> repetitionsAllHigh = [
      '3', '5', '10', '25', '50', '100', '250'
    ];

    List<String> pointRewardsDailyStreak = [
      '100 points', '1000 points', '250 points',  '500 points', '1000 points'
    ];

    List<String> dailyStreakRepetitions = [
      '2', '3', '7', '14', '30'
    ];

    List<String> pointRewardsWeeklyStreak = [
      '250 points', '500 points', '1000 points', '1500 points', '2000 points', '2500 points',
    ];

    List<String> weeklyStreakRepetitions = ['2', '4', '8', '12', '16', '20'];

    // Goal creation
    await addAchievement(Achievement(id: '1', title: 'Goal Setter I', reward: '100 points', task: 'Create 10 goals', isSecret: false));
    await addAchievement(Achievement(id: '2', title: 'Goal Setter II', reward: '250 points', task: 'Create 100 goals', isSecret: false));
    await addAchievement(Achievement(id: '3', title: 'Goal Setter III', reward: '1000 points', task: 'Create 1000 goals', isSecret: false));

    // Active goals
    await addAchievement(Achievement(id: '4', title: 'Juggler I', reward: '100 points', task: 'Have 10 active goals', isSecret: false));
    await addAchievement(Achievement(id: '5', title: 'Juggler II', reward: '250 points', task: 'Have 20 active goals', isSecret: false));

    // Completed goals
    await addAchievement(Achievement(id: '6', title: 'Completionist I', reward: '100 points', task: 'Complete 10 goals', isSecret: false));
    await addAchievement(Achievement(id: '7', title: 'Completionist II', reward: '250 points', task: 'Complete 100 goals', isSecret: false));
    await addAchievement(Achievement(id: '8', title: 'Completionist III', reward: '1000 points', task: 'Complete 1000 goals', isSecret: false));

    // Daily completions
    await addAchievement(Achievement(id: '9', title: 'Daily Driver I', reward: '100 points', task: 'Complete 3 goals in one day', isSecret: false));
    await addAchievement(Achievement(id: '10', title: 'Daily Driver II', reward: '250 points', task: 'Complete 5 goals in one day', isSecret: false));
    await addAchievement(Achievement(id: '11', title: 'Daily Driver III', reward: '500 points', task: 'Complete 10 goals in one day', isSecret: false));

    // Weekly completions
    await addAchievement(Achievement(id: '12', title: 'Weekly Warrior I', reward: '250 points', task: 'Complete 5 goals in one week', isSecret: false));
    await addAchievement(Achievement(id: '13', title: 'Weekly Warrior II', reward: '500 points', task: 'Complete 10 goals in one week', isSecret: false));
    await addAchievement(Achievement(id: '14', title: 'Weekly Warrior III', reward: '1000 points', task: 'Complete 20 goals in one week', isSecret: false));

    // Monthly completions
    await addAchievement(Achievement(id: '15', title: 'Monthly Momentum I', reward: '250 points', task: 'Complete 10 goals in one month', isSecret: false));
    await addAchievement(Achievement(id: '16', title: 'Monthly Momentum II', reward: '500 points', task: 'Complete 25 goals in one month', isSecret: false));
    await addAchievement(Achievement(id: '17', title: 'Monthly Momentum III', reward: '1000 points', task: 'Complete 50 goals in one month', isSecret: false));

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
    await addBulkAchievements(88, 'Consistent Completionist ', false, 'Complete goals every day for days', pointRewardsDailyStreak, dailyStreakRepetitions, 5);
    await addAchievement(Achievement(id: '93', title: '31-Day Club', reward: '1000 points', task: 'Complete goals on 31 days in a row', isSecret: true));

    // Weekly Streak based achievements -> 94 - 99
    await addBulkAchievements(94, 'Weekly Streak Master ', false, 'Complete goals every week for weeks', pointRewardsWeeklyStreak, weeklyStreakRepetitions, 6);

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

  /// Retrieve one achievement by ID
  Achievement? getById(String id) {
    try {
      return _cachedAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      debugPrint('getByID: failed. id: $id');
      return null;
    }
  }


  /// Remove an achievement by ID
  Future<void> removeAchievement(String id) async {
    _cachedAchievements.removeWhere((a) => a.id == id);
    await _saveToStorage();
  }

  /// Clear all achievements (for testing / reset)
  Future<void> clearAll() async {
    _cachedAchievements.clear();
    await _storage.delete(key: _key);
  }

  Future<String> getAchievementTrackingVariable(String key, String value) async {
    final String? storedValue = await _storage.read(key: key);
    if (storedValue == null || storedValue == '') {
      debugPrint('getAchievementTrackingVariable: no value found for key $key and value $value');
      return '';
    }
    return storedValue;
  }

  static void viewAchievement(int ID) {
    // TODO: This should show the achievement info.
  }
}
