import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  tearDown(() {
    GoalNotifier.resetForTesting();
  });

  test('checkAiEncouragement reads flag from injected storage', () async {
    final memory = InMemoryKeyValueStorage(
      initial: {'aiEncouragement': 'true'},
    );
    GoalNotifier.storage = memory;

    await GoalNotifier.checkAiEncouragement();

    expect(GoalNotifier.isAiEncouragementEnabled, isTrue);
  });

  test('checkDailyAffirmations reads flag from injected storage', () async {
    final memory = InMemoryKeyValueStorage(
      initial: {'dailyAffirmations': 'true'},
    );
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

  test(
    'notification frequency disables scheduling when set to No notifications',
    () async {
      GoalNotifier.storage = InMemoryKeyValueStorage(
        initial: {'notificationFrequency': 'No notifications'},
      );

      final enabled = await GoalNotifier.areNotificationsEnabledByFrequency();

      expect(enabled, isFalse);
    },
  );

  test(
    'notification frequency allows scheduling for valid frequencies',
    () async {
      GoalNotifier.storage = InMemoryKeyValueStorage(
        initial: {'notificationFrequency': 'Medium'},
      );

      final enabled = await GoalNotifier.areNotificationsEnabledByFrequency();

      expect(enabled, isTrue);
    },
  );

  test(
    'frequency transition from disabled to enabled re-schedules daily affirmations when enabled',
    () async {
      final memory = InMemoryKeyValueStorage(
        initial: {
          StorageKeys.dailyAffirmations: 'true',
          StorageKeys.dailyAffirmationsTime: '08:15',
        },
      );
      GoalNotifier.storage = memory;
      final scheduledTimes = <String>[];
      GoalNotifier.setDailyAffirmationsSchedulerForTesting((time) async {
        scheduledTimes.add(time);
      });

      await GoalNotifier.refreshSchedulesForFrequencyChange(
        oldFrequency: 'No notifications',
        newFrequency: 'Medium',
      );

      expect(scheduledTimes, ['08:15']);
    },
  );

  test(
    'frequency transition from disabled to enabled uses fallback time when affirmations time is missing',
    () async {
      final memory = InMemoryKeyValueStorage(
        initial: {StorageKeys.dailyAffirmations: 'true'},
      );
      GoalNotifier.storage = memory;
      final scheduledTimes = <String>[];
      GoalNotifier.setDailyAffirmationsSchedulerForTesting((time) async {
        scheduledTimes.add(time);
      });

      await GoalNotifier.refreshSchedulesForFrequencyChange(
        oldFrequency: 'No notifications',
        newFrequency: 'Low',
      );

      expect(scheduledTimes, ['06:00']);
    },
  );

  test(
    'frequency transition from disabled to enabled does not re-schedule when daily affirmations are disabled',
    () async {
      final memory = InMemoryKeyValueStorage(
        initial: {
          StorageKeys.dailyAffirmations: 'false',
          StorageKeys.dailyAffirmationsTime: '09:00',
        },
      );
      GoalNotifier.storage = memory;
      var schedulerCalls = 0;
      GoalNotifier.setDailyAffirmationsSchedulerForTesting((_) async {
        schedulerCalls++;
      });

      await GoalNotifier.refreshSchedulesForFrequencyChange(
        oldFrequency: 'No notifications',
        newFrequency: 'High',
      );

      expect(schedulerCalls, 0);
    },
  );

  test(
    'frequency transitions that stay enabled do not re-schedule daily affirmations',
    () async {
      final memory = InMemoryKeyValueStorage(
        initial: {
          StorageKeys.dailyAffirmations: 'true',
          StorageKeys.dailyAffirmationsTime: '09:00',
        },
      );
      GoalNotifier.storage = memory;
      var schedulerCalls = 0;
      GoalNotifier.setDailyAffirmationsSchedulerForTesting((_) async {
        schedulerCalls++;
      });

      await GoalNotifier.refreshSchedulesForFrequencyChange(
        oldFrequency: 'Low',
        newFrequency: 'High',
      );

      expect(schedulerCalls, 0);
    },
  );
}
