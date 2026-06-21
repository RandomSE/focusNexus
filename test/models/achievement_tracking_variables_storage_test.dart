import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  tearDown(AchievementTrackingVariables.resetForTesting);

  test('initializeIfNeeded seeds defaults when storage is empty', () async {
    final memory = InMemoryKeyValueStorage();
    AchievementTrackingVariables.bindStorage(memory);
    final tracking = AchievementTrackingVariables();

    await tracking.initializeIfNeeded();

    expect(tracking.totalGoalsCreated, 0);
    expect(memory.snapshot[StorageKeys.achievementTrackingData], isNotNull);
  });

  test('save and load roundtrip through storage', () async {
    final memory = InMemoryKeyValueStorage();
    final tracking = AchievementTrackingVariables.test(memory);

    tracking.totalGoalsCreated = 7;
    tracking.lastWeekGoalWasCompleted = '2026-05-04';
    await tracking.save();

    final reloaded = AchievementTrackingVariables.test(memory);
    await reloaded.load();

    expect(reloaded.totalGoalsCreated, 7);
    expect(reloaded.lastWeekGoalWasCompleted, '2026-05-04');
  });

  test('load resets when JSON is corrupt', () async {
    final memory = InMemoryKeyValueStorage(
      initial: {StorageKeys.achievementTrackingData: '{bad json'},
    );
    final tracking = AchievementTrackingVariables.test(memory);

    tracking.totalGoalsCreated = 99;
    await tracking.load();

    expect(tracking.totalGoalsCreated, 0);
    expect(memory.snapshot[StorageKeys.achievementTrackingData], isNotNull);
  });

  test('update writes merged snapshot to storage', () async {
    final memory = InMemoryKeyValueStorage();
    final tracking = AchievementTrackingVariables.test(memory);

    await tracking.update(totalGoalsCompleted: 3);

    final raw = memory.snapshot[StorageKeys.achievementTrackingData]!;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['totalGoalsCompleted'], 3);
  });
}
