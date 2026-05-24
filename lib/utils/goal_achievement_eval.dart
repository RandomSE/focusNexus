import 'package:intl/intl.dart';

import '../models/classes/goal_set.dart';

/// Which achievement counters should increment when a goal completes.
class GoalAchievementIncrements {
  const GoalAchievementIncrements({
    this.highPoints = false,
    this.highComplexity = false,
    this.highEffort = false,
    this.highMotivation = false,
    this.allHigh = false,
    this.highTimeRequirement = false,
    this.manySteps = false,
    this.completedEarly = false,
  });

  final bool highPoints;
  final bool highComplexity;
  final bool highEffort;
  final bool highMotivation;
  final bool allHigh;
  final bool highTimeRequirement;
  final bool manySteps;
  final bool completedEarly;
}

class GoalAchievementEval {
  GoalAchievementEval._();

  static GoalAchievementIncrements evaluate(GoalSet goal, DateTime now) {
    final bool isHighComplexity = goal.complexity.toLowerCase() == 'high';
    final bool isHighEffort = goal.effort.toLowerCase() == 'high';
    final bool isHighMotivation = goal.motivation.toLowerCase() == 'high';
    final bool isAllHigh =
        isHighComplexity && isHighEffort && isHighMotivation;

    var completedEarly = false;
    if (goal.deadline.isNotEmpty && goal.deadline != 'no deadline') {
      try {
        final DateTime deadlineDate =
            DateFormat('dd MMMM yyyy HH:mm').parse(goal.deadline);
        final Duration difference = deadlineDate.difference(now);
        completedEarly = difference.inHours >= 20;
      } catch (_) {
        completedEarly = false;
      }
    }

    return GoalAchievementIncrements(
      highPoints: goal.points >= 100,
      highComplexity: isHighComplexity,
      highEffort: isHighEffort,
      highMotivation: isHighMotivation,
      allHigh: isAllHigh,
      highTimeRequirement: goal.time >= 150,
      manySteps: goal.steps >= 15,
      completedEarly: completedEarly,
    );
  }
}
