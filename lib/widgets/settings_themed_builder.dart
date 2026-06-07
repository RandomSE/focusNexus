import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

typedef SettingsThemedWidgetBuilder = Widget Function(
  BuildContext context,
  ThemeBundle bundle,
);

/// Rebuilds when app settings change; derives [ThemeBundle] from the live snapshot.
class SettingsThemedBuilder extends ConsumerWidget {
  const SettingsThemedBuilder({
    super.key,
    required this.builder,
  });

  final SettingsThemedWidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(themeBundleProvider);
    return builder(context, bundle);
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
