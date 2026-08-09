import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';
import 'package:focusNexus/utils/debug_log.dart';

/// Aggregates completed goals into local calendar-day counts.
abstract final class ConsistencyAggregator {
  ConsistencyAggregator._();

  /// Counts completions per local calendar day. Skips unparseable [CompletedAt].
  static Map<DateTime, int> countsByDay(List<GoalSet> completed) {
    final map = <DateTime, int>{};
    for (final goal in completed) {
      final parsed = CompletionTimestamp.tryParse(goal.completedAt);
      if (parsed == null) {
        if (goal.completedAt.isNotEmpty) {
          debugLog(
            'ConsistencyAggregator skipped unparseable CompletedAt: '
            '${goal.completedAt}',
          );
        }
        continue;
      }
      final key = ConsistencyDate.dateOnly(parsed);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Day counts for a single calendar month (only days present in [completed]).
  static Map<DateTime, int> countsForMonth(
    List<GoalSet> completed,
    int year,
    int month,
  ) {
    final all = countsByDay(completed);
    final out = <DateTime, int>{};
    all.forEach((day, count) {
      if (day.year == year && day.month == month) {
        out[day] = count;
      }
    });
    return out;
  }

  /// Goals completed on [day] (local date), sorted by CompletedAt ascending.
  static List<GoalSet> goalsOnDay(List<GoalSet> completed, DateTime day) {
    final key = ConsistencyDate.dateOnly(day);
    final matched = <GoalSet>[];
    for (final goal in completed) {
      final parsed = CompletionTimestamp.tryParse(goal.completedAt);
      if (parsed == null) continue;
      if (ConsistencyDate.sameDay(parsed, key)) {
        matched.add(goal);
      }
    }
    matched.sort((a, b) {
      final pa = CompletionTimestamp.tryParse(a.completedAt)!;
      final pb = CompletionTimestamp.tryParse(b.completedAt)!;
      return pa.compareTo(pb);
    });
    return matched;
  }

  /// Earliest month that has any completion, or null if none.
  static DateTime? earliestCompletionMonth(List<GoalSet> completed) {
    DateTime? earliest;
    for (final goal in completed) {
      final parsed = CompletionTimestamp.tryParse(goal.completedAt);
      if (parsed == null) continue;
      final month = ConsistencyDate.monthStart(parsed.year, parsed.month);
      if (earliest == null || month.isBefore(earliest)) {
        earliest = month;
      }
    }
    return earliest;
  }

  static int countOnDay(Map<DateTime, int> counts, DateTime day) =>
      counts[ConsistencyDate.dateOnly(day)] ?? 0;
}
