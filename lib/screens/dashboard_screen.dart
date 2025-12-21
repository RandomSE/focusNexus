// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';

import '../models/classes/achievement_tracking_variables.dart';
import '../models/classes/theme_bundle.dart';
import '../utils/common_utils.dart';
import '../utils/notifier.dart';
import '../services/achievement_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends BaseState<DashboardScreen> {
  final _storage = const FlutterSecureStorage();
  int _points = 0;
  bool _themeLoaded = false;
  late ThemeData _themeData;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  late String _rewardType;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    await _loadPoints();
    await AchievementTrackingVariables().initializeIfNeeded();
    final storedType = await rewardType;
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle, storedType);
    await AchievementService().initialize();
    GoalNotifier.initialize();
  }

  Future<void> setThemeDataScreen (ThemeBundle themeBundle, String storedType)  async {
    setState(() {
      _themeData = themeBundle.themeData;
      _secondaryColor = themeBundle.secondaryColor;
      _textStyle = themeBundle.textStyle;
      _themeLoaded = true;
      _rewardType = storedType;
    });
  }

  Future<void> _loadPoints() async {
    final stored = await _storage.read(key: 'points');
    final value = stored == null ? 50 : int.tryParse(stored) ?? 50;
    if (stored == null) await _storage.write(key: 'points', value: '50');
    setState(() => _points = value);
  }





  @override
  Widget build(BuildContext context) {

    while (!_themeLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Theme(
      data: _themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Dashboard',
            style: _textStyle,
            textAlign: TextAlign.center,
          ),
          backgroundColor: _secondaryColor,
        ),
        backgroundColor: _secondaryColor,
        body: Container(
          color: _secondaryColor,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Points: $_points', style: _textStyle, textAlign: TextAlign.left),
              ),
              const SizedBox(height: 60),

              CommonUtils.buildCenteredButton(
                context, 'Settings', () => Navigator.pushNamed(context, 'settings', arguments: context).then((_) => _themeLoaded = false),
                _textStyle, _secondaryColor,
              ),

              CommonUtils.buildCenteredButton(
                context, 'Reward: $_rewardType', () => Navigator.pushNamed(context, 'reward'),
                _textStyle, _secondaryColor,
              ),

              CommonUtils.buildCenteredButton(
                context, 'AI Chat / Therapist Space', () => Navigator.pushNamed(context, 'chat'),
                _textStyle, _secondaryColor,
              ),

              CommonUtils.buildCenteredButton(
                context, 'Achievements', () => Navigator.pushNamed(context, 'achievements'), _textStyle, _secondaryColor,
              ),

              CommonUtils.buildCenteredButton(
                context, 'Goal Setting', () =>
                    Navigator.pushNamed(context, 'goals').then((_) =>
                        _loadPoints()),
                _textStyle, _secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}