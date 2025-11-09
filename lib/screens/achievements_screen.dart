import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final _storage = const FlutterSecureStorage();
  final achievementService = AchievementService();
  late List<Achievement> visibleAchievements;


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

    return Theme(
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
                  'Incomplete goals',
                  style: _textStyle,
                ),
                ...visibleAchievements.map((achievement) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: CommonUtils.buildElevatedButton(
                      achievement.title,
                      ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: _secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                          () => AchievementService.viewAchievement(int.parse(achievement.id)),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadAchievementScreen() async {
    await achievementService.initialize();
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle);

    // Ensure achievements are initialized before accessing .all


    setState(() {
      visibleAchievements = achievementService.all
          .where((a) => !a.isSecret)
          .where((a) => !a.isCompleted)
          .toList();
    });

    debugPrint('Loaded ${visibleAchievements.length} visible achievements.');
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
