import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/views/achievement_detail_view.dart';
import 'package:focusNexus/widgets/deferred_screen.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  Future<void> _openAchievement(
    WidgetRef ref,
    BuildContext context,
    Achievement achievement,
    ThemeBundle bundle,
    AchievementService service,
  ) async {
    final refreshList = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AchievementDetailView(
          achievement: achievement,
          themeData: bundle.themeData,
          primaryColor: bundle.primaryColor,
          secondaryColor: bundle.secondaryColor,
          textStyle: bundle.textStyle,
          buttonStyle: bundle.buttonStyle,
          achievementService: service,
        ),
      ),
    );
    if (refreshList == true) {
      ref.read(achievementsListRefreshProvider.notifier).bump();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshGen = ref.watch(achievementsListRefreshProvider);
    final service = ref.watch(achievementServiceProvider);
    final loader = _AchievementLoader(service);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return DeferredScreen<_AchievementLists>(
          loadToken: 'achievements-list-$refreshGen',
          load: loader._loadAchievements,
          loading: (_) => themedLoadingShell(
            bundle,
            title: 'Achievements',
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                SkeletonBlock(
                  background: bundle.secondaryColor,
                  foreground: bundle.primaryColor.withValues(alpha: 0.25),
                  height: 24,
                  width: 200,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < 5; i++) ...[
                  SkeletonBlock(
                    background: bundle.secondaryColor,
                    foreground: bundle.primaryColor.withValues(alpha: 0.25),
                    height: 52,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          builder: (context, data) {
            return Theme(
              data: bundle.themeData,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Achievements',
                    style: TextStyle(
                      backgroundColor: bundle.secondaryColor,
                      color: bundle.primaryColor,
                    ),
                  ),
                  backgroundColor: bundle.secondaryColor,
                  iconTheme: IconThemeData(color: bundle.primaryColor),
                ),
                backgroundColor: bundle.secondaryColor,
                body: Container(
                  color: bundle.secondaryColor,
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'In-progress achievements',
                          style: bundle.textStyle.copyWith(
                            color: Colors.deepPurple,
                          ),
                        ),
                        ...data.inProgress.map((achievement) {
                          final buttonColor = achievement.progress >= 100
                              ? Colors.deepPurple
                              : bundle.secondaryColor;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: CommonUtils.buildElevatedButton(
                              achievement.title,
                              bundle.primaryColor,
                              buttonColor,
                              bundle.textStyle,
                              14,
                              10,
                              () => _openAchievement(
                                ref,
                                context,
                                achievement,
                                bundle,
                                service,
                              ),
                            ),
                          );
                        }),
                        Text(
                          'Completed achievements',
                          style: bundle.textStyle.copyWith(
                            color: Colors.deepPurple,
                          ),
                        ),
                        ...data.completed.map((achievement) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: CommonUtils.buildElevatedButton(
                              achievement.title,
                              bundle.primaryColor,
                              bundle.secondaryColor,
                              bundle.textStyle,
                              14,
                              10,
                              () => _openAchievement(
                                ref,
                                context,
                                achievement,
                                bundle,
                                service,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AchievementLists {
  const _AchievementLists({
    required this.inProgress,
    required this.completed,
  });

  final List<Achievement> inProgress;
  final List<Achievement> completed;
}

class _AchievementLoader {
  _AchievementLoader(this.service);
  final AchievementService service;

  Future<_AchievementLists> _loadAchievements() async {
    await service.initialize();
    return _AchievementLists(
      inProgress: service.all
          .where((a) => !a.isSecret)
          .where((a) => !a.isCompleted)
          .toList(),
      completed: service.all.where((a) => a.isCompleted).toList(),
    );
  }
}
