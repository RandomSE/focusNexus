import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import 'goal_notifier_runtime.dart';

/// Storage from [goalNotifierWiringProvider].
KeyValueStorage goalNotifierStorage() {
  final bound = GoalNotifierRuntime.I.boundStorage;
  if (bound == null) {
    throw StateError(
      'GoalNotifier storage not bound. Read goalNotifierWiringProvider before use.',
    );
  }
  return bound;
}

/// Called once per [ProviderScope] via [goalNotifierWiringProvider].
void bindGoalNotifierStorage(KeyValueStorage storage) {
  GoalNotifierRuntime.I.boundStorage = storage;
}

/// Readable flags for unit tests (settings loaded from [goalNotifierStorage]).
bool get isAiEncouragementEnabled => GoalNotifierRuntime.I.aiEncouragement;

bool get isDailyAffirmationsEnabled => GoalNotifierRuntime.I.dailyAffirmations;

Future<void> checkAiEncouragement() async {
  final r = GoalNotifierRuntime.I;
  String? aiEncouragementString = await goalNotifierStorage().read(
    key: StorageKeys.aiEncouragement,
  );
  r.aiEncouragement = aiEncouragementString == 'true';
}

Future<void> checkDailyAffirmations() async {
  final r = GoalNotifierRuntime.I;
  String? dailyAffirmationsString = await goalNotifierStorage().read(
    key: StorageKeys.dailyAffirmations,
  );
  r.dailyAffirmations = dailyAffirmationsString == 'true';
}
