import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  tearDown(() {
    AchievementTrackingVariables.resetTestInstance();
  });

  test('initializeIfNeeded seeds defaults when storage is empty', () async {
    final memory = InMemoryKeyValueStorage();
    final tracking = AchievementTrackingVariables.test(memory);
    AchievementTrackingVariables.useTestInstance(tracking);

    await tracking.initializeIfNeeded();

    expect(tracking.totalGoalsCreated, 0);
    expect(memory.snapshot['achievementTrackingData'], isNotNull);
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
      initial: {'achievementTrackingData': '{bad json'},
    );
    final tracking = AchievementTrackingVariables.test(memory);

    tracking.totalGoalsCreated = 99;
    await tracking.load();

    expect(tracking.totalGoalsCreated, 0);
    expect(memory.snapshot['achievementTrackingData'], isNotNull);
  });

  test('update writes merged snapshot to storage', () async {
    final memory = InMemoryKeyValueStorage();
    final tracking = AchievementTrackingVariables.test(memory);

    await tracking.update(totalGoalsCompleted: 3);

    final raw = memory.snapshot['achievementTrackingData']!;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['totalGoalsCompleted'], 3);
  });
}
