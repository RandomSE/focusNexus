// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final container = ProviderContainer();
  await ensureAppReady(container);

  final initialRoute = AppRoutes.initialFor(
    container.read(appSettingsProvider.notifier).service,
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: FocusNexusApp(initialRoute: initialRoute),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(scheduleDeferredStartupWork(container: container));
  });
}

/// Root app widget. Uses [MaterialApp] named [routes], not [MaterialApp.router].
class FocusNexusApp extends ConsumerWidget {
  const FocusNexusApp({super.key, required this.initialRoute});

  final String initialRoute;

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
      title: 'FocusNexus',
      debugShowCheckedModeBanner: false,
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
        return ColoredBox(
          color: bg,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: initialRoute,
      routes: AppRoutes.builders(),
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}
