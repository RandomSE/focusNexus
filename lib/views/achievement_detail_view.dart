import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/utils/common_utils.dart';

class AchievementDetailView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final achievement = this.achievement;
    final buttonDisabled = ref.watch(
      achievementDetailDisabledProvider(achievement.id),
    );
    final toRefresh = ref.watch(
      achievementDetailRefreshProvider(achievement.id),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _pop(context, toRefresh);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => _pop(context, toRefresh),
          ),
          title: Text(achievement.title, style: textStyle),
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
              Text(
                'Progress: ${achievement.progress.toStringAsFixed(1)}%',
                style: textStyle,
              ),
              const SizedBox(height: 8),
              if (achievement.isCompleted && achievement.dateCompleted != null)
                Text(
                  'Completed on: ${achievement.dateCompleted}',
                  style: textStyle,
                ),
              const Spacer(),
              if (!buttonDisabled &&
                  achievement.progress >= 100 &&
                  !achievement.isCompleted) ...[
                CommonUtils.buildElevatedButton(
                  'Complete Achievement',
                  primaryColor,
                  secondaryColor,
                  textStyle,
                  14,
                  10,
                  () async {
                    ref
                        .read(achievementDetailRefreshProvider(achievement.id).notifier)
                        .markRefresh();
                    await achievementService.completeAchievement(
                      achievement.id,
                    );
                    if (!context.mounted) return;
                    ref
                        .read(achievementDetailDisabledProvider(achievement.id).notifier)
                        .disable();
                    CommonUtils.showSnackBar(
                      context,
                      'Achievement completed! Well done on completing ${achievement.title}',
                      textStyle,
                      2000,
                      12,
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _pop(context, toRefresh),
                style: buttonStyle,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _pop(BuildContext context, bool refreshList) {
    Navigator.of(context).pop(refreshList);
  }
}
