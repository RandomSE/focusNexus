import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:timezone/timezone.dart' as tz;

import '../common_utils.dart';
import '../text_utils.dart';
import 'goal_notifier_runtime.dart';
import 'goal_notifier_scheduling.dart';

int getScoreByTypeAndString(String type, String value) {
  if (type == 'Steps') {
    return CommonUtils.scoreFromSteps(int.parse(value));
  }
  if (type == 'Time') {
    return CommonUtils.scoreFromTime(int.parse(value));
  }
  return CommonUtils.scoreFromLevel(value);
}

(int, List<String>, int) getEncouragementValue(GoalSet goalSet) {
  final complexityScore = CommonUtils.scoreFromLevel(goalSet.complexity);
  final effortScore = CommonUtils.scoreFromLevel(goalSet.effort);
  final motivationScore = CommonUtils.scoreFromLevel(goalSet.motivation);
  final timeScore = CommonUtils.scoreFromTime(goalSet.time);
  final stepsScore = CommonUtils.scoreFromSteps(goalSet.steps);

  final totalScore =
      complexityScore +
      effortScore +
      motivationScore +
      timeScore +
      stepsScore;
  final biggestFactorScore = [
    complexityScore,
    effortScore,
    motivationScore,
    timeScore,
    stepsScore,
  ].reduce((a, b) => a > b ? a : b);

  final List<String> reasons = [];
  if (complexityScore > 0) {
    reasons.add('This goal has a challenging complexity level.');
  }
  if (effortScore > 0) {
    reasons.add('It requires notable effort to complete.');
  }
  if (motivationScore > 0) {
    reasons.add('Staying motivated might be tough.');
  }
  if (timeScore > 0) {
    reasons.add('It spans a significant amount of time.');
  }
  if (stepsScore > 0) {
    reasons.add('It involves many steps to complete.');
  }

  return (totalScore, reasons, biggestFactorScore);
}

/// Check-ins for demanding goals: early nudge, midpoint, and pre-deadline support.
Future<void> scheduleAiEncouragementSuite({
  required GoalSet goalSet,
  required String goalName,
  required int goalId,
  required String notificationStyle,
  required tz.TZDateTime now,
  required tz.TZDateTime deadline,
  required int hoursToExpire,
}) async {
  final r = GoalNotifierRuntime.I;
  final (score, reasons, biggest) = getEncouragementValue(goalSet);
  if (score < r.encouragementThreshold && biggest <= 3) {
    return;
  }

  final timeScore = getScoreByTypeAndString('Time', goalSet.time.toString());
  final stepScore = getScoreByTypeAndString(
    'Steps',
    goalSet.steps.toString(),
  );
  final complexityScore = getScoreByTypeAndString(
    'Levels',
    goalSet.complexity,
  );
  final effortScore = getScoreByTypeAndString('Levels', goalSet.effort);
  final motivationScore = getScoreByTypeAndString(
    'Levels',
    goalSet.motivation,
  );

  final triggers = <DateTime>{
    now.add(const Duration(hours: 2)),
    now.add(Duration(hours: hoursToExpire ~/ 2)),
    deadline.subtract(const Duration(hours: 12)),
  }..removeWhere((time) => !time.isAfter(now) || !time.isBefore(deadline));

  final sortedTriggers = <DateTime>[];
  for (final candidate in (triggers.toList()..sort())) {
    if (sortedTriggers.isEmpty ||
        candidate.difference(sortedTriggers.last).inMinutes.abs() >= 30) {
      sortedTriggers.add(candidate);
    }
  }

  for (var i = 0; i < sortedTriggers.length && i < 3; i++) {
    final trigger = sortedTriggers[i];
    final message = TextUtils.buildEncouragementMessage(
      goalName,
      goalId,
      goalSet.deadline,
      reasons,
      score,
      biggest,
      timeScore,
      stepScore,
      complexityScore,
      effortScore,
      motivationScore,
      notificationStyle,
      phase: i,
    );
    await scheduleReminder(
      goalId + GoalNotifierRuntime.aiEncouragementSlotOffsets[i],
      'AI encouragement',
      message,
      trigger,
      r.scheduleMode,
      r.aiEncouragementGroupId,
      'AI encouragement',
      'Encouragement for more intense goals',
      'ai_encouragement_group',
      'AI encouragement',
      'AI encouragement',
      'Encouragement for more intense goals',
    );
  }
}
