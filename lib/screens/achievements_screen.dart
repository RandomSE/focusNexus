import 'package:flutter/material.dart';
import 'package:focusNexus/utils/BaseState.dart';
import '../utils/common_utils.dart';

import '../models/classes/theme_bundle.dart';
import '../models/classes/achievement.dart';
import '../services/achievement_service.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends BaseState<AchievementScreen> {
  late ThemeData _themeData;
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  late ButtonStyle _buttonStyle;
  bool _themeLoaded = false;
  final achievementService = AchievementService();
  late List<Achievement> inProgressAchievements;
  late List<Achievement> completedAchievements;


  @override
  void initState() {
    super.initState();
    _loadAchievementScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope<Object?>(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          Future.microtask(() async {
            Navigator.of(context).pushReplacementNamed('dashboard');
            debugPrint("Dashboard re-opened and updated after exiting achievements"); // When completing achievements, you update points. This is to reflect that visually.
          });
        }
      },

    child: Theme(
      data: _themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Achievements',
            style: TextStyle(
              backgroundColor: _secondaryColor,
              color: _primaryColor,
            ),
          ),
          backgroundColor: _secondaryColor,
          iconTheme: IconThemeData(color: _primaryColor),
        ),
        backgroundColor: _secondaryColor,
        body: Container(
          color: _secondaryColor,
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'In-progress achievements',
                  style: _textStyle,
                ),
                ...inProgressAchievements.map((achievement) {
                  final buttonColor = achievement.progress >= 100 ? Colors.deepPurple : _primaryColor;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: CommonUtils.buildElevatedButton(
                      achievement.title, buttonColor, _secondaryColor, 14, 10,
                          () => AchievementService.viewAchievement(achievement.id, _themeData, _primaryColor, _secondaryColor, _textStyle, _buttonStyle, context)
                    ),
                  );
                }),
                Text(
                  'Completed achievements',
                  style: _textStyle,
                ),
                ...completedAchievements.map((achievement) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: CommonUtils.buildElevatedButton(
                        achievement.title, _primaryColor, _secondaryColor, 14, 10,
                            () => AchievementService.viewAchievement(achievement.id, _themeData, _primaryColor, _secondaryColor, _textStyle, _buttonStyle, context)
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }

  Future<void> _loadAchievementScreen() async {
    await achievementService.initialize();
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle);

    // Ensure achievements are initialized before accessing .all


    setState(() {
      inProgressAchievements = achievementService.all
          .where((a) => !a.isSecret)
          .where((a) => !a.isCompleted)
          .toList();
    });

    setState(() {
      completedAchievements = achievementService.all
          .where((a) => a.isCompleted)
          .toList();
    });

    debugPrint('Loaded ${inProgressAchievements.length} visible achievements.');
  }


  Future<void> setThemeDataScreen(ThemeBundle themeBundle) async {
    setState(() {
      _themeData = themeBundle.themeData;
      _primaryColor = themeBundle.primaryColor;
      _secondaryColor = themeBundle.secondaryColor;
      _textStyle = themeBundle.textStyle;
      _buttonStyle = themeBundle.buttonStyle;
      _themeLoaded = true;
    });
  }
}
