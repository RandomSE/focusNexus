// lib/main.dart
import 'package:flutter/material.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/screens/achievements_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/screens/ai_chat_screen.dart';
import 'package:focusNexus/screens/customization_screen.dart';
import 'package:focusNexus/screens/goals_screen.dart';
import 'package:focusNexus/screens/mini_games_screen.dart';
import 'package:focusNexus/screens/onboarding_screen.dart';
import 'package:focusNexus/screens/progressive_visual.dart';
import 'package:focusNexus/screens/progressive_visual_section.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/screens/settings_screen.dart';
import 'screens/auth_start_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repos = AppRepositories.instance;
  await repos.settings.load();
  final loggedIn = repos.settings.loggedIn;
  final rememberMe = repos.settings.rememberMe;
  bool currentlyLoggedIn = false;
  await dotenv.load(fileName: ".env");

  // TODO: Privacy policy, terms & conditions.
  if (rememberMe && loggedIn) { // If someone has both remember me and valid credentials, they can stay logged in. No remember me - not automatically logged back in.
    currentlyLoggedIn = true;
  }

  runApp(
    FocusNexusApp(initialRoute: currentlyLoggedIn ? 'dashboard' : 'auth'),
  );
}

Future<String> _getRewardTitle() async {
  final reward = await AppRepositories.instance.userPrefs.readString(StorageKeys.rewardType);
  return reward ?? 'Mini-games';
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
                switch(snapshot.data){
                  case 'Mini-games':
                    return const MiniGamesScreen();
                  case 'Progressive visuals':
                    return const ProgressiveVisualScreen();
                  case 'Customization':
                    return const CustomizationScreen();
                  default:
                    return PlaceholderScreen(snapshot.data!);

                }
              },
            ),
        'chat': (_) => const AiChatScreen(),
        'achievements': (_) => const AchievementScreen(),
        'goals': (_) => const GoalsScreen(),
        'progressive_visual': (_) => const ProgressiveVisualScreen(),
        'progressive_visual_section': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final themeId = args is VisualThemeId ? args : VisualThemeId.zenGarden;
          return ProgressiveVisualSectionScreen(themeId: themeId);
        },
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
