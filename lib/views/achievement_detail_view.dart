import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/utils/common_utils.dart';

class AchievementDetailView extends StatefulWidget {
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

  final Achievement achievement;
  final ThemeData themeData;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;
  final ButtonStyle buttonStyle;
  final AchievementService achievementService;

  @override
  State<AchievementDetailView> createState() => _AchievementDetailViewState();
}

class _AchievementDetailViewState extends State<AchievementDetailView> {
  bool _buttonDisabled = false;
  bool _toRefresh = false;

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;

    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_toRefresh),
          ),
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
              Text(
                'Progress: ${achievement.progress.toStringAsFixed(1)}%',
                style: widget.textStyle,
              ),
              const SizedBox(height: 8),
              if (achievement.isCompleted && achievement.dateCompleted != null)
                Text(
                  'Completed on: ${achievement.dateCompleted}',
                  style: widget.textStyle,
                ),
              const Spacer(),
              if (!_buttonDisabled &&
                  achievement.progress >= 100 &&
                  !achievement.isCompleted) ...[
                CommonUtils.buildElevatedButton(
                  'Complete Achievement',
                  widget.primaryColor,
                  widget.secondaryColor,
                  widget.textStyle,
                  14,
                  10,
                  () async {
                    _toRefresh = true;
                    await widget.achievementService.completeAchievement(
                      achievement.id,
                    );
                    if (!context.mounted) return;
                    setState(() => _buttonDisabled = true);
                    CommonUtils.showSnackBar(
                      context,
                      'Achievement completed! Well done on completing ${achievement.title}',
                      widget.textStyle,
                      2000,
                      12,
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _toRefresh),
                style: widget.buttonStyle,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
    );
  }
}
