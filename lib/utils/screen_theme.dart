import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

export 'package:focusNexus/widgets/settings_themed_builder.dart';

/// One-shot async load (startup delay + persisted theme read). Prefer [SettingsThemedBuilder] in UI.
Future<ThemeBundle> loadScreenThemeBundle() {
  final repos = AppRepositories.instance;
  return repos.theme.loadScreenBundle(prefs: repos.settings.snapshot);
}

/// Sync bundle from the current in-memory settings snapshot.
ThemeBundle currentThemeBundle() {
  final repos = AppRepositories.instance;
  return repos.theme.bundleFromSnapshot(repos.settings.snapshot);
}
