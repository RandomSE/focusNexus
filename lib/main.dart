// lib/main.dart
import 'package:flutter/material.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/settings/app_settings.dart';
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
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repos = AppRepositories.instance;
  await repos.settings.load();
  await dotenv.load(fileName: ".env");

  final initialRoute = _resolveInitialRoute(repos.settings);

  runApp(FocusNexusApp(initialRoute: initialRoute));
}

String _resolveInitialRoute(AppSettings settings) {
  if (settings.onboardingCompleted) return 'dashboard';
  if (settings.registrationComplete) return 'onboard';
  return 'auth';
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
    final settings = AppRepositories.instance.settings;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final snap = settings.snapshot;
        final scaffoldColor = ThemeStyles.resolveSecondaryColor(
          isDark: snap.isDark,
          highContrast: snap.highContrastMode,
          prefs: snap,
        );

        return MaterialApp(
      title: 'FocusNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          surface: scaffoldColor,
        ),
        scaffoldBackgroundColor: scaffoldColor,
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        final bg = resolveScaffoldBackground();
        return ColoredBox(
          color: bg,
          child: child ?? const SizedBox.shrink(),
        );
      },
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
                  return ThemedSkeletonScaffold(
                    title: 'Reward',
                    bundle: AppRepositories.instance.theme.bundleFromSnapshot(
                      AppRepositories.instance.settings.snapshot,
                    ),
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
