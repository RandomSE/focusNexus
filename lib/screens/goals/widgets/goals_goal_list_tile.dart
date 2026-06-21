import 'package:flutter/material.dart';

import 'package:focusNexus/goals/goal_deadline_label.dart';
import 'package:focusNexus/goals/goal_time_window_label.dart';
import 'package:focusNexus/goals/time_window_points_label.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

class GoalsGoalListTile extends StatelessWidget {
  const GoalsGoalListTile({
    super.key,
    required this.bundle,
    required this.selectedStatusFilter,
    required this.goal,
    required this.onComplete,
    required this.onIncrementStep,
    required this.onViewDetails,
    required this.onRemove,
    this.highlight = false,
  });

  final ThemeBundle bundle;
  final String selectedStatusFilter;
  final GoalSet goal;
  final VoidCallback onComplete;
  final VoidCallback onIncrementStep;
  final VoidCallback onViewDetails;
  final VoidCallback onRemove;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final steps = goal.steps > 0 ? goal.steps : 1;
    final isTimeWindow = isTimeWindowGoal(goal);
    final inWindow = selectedStatusFilter == 'Active' && isTimeWindow
        ? isActionWindowActive(goal, DateTime.now())
        : true;
    final outsideTimeWindow =
        selectedStatusFilter == 'Active' && isTimeWindow && !inWindow;
    final activeInWindow =
        selectedStatusFilter == 'Active' && isTimeWindow && inWindow;

    final titleStyle = bundle.textStyle.copyWith(
      color: outsideTimeWindow
          ? bundle.primaryColor.withValues(alpha: 0.45)
          : bundle.primaryColor,
      fontWeight: activeInWindow ? FontWeight.w700 : bundle.textStyle.fontWeight,
    );
    final subtitleStyle = bundle.textStyle.copyWith(
      fontSize: (bundle.textStyle.fontSize ?? 14) * 0.92,
      color: outsideTimeWindow
          ? bundle.primaryColor.withValues(alpha: 0.4)
          : bundle.primaryColor.withValues(alpha: 0.88),
    );

    final dateLabel = selectedStatusFilter == 'Completed'
        ? 'Completed ${goalCompletedLabel(goal.completedAt)}'
        : isTimeWindow
        ? goalTimeWindowLabel(goal)
        : goalDeadlineLabel(goal.deadline);
    final subtitleLines = <String>[
      if (isTimeWindow)
        timeWindowGoalPointsLabel(goal)
      else
        '${goal.points} pts · $dateLabel',
    ];
    if (isTimeWindow) {
      subtitleLines.add(dateLabel);
    }
    if (isTimeWindow) {
      subtitleLines.add(outsideTimeWindow ? 'Outside slot' : 'In slot now');
    }
    if (goal.repeatSeriesId != 0) {
      subtitleLines.add('Repeating');
    }
    if (selectedStatusFilter == 'Active' && steps > 1) {
      subtitleLines.add('Step ${goal.stepProgress.clamp(0, steps)}/$steps');
    }

    final actionColor = outsideTimeWindow
        ? Colors.black38
        : bundle.primaryColor;

    final tile = ListTile(
      key: ValueKey('goal-list-$selectedStatusFilter-${goal.goalId}'),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      titleTextStyle: titleStyle,
      textColor: titleStyle.color,
      tileColor: outsideTimeWindow
          ? Color.alphaBlend(
              Colors.black.withValues(alpha: 0.14),
              bundle.secondaryColor,
            )
          : activeInWindow
          ? Color.alphaBlend(
              bundle.accentColor.withValues(alpha: 0.14),
              bundle.secondaryColor,
            )
          : null,
      title: Text(
        goal.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      ),
      subtitle: Text(
        subtitleLines.join('\n'),
        style: subtitleStyle,
        maxLines: 4,
      ),
      onTap: onViewDetails,
      trailing: selectedStatusFilter == 'Active'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompactGoalAction(
                  tooltip: inWindow
                      ? 'Add Step Progress'
                      : 'Outside action window',
                  icon: Icons.add_circle_outline,
                  color: actionColor,
                  onPressed: inWindow ? onIncrementStep : null,
                ),
                _CompactGoalAction(
                  tooltip: inWindow
                      ? 'Complete Goal'
                      : 'Outside action window',
                  icon: Icons.add_task,
                  color: actionColor,
                  onPressed: inWindow ? onComplete : null,
                ),
                _CompactGoalAction(
                  tooltip: 'Remove Goal',
                  icon: Icons.delete,
                  color: bundle.primaryColor,
                  onPressed: onRemove,
                ),
              ],
            )
          : null,
    );

    if (selectedStatusFilter != 'Active') return tile;

    Color borderColor;
    double borderWidth;
    if (highlight) {
      borderColor = bundle.accentColor;
      borderWidth = 2.5;
    } else if (activeInWindow) {
      borderColor = bundle.accentColor.withValues(alpha: 0.9);
      borderWidth = 2;
    } else if (outsideTimeWindow) {
      borderColor = bundle.primaryColor.withValues(alpha: 0.22);
      borderWidth = 1;
    } else {
      borderColor = bundle.primaryColor.withValues(alpha: 0.5);
      borderWidth = 1.5;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(12),
        ),
        child: tile,
      ),
    );
  }
}

class _CompactGoalAction extends StatelessWidget {
  const _CompactGoalAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
