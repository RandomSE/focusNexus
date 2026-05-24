import 'package:flutter/material.dart';
import '../models/classes/achievement.dart';
import '../services/achievement_service.dart';
import '../utils/common_utils.dart';
import '../utils/screen_theme.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/settings_themed_builder.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final achievementService = AchievementService();
  List<Achievement> inProgressAchievements = [];
  List<Achievement> completedAchievements = [];
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    await achievementService.initialize();
    if (!mounted) return;
    setState(() {
      inProgressAchievements = achievementService.all
          .where((a) => !a.isSecret)
          .where((a) => !a.isCompleted)
          .toList();
      completedAchievements =
          achievementService.all.where((a) => a.isCompleted).toList();
      _dataReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        if (!_dataReady) {
          return themedLoadingShell(
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
          );
        }
        return PopScope<Object?>(
          canPop: true,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              Future.microtask(() {
                Navigator.of(context).pushReplacementNamed('dashboard');
              });
            }
          },
          child: Theme(
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
                        style: bundle.textStyle.copyWith(color: Colors.deepPurple),
                      ),
                      ...inProgressAchievements.map((achievement) {
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
                            () => AchievementService.viewAchievement(
                              achievement.id,
                              bundle.themeData,
                              bundle.primaryColor,
                              bundle.secondaryColor,
                              bundle.textStyle,
                              bundle.buttonStyle,
                              context,
                            ),
                          ),
                        );
                      }),
                      Text(
                        'Completed achievements',
                        style: bundle.textStyle.copyWith(color: Colors.deepPurple),
                      ),
                      ...completedAchievements.map((achievement) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: CommonUtils.buildElevatedButton(
                            achievement.title,
                            bundle.primaryColor,
                            bundle.secondaryColor,
                            bundle.textStyle,
                            14,
                            10,
                            () => AchievementService.viewAchievement(
                              achievement.id,
                              bundle.themeData,
                              bundle.primaryColor,
                              bundle.secondaryColor,
                              bundle.textStyle,
                              bundle.buttonStyle,
                              context,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
