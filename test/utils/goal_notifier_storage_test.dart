import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  tearDown(() {
    GoalNotifier.resetForTesting();
  });

  test('checkAiEncouragement reads flag from injected storage', () async {
    final memory = InMemoryKeyValueStorage(initial: {'aiEncouragement': 'true'});
    GoalNotifier.storage = memory;

    await GoalNotifier.checkAiEncouragement();

    expect(GoalNotifier.isAiEncouragementEnabled, isTrue);
  });

  test('checkDailyAffirmations reads flag from injected storage', () async {
    final memory = InMemoryKeyValueStorage(initial: {'dailyAffirmations': 'true'});
    GoalNotifier.storage = memory;

    await GoalNotifier.checkDailyAffirmations();

    expect(GoalNotifier.isDailyAffirmationsEnabled, isTrue);
  });

  test('settings default to false when storage keys are absent', () async {
    GoalNotifier.storage = InMemoryKeyValueStorage();

    await GoalNotifier.checkAdditionalNotificationSettings();

    expect(GoalNotifier.isAiEncouragementEnabled, isFalse);
    expect(GoalNotifier.isDailyAffirmationsEnabled, isFalse);
  });
}
