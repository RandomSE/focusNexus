import 'package:flutter/material.dart';

import 'package:focusNexus/goals/goal_time_window_label.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
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
    this.repeatRule,
  });

  final ThemeBundle bundle;
  final String selectedStatusFilter;
  final GoalSet goal;
  final VoidCallback onComplete;
  final VoidCallback onIncrementStep;
  final VoidCallback onViewDetails;
  final VoidCallback onRemove;
  final bool highlight;
  final RepeatRule? repeatRule;

  @override
  Widget build(BuildContext context) {
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
      fontWeight:
          activeInWindow ? FontWeight.w700 : bundle.textStyle.fontWeight,
    );
    final subtitleStyle = bundle.textStyle.copyWith(
      fontSize: (bundle.textStyle.fontSize ?? 14) * 0.92,
      color: outsideTimeWindow
          ? bundle.primaryColor.withValues(alpha: 0.4)
          : bundle.primaryColor.withValues(alpha: 0.88),
    );

    final subtitleLines = goalListSubtitleLines(
      goal: goal,
      selectedStatusFilter: selectedStatusFilter,
      now: DateTime.now(),
      repeatRule: repeatRule,
    );

    final actionColor = outsideTimeWindow
        ? Colors.black38
        : bundle.primaryColor;

    final tileColor = outsideTimeWindow
        ? Color.alphaBlend(
            Colors.black.withValues(alpha: 0.14),
            bundle.secondaryColor,
          )
        : activeInWindow
        ? Color.alphaBlend(
            bundle.accentColor.withValues(alpha: 0.14),
            bundle.secondaryColor,
          )
        : null;

    final content = Material(
      color: tileColor ?? Colors.transparent,
      child: InkWell(
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  if (selectedStatusFilter == 'Active')
                    Row(
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
                    ),
                ],
              ),
              if (subtitleLines.isNotEmpty) const SizedBox(height: 4),
              for (final line in subtitleLines)
                Text(
                  line,
                  style: subtitleStyle,
                  softWrap: true,
                ),
            ],
          ),
        ),
      ),
    );

    if (selectedStatusFilter != 'Active') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: content,
      );
    }

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
        child: content,
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
