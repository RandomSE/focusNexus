// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ensureAppReady();

  final initialRoute = AppRoutes.initialFor(AppRepositories.instance.settings);

  runApp(FocusNexusApp(initialRoute: initialRoute));
}

/// Root app widget. Uses [MaterialApp] named [routes], not [MaterialApp.router].
class FocusNexusApp extends StatelessWidget {
  const FocusNexusApp({super.key, required this.initialRoute});

  final String initialRoute;

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
                TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
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
          routes: AppRoutes.builders(),
          onUnknownRoute: AppRoutes.onUnknownRoute,
        );
      },
    );
  }
}
