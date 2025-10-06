import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';
import '../utils/common_utils.dart';

import '../models/classes/theme_bundle.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAchievementScreen();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (!_themeLoaded) {
      // show placeholder while theme loads
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              CommonUtils.buildText('Test 1', _textStyle),
              CommonUtils.buildText('Test 2', _textStyle),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAchievementScreen() async {
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle);
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
