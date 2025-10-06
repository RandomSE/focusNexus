// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';

import '../models/classes/theme_bundle.dart';
import '../utils/notifier.dart';


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
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  late ButtonStyle _buttonStyle;
  late String _rewardType;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    await _loadPoints();
    final storedType = await rewardType;
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle, storedType);
    GoalNotifier.initialize();
  }

  Future<void> setThemeDataScreen (ThemeBundle themeBundle, String storedType)  async {
    setState(() {
      _themeData = themeBundle.themeData;
      _primaryColor = themeBundle.primaryColor;
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


  Widget _buildCenteredButton(
      BuildContext context, {
        required String label,
        required VoidCallback onPressed,
        required TextStyle style,
        required Color backgroundColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
            ),
            child: Text(label, style: style, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
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
            'FocusNexus Dashboard',
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

              _buildCenteredButton(
                context,
                label: 'Settings',
                onPressed: () =>
                    Navigator.pushNamed(context, 'settings', arguments: context)
                        .then((_) => _themeLoaded = false),
                style: _textStyle,
                backgroundColor: _secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'Reward: $_rewardType',
                onPressed: () => Navigator.pushNamed(context, 'reward'),
                style: _textStyle,
                backgroundColor: _secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'AI Chat / Therapist Space',
                onPressed: () => Navigator.pushNamed(context, 'chat'),
                style: _textStyle,
                backgroundColor: _secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'Achievements',
                onPressed: () => Navigator.pushNamed(context, 'achievements'),
                style: _textStyle,
                backgroundColor: _secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'Goal Setting',
                onPressed: () =>
                    Navigator.pushNamed(context, 'goals').then((_) =>
                        _loadPoints()),
                style: _textStyle,
                backgroundColor: _secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}