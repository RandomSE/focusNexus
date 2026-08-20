import 'package:flutter/material.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/settings/app_settings.dart';

export 'package:focusNexus/app/app_navigation.dart';
export 'package:focusNexus/app/app_route.dart';

/// Back-compat facade for [MaterialApp.routes] wiring and legacy string constants.
abstract final class AppRoutes {
  AppRoutes._();

  static const auth = AuthRoute.routeName;
  static const registration = RegistrationRoute.routeName;
  static const onboard = OnboardRoute.routeName;
  static const dashboard = DashboardRoute.routeName;
  static const settings = SettingsRoute.routeName;
  static const soundEffects = SoundEffectsRoute.routeName;
  static const music = MusicRoute.routeName;
  static const backgroundMusic = BackgroundMusicRoute.routeName;
  static const customAffirmationPack = CustomAffirmationPackRoute.routeName;
  static const dashboardMotivatorPack = DashboardMotivatorPackRoute.routeName;
  static const dailyAffirmationPack = DailyAffirmationPackRoute.routeName;
  static const reward = RewardRoute.routeName;
  static const miniGames = MiniGamesRoute.routeName;
  static const miniGameLobby = MiniGameLobbyRoute.routeName;
  static const miniGamePlay = MiniGamePlayRoute.routeName;
  static const customization = CustomizationRoute.routeName;
  static const chat = ChatRoute.routeName;
  static const achievements = AchievementsRoute.routeName;
  static const consistencyExplorer = ConsistencyExplorerRoute.routeName;
  static const goals = GoalsRoute.routeName;
  static const timeWindowHub = TimeWindowHubRoute.routeName;
  static const timeWindowManual = TimeWindowManualRoute.routeName;
  static const timeWindowCalendar = TimeWindowCalendarRoute.routeName;
  static const timeWindowBulk = TimeWindowBulkCreateRoute.routeName;
  static const progressiveVisual = ProgressiveVisualRoute.routeName;
  static const progressiveVisualSection = ProgressiveVisualSectionRoute.routeName;
  static const cherryBlossomTree = CherryBlossomTreeRoute.routeName;

  static String initialFor(AppSettings settings) =>
      AppRouteGuard.initialFor(settings).path;

  static Map<String, WidgetBuilder> builders() =>
      AppRouteRegistry.materialRouteTable();

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      AppRouteRegistry.onUnknownRoute(settings);
}
