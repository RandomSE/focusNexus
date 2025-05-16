// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 🔁 Convert DashboardScreen to StatefulWidget
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final storage = FlutterSecureStorage();
    final points = await storage.read(key: 'points');
    if (points == null) {
      await storage.write(key: 'points', value: '50');
      setState(() => _points = 50);
    } else {
      setState(() => _points = int.tryParse(points) ?? 50);
    }
  }

  Future<void> addUserPoints(int amount, String source) async {
    final storage = FlutterSecureStorage();
    final current = await storage.read(key: 'points');
    final currentValue = int.tryParse(current ?? '50') ?? 50;
    final newTotal = currentValue + amount;
    await storage.write(key: 'points', value: newTotal.toString());
    setState(() => _points = newTotal);
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
            child: const Text('Reward: Avatar'),
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
              onPressed: () => Navigator.pushNamed(context, 'goals'),
              child: const Text('Goal Setting')),
        ],
      ),
    );
  }
}
