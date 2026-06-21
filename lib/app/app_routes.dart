import 'package:flutter/material.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/settings/app_settings.dart';

export 'package:focusNexus/app/app_navigation.dart';
export 'package:focusNexus/app/app_route.dart';

/// Back-compat facade for [MaterialApp.routes] wiring and legacy string constants.
abstract final class AppRoutes {
  AppRoutes._();

  static const auth = AuthRoute.routeName;
  static const onboard = OnboardRoute.routeName;
  static const dashboard = DashboardRoute.routeName;
  static const settings = SettingsRoute.routeName;
  static const reward = RewardRoute.routeName;
  static const chat = ChatRoute.routeName;
  static const achievements = AchievementsRoute.routeName;
  static const goals = GoalsRoute.routeName;
  static const timeWindowHub = TimeWindowHubRoute.routeName;
  static const timeWindowManual = TimeWindowManualRoute.routeName;
  static const timeWindowCalendar = TimeWindowCalendarRoute.routeName;
  static const timeWindowBulk = TimeWindowBulkCreateRoute.routeName;
  static const progressiveVisual = ProgressiveVisualRoute.routeName;
  static const progressiveVisualSection = ProgressiveVisualSectionRoute.routeName;

  static String initialFor(AppSettings settings) =>
      AppRouteGuard.initialFor(settings).path;

  static Map<String, WidgetBuilder> builders() =>
      AppRouteRegistry.materialRouteTable();

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      AppRouteRegistry.onUnknownRoute(settings);
}
