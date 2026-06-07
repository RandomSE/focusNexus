import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

export 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Sync bundle from the current settings snapshot (requires [ProviderScope]).
ThemeBundle currentThemeBundle(WidgetRef ref) => ref.watch(themeBundleProvider);

/// Legacy async theme read. Prefer [SettingsThemedBuilder].
Future<ThemeBundle> loadScreenThemeBundle(WidgetRef ref) {
  final repos = ref.read(appRepositoriesProvider);
  final snap = ref.read(appSettingsProvider).snapshot;
  return repos.theme.loadScreenBundle(prefs: snap);
}
