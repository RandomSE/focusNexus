// lib/services/achievement_tracking_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Global tracking service for goal-related achievement progress.
class AchievementTrackingVariables {
  /// singleton setup
  static final AchievementTrackingVariables _instance =
  AchievementTrackingVariables._internal();
  factory AchievementTrackingVariables() => _instance;
  AchievementTrackingVariables._internal();

  /// secure storage
  static const _key = 'achievementTrackingData';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// tracked variables
  int totalGoalsCreated = 0;
  int totalGoalsActive = 0;
  int totalGoalsCompleted = 0;
  int goalsCompletedToday = 0;
  int goalsCompletedThisWeek = 0;
  int goalsCompletedThisMonth = 0;
  int goalsCompletedWithHighPoints = 0;
  int goalsCompletedWithHighComplexity = 0;
  int goalsCompletedWithHighEffort = 0;
  int goalsCompletedWithHighMotivation = 0;
  int goalsCompletedWithAllHigh = 0;
  int goalsCompletedWithHighTimeRequirement = 0;
  int goalsCompletedWithManySteps = 0;
  int goalsCompletedEarly = 0;
  String datesGoalsCompleted = '';
  String lastWeekGoalWasCompleted = '';
  String lastMonthGoalWasCompleted = '';
  int consecutiveDaysWithGoalsCompleted = 0;
  int consecutiveWeeksWithGoalsCompleted = 0;

  /// Ensures tracking variables are initialized once on app startup.
  Future<void> initializeIfNeeded() async {
    final existing = await _storage.read(key: _key);
    if (existing == null) {
      await reset(); // creates and saves default values
      await _storage.write(key: _key, value: jsonEncode(_toJson()));
      debugPrint('Achievement tracking initialized with default values.');
    } else {
      await load(); // loads existing values
      debugPrint('Achievement tracking loaded from storage.');
    }
  }

  /// load existing data
  Future<void> load() async {
    final jsonStr = await _storage.read(key: _key);
    if (jsonStr == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      _fromJson(data);
    } catch (e) {
      // In case old format or corruption
      await reset();
    }
  }

  /// save current data
  Future<void> save() async {
    final encoded = jsonEncode(_toJson());
    await _storage.write(key: _key, value: encoded);
  }

  /// reset all current data
  Future<void> reset() async {
    totalGoalsCreated = 0;
    totalGoalsActive = 0;
    totalGoalsCompleted = 0;
    goalsCompletedToday = 0;
    goalsCompletedThisWeek = 0;
    goalsCompletedThisMonth = 0;
    goalsCompletedWithHighPoints = 0;
    goalsCompletedWithHighComplexity = 0;
    goalsCompletedWithHighEffort = 0;
    goalsCompletedWithHighMotivation = 0;
    goalsCompletedWithAllHigh = 0;
    goalsCompletedWithHighTimeRequirement = 0;
    goalsCompletedWithManySteps = 0;
    goalsCompletedEarly = 0;
    datesGoalsCompleted = '';
    lastWeekGoalWasCompleted = '';
    lastMonthGoalWasCompleted = '';
    consecutiveDaysWithGoalsCompleted = 0;
    consecutiveWeeksWithGoalsCompleted = 0;
    await save();
  }

  /// helper for updates
  Future<void> update({
    int? totalGoalsCreated,
    int? totalGoalsActive,
    int? totalGoalsCompleted,
    int? goalsCompletedToday,
    int? goalsCompletedThisWeek,
    int? goalsCompletedThisMonth,
    int? goalsCompletedWithHighPoints,
    int? goalsCompletedWithHighComplexity,
    int? goalsCompletedWithHighEffort,
    int? goalsCompletedWithHighMotivation,
    int? goalsCompletedWithAllHigh,
    int? goalsCompletedWithHighTimeRequirement,
    int? goalsCompletedWithManySteps,
    int? goalsCompletedEarly,
    String? datesGoalsCompleted,
    String? lastWeekGoalWasCompleted,
    String? lastMonthGoalWasCompleted,
    int? consecutiveDaysWithGoalsCompleted,
    int? consecutiveWeeksWithGoalsCompleted,
  }) async {
    if (totalGoalsCreated != null) this.totalGoalsCreated = totalGoalsCreated;
    if (totalGoalsActive != null) this.totalGoalsActive = totalGoalsActive;
    if (totalGoalsCompleted != null) this.totalGoalsCompleted = totalGoalsCompleted;
    if (goalsCompletedToday != null) this.goalsCompletedToday = goalsCompletedToday;
    if (goalsCompletedThisWeek != null) this.goalsCompletedThisWeek = goalsCompletedThisWeek;
    if (goalsCompletedThisMonth != null) this.goalsCompletedThisMonth = goalsCompletedThisMonth;
    if (goalsCompletedWithHighPoints != null) this.goalsCompletedWithHighPoints = goalsCompletedWithHighPoints;
    if (goalsCompletedWithHighComplexity != null) this.goalsCompletedWithHighComplexity = goalsCompletedWithHighComplexity;
    if (goalsCompletedWithHighEffort != null) this.goalsCompletedWithHighEffort = goalsCompletedWithHighEffort;
    if (goalsCompletedWithHighMotivation != null) this.goalsCompletedWithHighMotivation = goalsCompletedWithHighMotivation;
    if (goalsCompletedWithAllHigh != null) this.goalsCompletedWithAllHigh = goalsCompletedWithAllHigh;
    if (goalsCompletedWithHighTimeRequirement != null) this.goalsCompletedWithHighTimeRequirement = goalsCompletedWithHighTimeRequirement;
    if (goalsCompletedWithManySteps != null) this.goalsCompletedWithManySteps = goalsCompletedWithManySteps;
    if (goalsCompletedEarly != null) this.goalsCompletedEarly = goalsCompletedEarly;
    if (datesGoalsCompleted != null) this.datesGoalsCompleted = datesGoalsCompleted;
    if (lastWeekGoalWasCompleted != null) this.lastWeekGoalWasCompleted = lastWeekGoalWasCompleted;
    if (lastMonthGoalWasCompleted != null) this.lastMonthGoalWasCompleted = lastMonthGoalWasCompleted;
    if (consecutiveDaysWithGoalsCompleted != null) this.consecutiveDaysWithGoalsCompleted = consecutiveDaysWithGoalsCompleted;
    if (consecutiveWeeksWithGoalsCompleted != null) this.consecutiveWeeksWithGoalsCompleted = consecutiveWeeksWithGoalsCompleted;

    await save();
  }

  /// internal serialization
  Map<String, dynamic> _toJson() => {
    'totalGoalsCreated': totalGoalsCreated,
    'totalGoalsActive': totalGoalsActive,
    'totalGoalsCompleted': totalGoalsCompleted,
    'goalsCompletedToday': goalsCompletedToday,
    'goalsCompletedThisWeek': goalsCompletedThisWeek,
    'goalsCompletedThisMonth': goalsCompletedThisMonth,
    'goalsCompletedWithHighPoints': goalsCompletedWithHighPoints,
    'goalsCompletedWithHighComplexity': goalsCompletedWithHighComplexity,
    'goalsCompletedWithHighEffort': goalsCompletedWithHighEffort,
    'goalsCompletedWithHighMotivation': goalsCompletedWithHighMotivation,
    'goalsCompletedWithAllHigh': goalsCompletedWithAllHigh,
    'goalsCompletedWithHighTimeRequirement': goalsCompletedWithHighTimeRequirement,
    'goalsCompletedWithManySteps': goalsCompletedWithManySteps,
    'goalsCompletedEarly': goalsCompletedEarly,
    'datesGoalsCompleted': datesGoalsCompleted,
    'lastWeekGoalWasCompleted': lastWeekGoalWasCompleted,
    'lastMonthGoalWasCompleted': lastMonthGoalWasCompleted,
    'consecutiveDaysWithGoalsCompleted': consecutiveDaysWithGoalsCompleted,
    'consecutiveWeeksWithGoalsCompleted': consecutiveWeeksWithGoalsCompleted,
  };

  void _fromJson(Map<String, dynamic> json) {
    totalGoalsCreated =  json['totalGoalsCreated'];
    totalGoalsActive = json['totalGoalsActive'] ?? 0;
    totalGoalsCompleted = json['totalGoalsCompleted'] ?? 0;
    goalsCompletedToday = json['goalsCompletedToday'] ?? 0;
    goalsCompletedThisWeek = json['goalsCompletedThisWeek'] ?? 0;
    goalsCompletedThisMonth = json['goalsCompletedThisMonth'] ?? 0;
    goalsCompletedWithHighPoints = json['goalsCompletedWithHighPoints'] ?? 0;
    goalsCompletedWithHighComplexity = json['goalsCompletedWithHighComplexity'] ?? 0;
    goalsCompletedWithHighEffort = json['goalsCompletedWithHighEffort'] ?? 0;
    goalsCompletedWithHighMotivation = json['goalsCompletedWithHighMotivation'] ?? 0;
    goalsCompletedWithAllHigh = json['goalsCompletedWithAllHigh'] ?? 0;
    goalsCompletedWithHighTimeRequirement = json['goalsCompletedWithHighTimeRequirement'] ?? 0;
    goalsCompletedWithManySteps = json['goalsCompletedWithManySteps'] ?? 0;
    goalsCompletedEarly = json['goalsCompletedEarly'] ?? 0;
    datesGoalsCompleted = json['datesGoalsCompleted'] ?? '';
    lastWeekGoalWasCompleted = json ['lastMonthGoalWasCompleted'] ?? '';
    lastMonthGoalWasCompleted = json['lastMonthGoalWasCompleted'] ?? '';
    consecutiveDaysWithGoalsCompleted = json['consecutiveDaysWithGoalsCompleted'] ?? 0;
    consecutiveWeeksWithGoalsCompleted = json['consecutiveWeeksWithGoalsCompleted'] ?? 0;
  }
}
