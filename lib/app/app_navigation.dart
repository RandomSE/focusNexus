import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';

/// Typed navigation helpers — prefer over raw [Navigator.pushNamed] strings.
extension AppNavigation on WidgetRef {
  Future<T?> pushRoute<T>(BuildContext context, AppRoute route) async {
    final settings = read(appSettingsProvider.notifier).service;
    final guarded = AppRouteGuard.guard(route, settings);
    final result = await Navigator.of(context).pushNamed(
      guarded.path,
      arguments: guarded.navigationArguments,
    );
    return result as T?;
  }

  void pushReplacementRoute(BuildContext context, AppRoute route) {
    final settings = read(appSettingsProvider.notifier).service;
    final guarded = AppRouteGuard.guard(route, settings);
    Navigator.of(context).pushReplacementNamed(
      guarded.path,
      arguments: guarded.navigationArguments,
    );
  }

  void resetToRoute(BuildContext context, AppRoute route) {
    final settings = read(appSettingsProvider.notifier).service;
    final guarded = AppRouteGuard.guard(route, settings);
    Navigator.of(context).pushNamedAndRemoveUntil(
      guarded.path,
      (_) => false,
      arguments: guarded.navigationArguments,
    );
  }
}
