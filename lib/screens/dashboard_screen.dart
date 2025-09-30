// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';

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
    _loadPoints();
    _themeData = ThemeData.light();
    initializeTheme(); // async theme setup from storage
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storedType = await _storage.read(key: 'rewardType');
    if (mounted) {
      setState(() {
        _rewardType = storedType ?? 'Avatar';
      });
    }
    GoalNotifier.initialize();
  }

  Future<void> initializeTheme() async {
    ThemeData loadedTheme;

    final String? storedTheme = await _storage.read(key: 'themeData');
    await Future.delayed(const Duration(seconds: 1));
    if (storedTheme != null) {
      loadedTheme = parseThemeData(storedTheme);
    } else {
      loadedTheme = await setAndGetThemeData(
        isDark: userTheme == 'dark',
        highContrastMode: highContrastMode,
        userFontSize: userFontSize,
        useDyslexiaFont: useDyslexiaFont,
      );
    }

    if (mounted) {
      setState(() {
        _themeData = loadedTheme;
        _primaryColor = loadedTheme.primaryColor;
        _secondaryColor = loadedTheme.scaffoldBackgroundColor;
        _textStyle = loadedTheme.textTheme.bodyMedium!;
        _buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: _primaryColor,
        );
        _themeLoaded = true;
      });
    }
    refreshDashboardTheme();
  }

  @override
  void onThemeUpdated() {
    refreshDashboardTheme();
  }

  Future<void> refreshDashboardTheme() async {
    await initializeTheme();
  }

  void triggerThemeRefresh() {
    setState(() {
      _themeLoaded = false;
    });
  }

  Future<void> _loadPoints() async {
    final stored = await _storage.read(key: 'points');
    final value = stored == null ? 50 : int.tryParse(stored) ?? 50;
    if (stored == null) await _storage.write(key: 'points', value: '50');
    setState(() => _points = value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _loadPoints(); // Refresh points
      refreshDashboardTheme();
    });
  }

  static Future<void> addPoints(int amount, String source) async {
    final storage = FlutterSecureStorage();
    final stored = await storage.read(key: 'points');
    final current = int.tryParse(stored ?? '50') ?? 50;
    final newTotal = current + amount;
    await storage.write(key: 'points', value: newTotal.toString());
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
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(
        userFontSize, primaryColor, useDyslexiaFont);

    if (!_themeLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Theme(
      data: _themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'FocusNexus Dashboard',
            style: TextStyle(
                backgroundColor: secondaryColor, color: primaryColor),
            textAlign: TextAlign.center,
          ),
          backgroundColor: secondaryColor,
        ),
        backgroundColor: secondaryColor,
        body: Container(
          color: secondaryColor,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Points: $_points', style: textStyle, textAlign: TextAlign.left),
              ),
              const SizedBox(height: 60),

              _buildCenteredButton(
                context,
                label: 'Settings',
                onPressed: () =>
                    Navigator.pushNamed(context, 'settings', arguments: context)
                        .then((_) => _themeLoaded = false),
                style: textStyle,
                backgroundColor: secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'Reward: $_rewardType',
                onPressed: () => Navigator.pushNamed(context, 'reward'),
                style: textStyle,
                backgroundColor: secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'AI Chat / Therapist Space',
                onPressed: () => Navigator.pushNamed(context, 'chat'),
                style: textStyle,
                backgroundColor: secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'Achievements',
                onPressed: () => Navigator.pushNamed(context, 'achievements'),
                style: textStyle,
                backgroundColor: secondaryColor,
              ),

              _buildCenteredButton(
                context,
                label: 'Goal Setting',
                onPressed: () =>
                    Navigator.pushNamed(context, 'goals').then((_) =>
                        _loadPoints()),
                style: textStyle,
                backgroundColor: secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}