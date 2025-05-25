// lib/screens/dashboard_screen.dart (replaced with final version that can be updated live)
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/common_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _points = 0;
  final _storage = const FlutterSecureStorage();
  double userFontSize = 14.0;
  String userTheme = 'light';
  String rewardType = 'Avatar';

  @override
  void initState() {
    super.initState();
    _loadPoints();
    CommonUtils.getUserPreferences(this);
    _loadRewardType();
  }

  Future<void> _loadRewardType() async {
    final storage = FlutterSecureStorage();
    final stored = await storage.read(key: 'rewardType');
    setState(() {
      rewardType = stored ?? 'Avatar';
    });
  }

  Future<void> _loadPoints() async {
    final stored = await _storage.read(key: 'points');
    final value = stored == null ? 50 : int.tryParse(stored) ?? 50;
    if (stored == null) await _storage.write(key: 'points', value: '50');
    setState(() => _points = value);
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
    return Scaffold(
      appBar: AppBar(title: const Text('FocusNexus Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Points: $_points', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, 'settings'),
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
            onPressed: () => Navigator.pushNamed(context, 'goals').then((_) => _loadPoints()),
            child: const Text('Goal Setting'),
          ),
        ],
      ),
    );
  }
}
