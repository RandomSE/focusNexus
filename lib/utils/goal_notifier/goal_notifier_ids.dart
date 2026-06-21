import 'dart:math';

import 'package:timezone/timezone.dart' as tz;

import 'goal_notifier_runtime.dart';

int generateGoalId(String goalName) {
  final random = Random();
  final randomPart = random.nextInt(100000);
  final hashPart = goalName.hashCode.abs();

  // Combine safely within 32-bit int range
  final combined = (hashPart % 1000000) * 100000 + randomPart;
  return combined & 0x7FFFFFFF;
}

Duration getDurationFromSeconds(int seconds) {
  return Duration(seconds: seconds);
}

void setNow() {
  GoalNotifierRuntime.I.now = tz.TZDateTime.now(tz.local);
}
