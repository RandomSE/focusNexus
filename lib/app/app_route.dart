import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/screens/achievements_screen.dart';
import 'package:focusNexus/screens/ai_chat_screen.dart';
import 'package:focusNexus/screens/auth_start_screen.dart';
import 'package:focusNexus/screens/customization_screen.dart';
import 'package:focusNexus/screens/dashboard_screen.dart';
import 'package:focusNexus/screens/goals/time_window_bulk_create_wizard.dart';
import 'package:focusNexus/screens/goals/time_window_calendar_placeholder_screen.dart';
import 'package:focusNexus/screens/goals/time_window_goals_hub_screen.dart';
import 'package:focusNexus/screens/goals/time_window_manual_create_screen.dart';
import 'package:focusNexus/screens/goals_screen.dart';
import 'package:focusNexus/screens/mini_games_screen.dart';
import 'package:focusNexus/screens/onboarding_screen.dart';
import 'package:focusNexus/screens/progressive_visual_section.dart';
import 'package:focusNexus/screens/settings_screen.dart';
import 'package:focusNexus/settings/app_settings.dart';

/// Persisted reward-type strings mapped to concrete reward destinations.
enum RewardKind {
  miniGames('Mini-games'),
  progressiveVisuals('Progressive visuals'),
  customization('Customization');

  const RewardKind(this.storageValue);
  final String storageValue;

  static RewardKind parse(String? raw) {
    return RewardKind.values.firstWhere(
      (kind) => kind.storageValue == raw,
      orElse: () => RewardKind.miniGames,
    );
  }
}

/// Typed app destinations. Use [path] only at the [MaterialApp] boundary.
sealed class AppRoute {
  const AppRoute();

  String get path;

  /// Arguments for [Navigator.pushNamed] when required.
  Object? get navigationArguments => null;

  static const auth = AuthRoute();
  static const onboard = OnboardRoute();
  static const dashboard = DashboardRoute();
  static const settings = SettingsRoute();
  static const reward = RewardRoute();
  static const chat = ChatRoute();
  static const achievements = AchievementsRoute();
  static const goals = GoalsRoute();
  static const timeWindowHub = TimeWindowHubRoute();
  static const progressiveVisual = ProgressiveVisualRoute();

  static AppRoute fromRouteSettings(RouteSettings settings) {
    return switch (settings.name) {
      AuthRoute.routeName => auth,
      OnboardRoute.routeName => onboard,
      DashboardRoute.routeName => dashboard,
      SettingsRoute.routeName => AppRoute.settings,
      RewardRoute.routeName => reward,
      ChatRoute.routeName => chat,
      AchievementsRoute.routeName => achievements,
      GoalsRoute.routeName => GoalsRoute(GoalsRoute.goalIdFrom(settings.arguments)),
      TimeWindowHubRoute.routeName => timeWindowHub,
      TimeWindowManualRoute.routeName => const TimeWindowManualRoute(),
      TimeWindowCalendarRoute.routeName => const TimeWindowCalendarRoute(),
      TimeWindowBulkCreateRoute.routeName => const TimeWindowBulkCreateRoute(),
      ProgressiveVisualRoute.routeName => progressiveVisual,
      ProgressiveVisualSectionRoute.routeName => ProgressiveVisualSectionRoute(
        ProgressiveVisualSectionRoute.themeIdFrom(settings.arguments),
      ),
      _ => UnknownRoute(settings.name),
    };
  }
}

final class AuthRoute extends AppRoute {
  const AuthRoute();
  static const routeName = 'auth';
  @override
  String get path => routeName;
}

final class OnboardRoute extends AppRoute {
  const OnboardRoute();
  static const routeName = 'onboard';
  @override
  String get path => routeName;
}

final class DashboardRoute extends AppRoute {
  const DashboardRoute();
  static const routeName = 'dashboard';
  @override
  String get path => routeName;
}

final class SettingsRoute extends AppRoute {
  const SettingsRoute();
  static const routeName = 'settings';
  @override
  String get path => routeName;
}

final class RewardRoute extends AppRoute {
  const RewardRoute();
  static const routeName = 'reward';
  @override
  String get path => routeName;
}

final class ChatRoute extends AppRoute {
  const ChatRoute();
  static const routeName = 'chat';
  @override
  String get path => routeName;
}

final class AchievementsRoute extends AppRoute {
  const AchievementsRoute();
  static const routeName = 'achievements';
  @override
  String get path => routeName;
}

final class GoalsRoute extends AppRoute {
  const GoalsRoute([this.highlightGoalId]);

  final int? highlightGoalId;

  static const routeName = 'goals';

  static int? goalIdFrom(Object? arguments) {
    if (arguments is int) return arguments;
    if (arguments is String) return int.tryParse(arguments);
    return null;
  }

  @override
  String get path => routeName;

  @override
  Object? get navigationArguments => highlightGoalId;
}

final class TimeWindowHubRoute extends AppRoute {
  const TimeWindowHubRoute();
  static const routeName = 'time_window_hub';
  @override
  String get path => routeName;
}

final class TimeWindowManualRoute extends AppRoute {
  const TimeWindowManualRoute();
  static const routeName = 'time_window_manual';
  @override
  String get path => routeName;
}

final class TimeWindowCalendarRoute extends AppRoute {
  const TimeWindowCalendarRoute();
  static const routeName = 'time_window_calendar';
  @override
  String get path => routeName;
}

final class TimeWindowBulkCreateRoute extends AppRoute {
  const TimeWindowBulkCreateRoute();
  static const routeName = 'time_window_bulk';
  @override
  String get path => routeName;
}

final class ProgressiveVisualRoute extends AppRoute {
  const ProgressiveVisualRoute();
  static const routeName = 'progressive_visual';
  @override
  String get path => routeName;
}

final class ProgressiveVisualSectionRoute extends AppRoute {
  const ProgressiveVisualSectionRoute(this.themeId);

  final VisualThemeId themeId;

  static const routeName = 'progressive_visual_section';

  static VisualThemeId themeIdFrom(Object? arguments) {
    if (arguments is VisualThemeId) return arguments;
    if (arguments is String) {
      return VisualThemeId.values.firstWhere(
        (id) => id.name == arguments,
        orElse: () => VisualThemeId.zenGarden,
      );
    }
    return VisualThemeId.zenGarden;
  }

  @override
  String get path => routeName;

  @override
  Object? get navigationArguments => themeId;
}

final class UnknownRoute extends AppRoute {
  const UnknownRoute(this.requestedPath);

  final String? requestedPath;

  @override
  String get path => requestedPath ?? 'unknown';
}

/// Onboarding / registration guards applied before building a route.
abstract final class AppRouteGuard {
  static AppRoute initialFor(AppSettings settings) {
    if (settings.onboardingCompleted) return AppRoute.dashboard;
    if (settings.registrationComplete) return AppRoute.onboard;
    return AppRoute.auth;
  }

  static AppRoute guard(AppRoute requested, AppSettings settings) {
    return switch (requested) {
      AuthRoute() => _guardAuth(settings),
      OnboardRoute() => _guardOnboard(settings),
      UnknownRoute() => requested,
      _ when !_canAccessMainApp(settings) => initialFor(settings),
      _ => requested,
    };
  }

  static AppRoute _guardAuth(AppSettings settings) {
    if (settings.onboardingCompleted) return AppRoute.dashboard;
    if (settings.registrationComplete) return AppRoute.onboard;
    return AppRoute.auth;
  }

  static AppRoute _guardOnboard(AppSettings settings) {
    if (settings.onboardingCompleted) return AppRoute.dashboard;
    if (!settings.registrationComplete) return AppRoute.auth;
    return AppRoute.onboard;
  }

  static bool _canAccessMainApp(AppSettings settings) =>
      settings.onboardingCompleted;
}

/// Builds widgets for [AppRoute] values and exposes [MaterialApp.routes].
abstract final class AppRouteRegistry {
  static Map<String, WidgetBuilder> materialRouteTable() {
    return {
      AuthRoute.routeName: (_) => const _GuardedRouteScreen(route: AppRoute.auth),
      OnboardRoute.routeName: (_) => const _GuardedRouteScreen(route: AppRoute.onboard),
      DashboardRoute.routeName: (_) =>
          const _GuardedRouteScreen(route: AppRoute.dashboard),
      SettingsRoute.routeName: (_) => const _GuardedRouteScreen(route: AppRoute.settings),
      RewardRoute.routeName: (_) => const _GuardedRouteScreen(route: AppRoute.reward),
      ChatRoute.routeName: (_) => const _GuardedRouteScreen(route: AppRoute.chat),
      AchievementsRoute.routeName: (_) =>
          const _GuardedRouteScreen(route: AppRoute.achievements),
      GoalsRoute.routeName: (context) {
        final requested = AppRoute.fromRouteSettings(
          ModalRoute.of(context)!.settings,
        );
        return _GuardedRouteScreen(route: requested);
      },
      TimeWindowHubRoute.routeName: (_) =>
          const _GuardedRouteScreen(route: TimeWindowHubRoute()),
      TimeWindowManualRoute.routeName: (_) =>
          const _GuardedRouteScreen(route: TimeWindowManualRoute()),
      TimeWindowCalendarRoute.routeName: (_) =>
          const _GuardedRouteScreen(route: TimeWindowCalendarRoute()),
      TimeWindowBulkCreateRoute.routeName: (_) =>
          const _GuardedRouteScreen(route: TimeWindowBulkCreateRoute()),
      ProgressiveVisualRoute.routeName: (_) =>
          const _GuardedRouteScreen(route: AppRoute.progressiveVisual),
      ProgressiveVisualSectionRoute.routeName: (context) {
        final requested = AppRoute.fromRouteSettings(
          ModalRoute.of(context)!.settings,
        );
        return _GuardedRouteScreen(route: requested);
      },
    };
  }

  static Widget build(BuildContext context, AppRoute route) {
    return switch (route) {
      AuthRoute() => const AuthStartScreen(),
      OnboardRoute() => const OnboardingScreen(),
      DashboardRoute() => const DashboardScreen(),
      SettingsRoute() => const SettingsScreen(),
      RewardRoute() => const RewardRouteScreen(),
      ChatRoute() => const AiChatScreen(),
      AchievementsRoute() => const AchievementScreen(),
      GoalsRoute(:final highlightGoalId) =>
        GoalsScreen(highlightGoalId: highlightGoalId),
      TimeWindowHubRoute() => const TimeWindowGoalsHubScreen(),
      TimeWindowManualRoute() => const TimeWindowManualCreateScreen(),
      TimeWindowCalendarRoute() => const TimeWindowCalendarPlaceholderScreen(),
      TimeWindowBulkCreateRoute() => const TimeWindowBulkCreateWizard(),
      ProgressiveVisualRoute() => const ProgressiveVisualSectionScreen(
        themeId: VisualThemeId.zenGarden,
      ),
      ProgressiveVisualSectionRoute(:final themeId) =>
        ProgressiveVisualSectionScreen(themeId: themeId),
      UnknownRoute(:final requestedPath) => UnknownRouteScreen(
        routeName: requestedPath,
      ),
    };
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => UnknownRouteScreen(routeName: settings.name),
    );
  }
}

/// Applies [AppRouteGuard] using live [AppSettings] from Riverpod.
class _GuardedRouteScreen extends ConsumerWidget {
  const _GuardedRouteScreen({required this.route});

  final AppRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider.notifier).service;
    final guarded = AppRouteGuard.guard(route, settings);
    return AppRouteRegistry.build(context, guarded);
  }
}

/// Resolves reward destination from loaded settings (no [FutureBuilder]).
class RewardRouteScreen extends ConsumerWidget {
  const RewardRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardType = ref.watch(appSettingsProvider).snapshot.rewardType;
    return switch (RewardKind.parse(rewardType)) {
      RewardKind.miniGames => const MiniGamesScreen(),
      RewardKind.progressiveVisuals => const ProgressiveVisualSectionScreen(
        themeId: VisualThemeId.zenGarden,
      ),
      RewardKind.customization => const CustomizationScreen(),
    };
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({
    super.key,
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
