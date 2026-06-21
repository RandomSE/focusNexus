import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/goals/goal_kind.dart';

/// Maximum window length treated as a "strict" window for bonus points.
const Duration strictWindowMaxDuration = Duration(hours: 3);

/// When start was clamped to now, schedule end reminder only if remaining window exceeds this.
const Duration longWindowReminderThreshold = Duration(hours: 1);

/// How far ahead of window start we materialize the next repeating instance.
const Duration repeatSpawnLookahead = Duration(hours: 24);
const int actionWindowStartNotificationOffset = 200;
const int actionWindowEndReminderNotificationOffset = 201;

class ActionWindow {
  const ActionWindow({
    required this.start,
    required this.end,
    required this.wasStartClamped,
  });

  final DateTime start;
  final DateTime end;
  final bool wasStartClamped;

  Duration get duration => end.difference(start);
}

ActionWindow computeActionWindow({
  required DateTime endAt,
  required Duration duration,
  required DateTime now,
}) {
  final idealStart = endAt.subtract(duration);
  final wasClamped = idealStart.isBefore(now);
  final start = wasClamped ? now : idealStart;
  return ActionWindow(start: start, end: endAt, wasStartClamped: wasClamped);
}

bool isTimeWindowGoal(GoalSet goal) =>
    goal.goalKind == GoalKind.timeWindow ||
    (goal.actionWindowEnd.isNotEmpty && goal.goalKind != GoalKind.deadline);

bool isActionWindowActive(GoalSet goal, DateTime now, {DateTime? start, DateTime? end}) {
  if (!isTimeWindowGoal(goal)) return true;
  final windowStart = start ?? parseGoalDateTime(goal.actionWindowStart);
  final windowEnd = end ?? parseGoalDateTime(goal.actionWindowEnd);
  if (windowStart == null || windowEnd == null) return false;
  return !now.isBefore(windowStart) && now.isBefore(windowEnd);
}

DateTime? parseGoalDateTime(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  try {
    return DateTime.parse(trimmed);
  } catch (_) {
    return null;
  }
}

DateTime? resolveActionWindowReminderTime({
  required DateTime start,
  required DateTime end,
  required DateTime now,
  required bool wasStartClamped,
}) {
  if (start.isAfter(now)) return start;
  if (wasStartClamped && end.difference(now) > longWindowReminderThreshold) {
    final reminder = end.subtract(longWindowReminderThreshold);
    return reminder.isAfter(now) ? reminder : null;
  }
  return null;
}

bool isStrictWindow(Duration duration) => duration <= strictWindowMaxDuration;

/// Next window end strictly after [after], following [rule] from [anchorEndAt].
DateTime? computeNextWindowEnd({
  required RepeatRule rule,
  required DateTime anchorEndAt,
  required DateTime after,
}) {
  if (!rule.enabled || rule.interval < 1) return null;

  final offsetAnchor = anchorEndAt.add(rule.startOffset);
  final searchAfter = after.isBefore(offsetAnchor) ? offsetAnchor : after;

  switch (rule.unit) {
    case RepeatUnit.hours:
      return _nextHourlyEnd(
        anchor: offsetAnchor,
        intervalHours: rule.interval,
        after: searchAfter,
      );
    case RepeatUnit.days:
      return _nextDailyEnd(
        anchor: offsetAnchor,
        intervalDays: rule.interval,
        weekdays: rule.weekdays,
        after: searchAfter,
      );
    case RepeatUnit.weeks:
      return _nextWeeklyEnd(
        anchor: offsetAnchor,
        intervalWeeks: rule.interval,
        weekdays: rule.weekdays,
        after: searchAfter,
      );
  }
}

DateTime? _nextHourlyEnd({
  required DateTime anchor,
  required int intervalHours,
  required DateTime after,
}) {
  if (!after.isBefore(anchor)) {
    final elapsed = after.difference(anchor);
    final hours = elapsed.inMinutes / 60.0;
    final steps = (hours / intervalHours).ceil();
    final candidate = anchor.add(Duration(hours: intervalHours * steps));
    if (candidate.isAfter(after)) return candidate;
  }
  return anchor.isAfter(after) ? anchor : anchor.add(Duration(hours: intervalHours));
}

DateTime? _nextDailyEnd({
  required DateTime anchor,
  required int intervalDays,
  required Set<int> weekdays,
  required DateTime after,
}) {
  var candidate = anchor;
  if (!candidate.isAfter(after)) {
    final elapsedDays = after.difference(anchor).inDays;
    final steps = (elapsedDays / intervalDays).ceil();
    candidate = anchor.add(Duration(days: intervalDays * steps));
  }
  for (var i = 0; i < 366; i++) {
    if (candidate.isAfter(after) && _matchesWeekday(candidate, weekdays)) {
      return candidate;
    }
    candidate = candidate.add(Duration(days: intervalDays));
  }
  return null;
}

DateTime? _nextWeeklyEnd({
  required DateTime anchor,
  required int intervalWeeks,
  required Set<int> weekdays,
  required DateTime after,
}) {
  final effectiveWeekdays = weekdays.isEmpty ? {anchor.weekday} : weekdays;
  final anchorWeekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
  for (var week = 0; week < 104; week++) {
    final weekStart = anchorWeekStart.add(Duration(days: week * intervalWeeks * 7));
    for (final weekday in effectiveWeekdays.toList()..sort()) {
      final candidate = weekStart.add(Duration(days: weekday - 1));
      final withTime = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        anchor.hour,
        anchor.minute,
        anchor.second,
      );
      if (withTime.isAfter(after)) return withTime;
    }
  }
  return null;
}

bool _matchesWeekday(DateTime date, Set<int> weekdays) {
  if (weekdays.isEmpty) return true;
  return weekdays.contains(date.weekday);
}

String summarizeRepeatRule(RepeatRule rule) {
  if (!rule.enabled) return 'Does not repeat';
  final unitLabel = switch (rule.unit) {
    RepeatUnit.hours => rule.interval == 1 ? 'hour' : 'hours',
    RepeatUnit.days => rule.interval == 1 ? 'day' : 'days',
    RepeatUnit.weeks => rule.interval == 1 ? 'week' : 'weeks',
  };
  final base = 'Every ${rule.interval} $unitLabel';
  if (rule.weekdays.isEmpty) return base;
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final days = (rule.weekdays.toList()..sort())
      .map((d) => names[d - 1])
      .join(', ');
  return '$base on $days';
}

String formatGoalDateTime(DateTime value) => value.toIso8601String();

/// User-facing window end (minute precision, no fractional seconds).
String formatActionWindowEndLabel(DateTime endAt) {
  final h = endAt.hour.toString().padLeft(2, '0');
  final m = endAt.minute.toString().padLeft(2, '0');
  return '${endAt.day}/${endAt.month}/${endAt.year} $h:$m';
}
