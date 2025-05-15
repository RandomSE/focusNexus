// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FocusNexus Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
            child: const Text('Goal Setting'),
          ),
        ],
      ),
    );
  }
}
