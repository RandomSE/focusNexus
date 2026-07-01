import 'package:flutter/material.dart';

import 'package:focusNexus/goals/goal_deadline_label.dart';
import 'package:focusNexus/goals/goal_time_window_label.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Read-only goal detail dialog for the goals list.
Future<void> showGoalsGoalDetailsDialog({
  required BuildContext context,
  required ThemeBundle bundle,
  required GoalSet goal,
  required bool isCompleted,
  RepeatRule? repeatRule,
}) {
  final isTimeWindow = isTimeWindowGoal(goal);
  return showDialog<void>(
    context: context,
    barrierColor: bundle.secondaryColor,
    builder:
        (_) => AlertDialog(
          backgroundColor: bundle.secondaryColor,
          iconColor: bundle.primaryColor,
          title: Text(goal.title, style: bundle.textStyle),
          content: CommonUtils.scrollableDialogBody(
            context: context,
            heightFactor: 0.5,
            children: [
              Text('Category: ${goal.category}', style: bundle.textStyle),
              Text('Complexity: ${goal.complexity}', style: bundle.textStyle),
              Text('Effort: ${goal.effort}', style: bundle.textStyle),
              Text('Motivation: ${goal.motivation}', style: bundle.textStyle),
              Text(
                'Time Needed in minutes: ${goal.time}',
                style: bundle.textStyle,
              ),
              if (isCompleted)
                Text(
                  'Completed: ${goalCompletedLabel(goal.completedAt)}',
                  style: bundle.textStyle,
                )
              else if (isTimeWindow) ...[
                Text(goalTimeWindowLabel(goal), style: bundle.textStyle),
                Text(
                  isActionWindowActive(goal, DateTime.now())
                      ? 'In slot now'
                      : 'Outside slot',
                  style: bundle.textStyle,
                ),
              ] else
                Text(
                  'Deadline: ${goalDeadlineLabel(goal.deadline)}',
                  style: bundle.textStyle,
                ),
              if (goal.repeatSeriesId != 0)
                Text(
                  repeatRule != null && repeatRule.enabled
                      ? summarizeRepeatRule(repeatRule)
                      : 'Repeats',
                  style: bundle.textStyle,
                ),
              Text('Steps: ${goal.steps}', style: bundle.textStyle),
              Text('Points: ${goal.points}', style: bundle.textStyle),
              Text('Id: ${goal.goalId}', style: bundle.textStyle),
            ],
          ),
          actions: [
            Container(
              color: bundle.secondaryColor,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: bundle.textStyle),
              ),
            ),
          ],
        ),
  );
}
