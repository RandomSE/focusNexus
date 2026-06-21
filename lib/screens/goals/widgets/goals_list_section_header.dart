import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

class GoalsListSectionHeader extends StatelessWidget {
  const GoalsListSectionHeader({super.key, required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 2,
          thickness: 2,
          color: bundle.primaryColor.withValues(alpha: 0.35),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            'Your goals',
            style: bundle.textStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: bundle.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildStepDisplay(GoalSet g, double userFontSize) {
  final totalSteps = g.steps > 0 ? g.steps : 1;
  final currentProgress = g.stepProgress.clamp(0, totalSteps);

  if (totalSteps > 10) {
    return Text(
      'Step $currentProgress/$totalSteps',
      style: TextStyle(fontSize: userFontSize),
    );
  }

  return Wrap(
    spacing: 4.0,
    runSpacing: 4.0,
    children: List.generate(
      totalSteps,
      (i) => Icon(
        i < currentProgress ? Icons.check_box : Icons.check_box_outline_blank,
        size: userFontSize,
      ),
    ),
  );
}
