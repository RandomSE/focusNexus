// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:focusNexus/screens/goals_screen.dart';
import 'package:focusNexus/screens/onboarding_screen.dart';
import 'package:focusNexus/screens/settings_screen.dart';
import 'screens/auth_start_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  final loggedIn = await storage.read(key: 'loggedIn');
  final rememberMe = await storage.read(key: 'rememberMe');
  bool currentlyLoggedIn = false;

  // TODO: Privacy policy, terms & conditions.
  if (rememberMe == 'true' && loggedIn == 'true') { // If someone has both remember me and valid credentials, they can stay logged in. No remember me - not automatically logged back in.
    currentlyLoggedIn = true;
  }

  runApp(
    FocusNexusApp(initialRoute: currentlyLoggedIn ? 'dashboard' : 'auth'),
  );
}

Future<String> _getRewardTitle() async {
  final storage = FlutterSecureStorage();
  final reward = await storage.read(key: 'rewardType') ?? 'Avatar';
  return reward;
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
        'onboard': (_) => const OnboardingScreen(),
        'dashboard': (_) => const DashboardScreen(),
        'settings': (_) => const SettingsScreen(),
        'reward':
            (_) => FutureBuilder<String>(
              future: _getRewardTitle(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return PlaceholderScreen(snapshot.data!);
              },
            ),
        'chat': (_) => PlaceholderScreen('AI Chat / Therapist Space'),
        'achievements': (_) => PlaceholderScreen('Achievements'),
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
