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
      _cachedAchievements = [];
      initializeAchievements();
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

  Future<void> initializeAchievements() async { // TODO: Expand this. Use this to initially have all the achievements. Loads on opening app
      debugPrint('Achievements not initialized - creating.');
      addAchievement(Achievement(id: '1', title: 'test achievement 1', reward: '1000 points', task: 'Test visuals', isSecret: false));
      addAchievement(Achievement(id: '2', title: 'test achievement 2', reward: '1000 points', task: 'make achievement object', isSecret: false));
      addAchievement(Achievement(id: '3', title: 'test achievement 3', reward: '1000 points', task: 'Test achievements are shown', isSecret: false));
      addAchievement(Achievement(id: '4', title: 'test achievement 4', reward: '1000 points', task: 'test achievements can be opened', isSecret: false));
      addAchievement(Achievement(id: '5', title: 'test achievement 5', reward: '1000 points', task: 'test achievements can be completed', isSecret: false));

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
