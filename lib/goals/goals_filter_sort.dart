import 'package:intl/intl.dart';

import 'package:focusNexus/models/classes/goal_set.dart';

/// Pure filter/sort for goals list UI (no I/O).
List<GoalSet> filterAndSortGoals({
  required List<GoalSet> source,
  required String categoryFilter,
  required String complexityFilter,
  required String sortBy,
  required DateFormat deadlineFormat,
}) {
  var goals = List<GoalSet>.from(source);

  if (categoryFilter != 'All') {
    goals = goals.where((g) => g.category == categoryFilter).toList();
  }
  if (complexityFilter != 'All') {
    goals = goals.where((g) => g.complexity == complexityFilter).toList();
  }

  switch (sortBy) {
    case 'Title A-Z':
      goals.sort((a, b) => a.title.compareTo(b.title));
    case 'Title Z-A':
      goals.sort((a, b) => b.title.compareTo(a.title));
    case 'Time ↑':
      goals.sort((a, b) => a.time.compareTo(b.time));
    case 'Time ↓':
      goals.sort((a, b) => b.time.compareTo(a.time));
    case 'Steps ↑':
      goals.sort((a, b) => a.steps.compareTo(b.steps));
    case 'Steps ↓':
      goals.sort((a, b) => b.steps.compareTo(a.steps));
    case 'Closest deadline':
      final withDeadline = <({GoalSet goal, DateTime parsed})>[];
      final withoutDeadline = <GoalSet>[];

      for (final goal in goals) {
        try {
          final parsed = deadlineFormat.parseStrict(goal.deadline);
          withDeadline.add((goal: goal, parsed: parsed));
        } catch (_) {
          withoutDeadline.add(goal);
        }
      }

      withDeadline.sort((a, b) => a.parsed.compareTo(b.parsed));
      goals = [
        ...withDeadline.map((e) => e.goal),
        ...withoutDeadline,
      ];
    default:
      break;
  }

  return goals;
}
