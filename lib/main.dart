// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/screens/goals_screen.dart';
import 'package:focusNexus/screens/settings_screen.dart';
import 'screens/auth_start_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  final loggedIn = await storage.read(key: 'loggedIn');

  runApp(FocusNexusApp(initialRoute: loggedIn == 'true' ? 'dashboard' : 'auth'));
}

class FocusNexusApp extends StatelessWidget {
  final String initialRoute;
  const FocusNexusApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        'auth': (_) => const AuthStartScreen(),
        'dashboard': (_) => const DashboardScreen(),
        'settings': (_) => const SettingsScreen(),
        'reward': (_) => PlaceholderScreen('Avatar Customization'),
        'chat': (_) => PlaceholderScreen('AI Chat / Therapist Space'),
        'reminders': (_) => PlaceholderScreen('Reminders'),
        'achievements': (_) => PlaceholderScreen('Achievements'),
        'tasks': (_) => PlaceholderScreen('Tasks'),
        'goals': (_) => const GoalsScreen(),
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen coming soon...')),
    );
  }
}