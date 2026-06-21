// lib/services/achievement_tracking_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/achievement_tracking_codec.dart';

/// Global tracking service for goal-related achievement progress.
class AchievementTrackingVariables {
  AchievementTrackingVariables._(this._storage);

  /// Test-only: direct instance with injected storage (bypasses factory routing).
  AchievementTrackingVariables.test(KeyValueStorage storage) : _storage = storage;

  static KeyValueStorage? _boundStorage;
  static AchievementTrackingVariables? _singleton;

  factory AchievementTrackingVariables() {
    final storage = _boundStorage;
    if (storage == null) {
      throw StateError(
        'AchievementTrackingVariables storage not bound. '
        'Read achievementTrackingWiringProvider before use.',
      );
    }
    return _singleton ??= AchievementTrackingVariables._(storage);
  }

  /// Called once per [ProviderScope] via [achievementTrackingWiringProvider].
  static void bindStorage(KeyValueStorage storage) {
    _boundStorage = storage;
    _singleton = AchievementTrackingVariables._(storage);
  }

  /// Test-only: restore defaults between tests.
  static void resetForTesting() {
    _boundStorage = null;
    _singleton = null;
  }

  final KeyValueStorage _storage;

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
    final existing = await _storage.read(key: StorageKeys.achievementTrackingData);
    if (existing == null) {
      await reset(); // creates and saves default values
      await _storage.write(
        key: StorageKeys.achievementTrackingData,
        value: jsonEncode(_toJson()),
      );
      debugPrint('Achievement tracking initialized with default values.');
    } else {
      await load(); // loads existing values
      debugPrint('Achievement tracking loaded from storage.');
    }
  }

  /// load existing data
  Future<void> load() async {
    final jsonStr = await _storage.read(key: StorageKeys.achievementTrackingData);
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
    await _storage.write(key: StorageKeys.achievementTrackingData, value: encoded);
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

  /// Exposed for unit tests and serialization roundtrips.
  AchievementTrackingSnapshot toSnapshot() {
    return AchievementTrackingSnapshot(
      totalGoalsCreated: totalGoalsCreated,
      totalGoalsActive: totalGoalsActive,
      totalGoalsCompleted: totalGoalsCompleted,
      goalsCompletedToday: goalsCompletedToday,
      goalsCompletedThisWeek: goalsCompletedThisWeek,
      goalsCompletedThisMonth: goalsCompletedThisMonth,
      goalsCompletedWithHighPoints: goalsCompletedWithHighPoints,
      goalsCompletedWithHighComplexity: goalsCompletedWithHighComplexity,
      goalsCompletedWithHighEffort: goalsCompletedWithHighEffort,
      goalsCompletedWithHighMotivation: goalsCompletedWithHighMotivation,
      goalsCompletedWithAllHigh: goalsCompletedWithAllHigh,
      goalsCompletedWithHighTimeRequirement: goalsCompletedWithHighTimeRequirement,
      goalsCompletedWithManySteps: goalsCompletedWithManySteps,
      goalsCompletedEarly: goalsCompletedEarly,
      datesGoalsCompleted: datesGoalsCompleted,
      lastWeekGoalWasCompleted: lastWeekGoalWasCompleted,
      lastMonthGoalWasCompleted: lastMonthGoalWasCompleted,
      consecutiveDaysWithGoalsCompleted: consecutiveDaysWithGoalsCompleted,
      consecutiveWeeksWithGoalsCompleted: consecutiveWeeksWithGoalsCompleted,
    );
  }

  void applySnapshot(AchievementTrackingSnapshot snapshot) {
    totalGoalsCreated = snapshot.totalGoalsCreated;
    totalGoalsActive = snapshot.totalGoalsActive;
    totalGoalsCompleted = snapshot.totalGoalsCompleted;
    goalsCompletedToday = snapshot.goalsCompletedToday;
    goalsCompletedThisWeek = snapshot.goalsCompletedThisWeek;
    goalsCompletedThisMonth = snapshot.goalsCompletedThisMonth;
    goalsCompletedWithHighPoints = snapshot.goalsCompletedWithHighPoints;
    goalsCompletedWithHighComplexity = snapshot.goalsCompletedWithHighComplexity;
    goalsCompletedWithHighEffort = snapshot.goalsCompletedWithHighEffort;
    goalsCompletedWithHighMotivation = snapshot.goalsCompletedWithHighMotivation;
    goalsCompletedWithAllHigh = snapshot.goalsCompletedWithAllHigh;
    goalsCompletedWithHighTimeRequirement = snapshot.goalsCompletedWithHighTimeRequirement;
    goalsCompletedWithManySteps = snapshot.goalsCompletedWithManySteps;
    goalsCompletedEarly = snapshot.goalsCompletedEarly;
    datesGoalsCompleted = snapshot.datesGoalsCompleted;
    lastWeekGoalWasCompleted = snapshot.lastWeekGoalWasCompleted;
    lastMonthGoalWasCompleted = snapshot.lastMonthGoalWasCompleted;
    consecutiveDaysWithGoalsCompleted = snapshot.consecutiveDaysWithGoalsCompleted;
    consecutiveWeeksWithGoalsCompleted = snapshot.consecutiveWeeksWithGoalsCompleted;
  }

  /// internal serialization
  Map<String, dynamic> _toJson() => toSnapshot().toJson();

  void _fromJson(Map<String, dynamic> json) {
    applySnapshot(AchievementTrackingSnapshot.fromJson(json));
  }
}
