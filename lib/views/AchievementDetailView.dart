import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/common_utils.dart';

import '../models/classes/achievement.dart';

class AchievementDetailView extends StatelessWidget {
  final Achievement achievement;
  final ThemeData themeData;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;
  final ButtonStyle buttonStyle;

  const AchievementDetailView({
    Key? key,
    required this.achievement,
    required this.themeData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
    required this.buttonStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String achievementId = achievement.id;
    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            achievement.title,
            style: textStyle,
          ),
          backgroundColor: secondaryColor,
          iconTheme: IconThemeData(color: primaryColor),
        ),
        backgroundColor: secondaryColor,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Task: ${achievement.task}', style: textStyle),
              const SizedBox(height: 8),
              Text('Reward: ${achievement.reward}', style: textStyle),
              const SizedBox(height: 8),
              Text('Progress: ${achievement.progress.toStringAsFixed(1)}%', style: textStyle),
              const SizedBox(height: 8),
              if (achievement.isCompleted && achievement.dateCompleted != null)
                Text('Completed on: ${achievement.dateCompleted}', style: textStyle),
              const Spacer(),
              // Complete button (disabled if not ready)
              CommonUtils.buildElevatedButton(
                'Complete Achievement',
                primaryColor,
                secondaryColor,
                14,
                10,
                (achievement.progress >= 100 && !achievement.isCompleted)
                    ? () {
                  debugPrint('Achievement ID: $achievementId'); // TODO: achievement completion logic
                }
                    : null, // disabled if condition not met
              ),
              const SizedBox(height: 12),
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: buttonStyle,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
