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

  @override
  void initState() {
    super.initState();
    _loadPoints();
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
    final isDark = userTheme == 'dark';
    final themeData = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: highContrastMode ? Colors.yellow : Colors.deepPurple,
      scaffoldBackgroundColor: highContrastMode
          ? Colors.yellow.withOpacity(0.3)
          : isDark
          ? Colors.black.withOpacity(backgroundBrightness)
          : Colors.white.withOpacity(1 - backgroundBrightness),
      textTheme: Theme.of(context).textTheme.apply(
        fontSizeFactor: userFontSize / 14.0,
        fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null,
        bodyColor: isDark ? Colors.grey[300] : Colors.black,
        displayColor: isDark ? Colors.grey[300] : Colors.black,
      ),
    );

    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(title: const Text('FocusNexus Dashboard')),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Points: $_points', style: TextStyle(fontSize: userFontSize)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'settings')
                  .then((_) {
                setState(() {
                  _loadPoints();  // Reload points
                });
              }),
              child: const Text('Settings'),
            ),

            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'reward'),
              child: Text('Reward: $rewardType'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'chat'),
              child: const Text('AI Chat / Therapist Space'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'reminders'),
              child: const Text('Reminders'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'achievements'),
              child: const Text('Achievements'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'tasks'),
              child: const Text('Tasks'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, 'goals').then((_) => _loadPoints()),
              child: const Text('Goal Setting'),
            ),
          ],
        ),
      ),
    );
  }
}
