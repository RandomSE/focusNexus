import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/common_utils.dart';

import '../models/classes/achievement.dart';
import '../services/achievement_service.dart';

class AchievementDetailView extends StatefulWidget {
  final Achievement achievement;
  final ThemeData themeData;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;
  final ButtonStyle buttonStyle;
  final AchievementService achievementService;

  const AchievementDetailView({
    super.key,
    required this.achievement,
    required this.themeData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
    required this.buttonStyle,
    required this.achievementService,
  });

  @override
  State<AchievementDetailView> createState() => _AchievementDetailViewState();
}

class _AchievementDetailViewState extends State<AchievementDetailView> {
  bool _buttonDisabled = false;
  bool _toRefresh = false;

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;


    return PopScope<Object?>(
        canPop: true,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          debugPrint("Should page refresh? didPop: $didPop, toRefresh: $_toRefresh");
          if ((didPop) && _toRefresh) {
            Future.microtask(() async {
              Navigator.of(context).pushReplacementNamed('achievements');
              debugPrint("Achievements re-opened after completing an achievement"); // When completing achievements, you update points. This is to reflect that visually.
            });
          }
        },


        child: Scaffold(
      appBar: AppBar(
        title: Text(achievement.title, style: widget.textStyle),
        backgroundColor: widget.secondaryColor,
        iconTheme: IconThemeData(color: widget.primaryColor),
      ),
      backgroundColor: widget.secondaryColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task: ${achievement.task}', style: widget.textStyle),
            const SizedBox(height: 8),
            Text('Reward: ${achievement.reward}', style: widget.textStyle),
            const SizedBox(height: 8),
            Text('Progress: ${achievement.progress.toStringAsFixed(1)}%', style: widget.textStyle),
            const SizedBox(height: 8),
            if (achievement.isCompleted && achievement.dateCompleted != null)
              Text('Completed on: ${achievement.dateCompleted}', style: widget.textStyle),
            const Spacer(),
            CommonUtils.buildElevatedButton(
              'Complete Achievement',
              widget.primaryColor,
              widget.secondaryColor,
              14,
              10,
              (!_buttonDisabled && achievement.progress >= 100 && !achievement.isCompleted)
                  ? () async {
                _toRefresh = true;
                await widget.achievementService.completeAchievement(achievement.id);
                setState(() {
                  _buttonDisabled = true; // disable after one click
                  _toRefresh = true;
                });
                CommonUtils.showSnackBar(context, 'Achievement completed! Well done on completing ${achievement.title}', widget.textStyle, 2000, 12);
              }
                  : null, // disabled if already clicked or not ready
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: widget.buttonStyle,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      )
    );
  }
}
