import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/screens/achievements_screen.dart';
import 'package:focusNexus/screens/ai_chat_screen.dart';
import 'package:focusNexus/screens/auth_start_screen.dart';
import 'package:focusNexus/screens/customization_screen.dart';
import 'package:focusNexus/screens/dashboard_screen.dart';
import 'package:focusNexus/screens/goals_screen.dart';
import 'package:focusNexus/screens/mini_games_screen.dart';
import 'package:focusNexus/screens/onboarding_screen.dart';
import 'package:focusNexus/screens/progressive_visual.dart';
import 'package:focusNexus/screens/progressive_visual_section.dart';
import 'package:focusNexus/screens/settings_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

/// Named routes for [MaterialApp.routes] (not [MaterialApp.router]).
abstract final class AppRoutes {
  AppRoutes._();

  static const auth = 'auth';
  static const onboard = 'onboard';
  static const dashboard = 'dashboard';
  static const settings = 'settings';
  static const reward = 'reward';
  static const chat = 'chat';
  static const achievements = 'achievements';
  static const goals = 'goals';
  static const progressiveVisual = 'progressive_visual';
  static const progressiveVisualSection = 'progressive_visual_section';

  static String initialFor(AppSettings settings) {
    if (settings.onboardingCompleted) return dashboard;
    if (settings.registrationComplete) return onboard;
    return auth;
  }

  static Map<String, WidgetBuilder> builders() {
    return {
      auth: (_) => const AuthStartScreen(),
      onboard: (_) => const OnboardingScreen(),
      dashboard: (_) => const DashboardScreen(),
      settings: (_) => const SettingsScreen(),
      reward: (_) => const _RewardRouteScreen(),
      chat: (_) => const AiChatScreen(),
      achievements: (_) => const AchievementScreen(),
      goals: (_) => const GoalsScreen(),
      progressiveVisual: (_) => const ProgressiveVisualScreen(),
      progressiveVisualSection: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final themeId =
            args is VisualThemeId ? args : VisualThemeId.zenGarden;
        return ProgressiveVisualSectionScreen(themeId: themeId);
      },
    };
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => _UnknownRouteScreen(routeName: settings.name),
    );
  }
}

class _RewardRouteScreen extends StatelessWidget {
  const _RewardRouteScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadRewardType(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ThemedSkeletonScaffold(
            title: 'Reward',
            bundle: AppRepositories.instance.theme.bundleFromSnapshot(
              AppRepositories.instance.settings.snapshot,
            ),
          );
        }

        switch (snapshot.data) {
          case 'Mini-games':
            return const MiniGamesScreen();
          case 'Progressive visuals':
            return const ProgressiveVisualScreen();
          case 'Customization':
            return const CustomizationScreen();
          default:
            return _UnknownRouteScreen(
              routeName: snapshot.data,
              message: '${snapshot.data} screen coming soon...',
            );
        }
      },
    );
  }

  static Future<String> _loadRewardType() async {
    final reward = await AppRepositories.instance.userPrefs.readString(
      StorageKeys.rewardType,
    );
    return reward ?? 'Mini-games';
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({
    this.routeName,
    this.message,
  });

  final String? routeName;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final title = routeName ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(message ?? 'Unknown route: $title'),
      ),
    );
  }
}
