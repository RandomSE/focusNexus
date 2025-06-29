// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/utils/BaseState.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends BaseState<DashboardScreen> {
  final _storage = const FlutterSecureStorage();
  int _points = 0;
  late ThemeData _themeData;

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _themeData = defaultThemeData; // Start with default
    loadStoredTheme(); // Try loading stored theme data
    setThemeData();
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
      _loadPoints();  // Refresh points
    });
  }


  static Future<void> addPoints(int amount, String source) async {
    final storage = FlutterSecureStorage();
    final stored = await storage.read(key: 'points');
    final current = int.tryParse(stored ?? '50') ?? 50;
    final newTotal = current + amount;
    await storage.write(key: 'points', value: newTotal.toString());
  }

  static Future<void> refreshDashboardPoints(BuildContext context) async {
    final state = context.findAncestorStateOfType<_DashboardScreenState>();
    if (state != null) {
      await state._loadPoints();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(userFontSize, primaryColor, useDyslexiaFont);


    return Theme(
      data: _themeData,
      child: Scaffold(
        appBar: AppBar(title:  Text('FocusNexus Dashboard', style: TextStyle(backgroundColor: secondaryColor, color: primaryColor)), backgroundColor: secondaryColor),
        backgroundColor: secondaryColor,
        body: Container(
          color: secondaryColor,
          child: ListView(
              padding: const EdgeInsets.all(16.0),
          children: [
            Text('Points: $_points', style: textStyle),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'settings')
                  .then((_) {
                setState(() {
                  _loadPoints();  // Reload points
                });
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor, // 🔹 Applies secondaryColor as background
              ),
              child:  Text('Settings', style: textStyle),
            ),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'reward'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor, // 🔹 Applies secondaryColor as background
              ),
              child: Text('Reward: $rewardType', style: textStyle),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor, // 🔹 Applies secondaryColor as background
              ),
              child:  Text('AI Chat / Therapist Space' , style: textStyle),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'reminders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor, // 🔹 Applies secondaryColor as background
              ),
              child:  Text('Reminders', style: textStyle),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'achievements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor, // 🔹 Applies secondaryColor as background
              ),
              child:  Text('Achievements', style: textStyle),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'tasks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor, // 🔹 Applies secondaryColor as background
              ),
              child:  Text('Tasks', style: textStyle),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, 'goals').then((_) => _loadPoints()),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor, // 🔹 Applies secondaryColor as background
              ),
              child:  Text('Goal Setting', style: textStyle),
            ),

          ],
        ),
      ),
      )
    );
  }
}
