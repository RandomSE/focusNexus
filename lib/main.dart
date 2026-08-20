// lib/main.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigator.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/goals/goals_notification_navigation.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/music_lifecycle_binder.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

void main() {
  runZonedGuarded(() async {
    // Bindings and runApp must share this zone (Flutter BindingBase.debugCheckZone).
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      debugLog('FlutterError: ${details.exceptionAsString()}');
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugLog('Uncaught async error: $error\n$stack');
      return true;
    };

    final container = ProviderContainer();
    // Gate-critical only (settings/route prefs). Achievements/audio/notifications
    // continue in scheduleDeferredStartupWork after the first frame.
    await ensureAppReady(container);

    final initialRoute = AppRouteGuard.initialFor(
      container.read(appSettingsProvider.notifier).service,
    ).path;

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: FocusNexusApp(
          initialRoute: initialRoute,
          ambientRouteObserver: AmbientRouteObserver(container),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await scheduleDeferredStartupWork(container: container);
      openGoalsFromPendingNotification();
    });
  }, (error, stack) {
    debugLog('Zone error: $error\n$stack');
  });
}

/// Root app widget. Uses [MaterialApp] named [routes], not [MaterialApp.router].
class FocusNexusApp extends ConsumerWidget {
  const FocusNexusApp({
    super.key,
    required this.initialRoute,
    this.ambientRouteObserver,
  });

  final String initialRoute;
  final AmbientRouteObserver? ambientRouteObserver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsView = ref.watch(appSettingsProvider);
    final snap = settingsView.snapshot;

    final primaryColor = ThemeStyles.resolvePrimaryColor(
      isDark: snap.isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final scaffoldColor = ThemeStyles.resolveSecondaryColor(
      isDark: snap.isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final accentColor = ThemeStyles.resolveAccentColor(
      isDark: snap.isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final appTheme = ThemeStyles.buildThemeData(
      isDark: snap.isDark,
      primaryColor: primaryColor,
      secondaryColor: scaffoldColor,
      accentColor: accentColor,
      fontSize: snap.fontSize,
      useDyslexiaFont: snap.useDyslexiaFont,
    );

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'FocusNexus',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        if (ambientRouteObserver != null) ambientRouteObserver!,
      ],
      theme: appTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        final bg = resolveScaffoldBackground(snap);
        return MusicLifecycleBinder(
          child: ColoredBox(
            color: bg,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      initialRoute: initialRoute,
      routes: AppRoutes.builders(),
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}
