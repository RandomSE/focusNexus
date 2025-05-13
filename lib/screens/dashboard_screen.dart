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
            onPressed: () {},
            child: const Text('Settings'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Reward: Avatar'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('AI Chat / Therapist Space'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Reminders'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Achievements'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Tasks'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Goal Setting'),
          ),
        ],
      ),
    );
  }
}
