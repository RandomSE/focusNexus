import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

typedef SettingsThemedWidgetBuilder = Widget Function(
  BuildContext context,
  ThemeBundle bundle,
);

/// Rebuilds when [AppSettings] changes; derives [ThemeBundle] from the live snapshot.
class SettingsThemedBuilder extends StatelessWidget {
  const SettingsThemedBuilder({
    super.key,
    required this.builder,
  });

  final SettingsThemedWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final settings = AppRepositories.instance.settings;
    final theme = AppRepositories.instance.theme;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final bundle = theme.bundleFromSnapshot(settings.snapshot);
        return builder(context, bundle);
      },
    );
  }
}

/// Themed skeleton shell (use instead of [CircularProgressIndicator]).
Widget themedLoadingShell(
  ThemeBundle bundle, {
  String? title,
  Widget? body,
}) {
  return Theme(
    data: bundle.themeData,
    child: ThemedSkeletonScaffold(
      title: title,
      bundle: bundle,
      child: body,
    ),
  );
}
